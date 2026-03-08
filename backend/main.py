from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Dict, List
from fastapi.middleware.cors import CORSMiddleware

from datetime import datetime
import trading

app = FastAPI(title="NVST Hackathon Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

user_preferences = {
    "apps": {}
}

user_usage_stats = {}
user_activity_log = []

def format_time_string(minutes: float) -> str:
    hours = int(minutes // 60)
    mins = int(minutes % 60)
    if hours > 0:
        return f"{hours}h {mins}m today"
    return f"{mins}m today"

def format_gain_string(gain: float) -> str:
    if gain >= 0:
        return f"+${gain:.2f}"
    return f"-${abs(gain):.2f}"

class UsageData(BaseModel):
    app_name: str
    usage_minutes: float

class PreferenceData(BaseModel):
    app_name: str
    investment_rate_per_hour: float
    ticker: str

@app.get("/")
def read_root():
    return {"status": "active", "service": "NVST Alpaca Backend"}

@app.get("/api/portfolio")
def get_portfolio():
    try:
        account = trading.get_account()
        positions = trading.get_portfolio_positions()
        alpaca_pos = {p.symbol: p for p in positions}
        
        total_auto_invested = 0.0
        total_current_value = 0.0
        total_minutes = 0.0
        holdings = []
        
        for app_name, stats in user_usage_stats.items():
            inv_amount = stats["invested_amount"]
            ticker = stats["ticker"].upper()
            mins = stats["time_minutes"]
            
            total_auto_invested += inv_amount
            total_minutes += mins
            
            current_value = inv_amount
            shares_qty = 0.0
            avg_price = 1.0
            
            if ticker in alpaca_pos:
                pos = alpaca_pos[ticker]
                avg_price_str = getattr(pos, 'avg_entry_price', None)
                current_price_str = getattr(pos, 'current_price', None)
                
                avg_price = float(avg_price_str) if avg_price_str else 1.0
                current_price = float(current_price_str) if current_price_str else 1.0
                
                if avg_price > 0:
                    gain_pct = (current_price - avg_price) / avg_price
                    current_value = inv_amount * (1 + gain_pct)
                    
                shares_qty = current_value / current_price if current_price > 0 else 0.0
            else:
                shares_qty = inv_amount / 150.0 
                current_value = inv_amount * 1.05 
                
            return_pct = ((current_value - inv_amount) / inv_amount) * 100.0 if inv_amount > 0 else 0.0
            total_current_value += current_value
            
            display_name = "X" if app_name.lower() == "twitter" else app_name.capitalize()
            
            pref = user_preferences["apps"].get(app_name.lower())
            rate_per_hour = pref["rate_per_hour"] if pref else 0.0
            
            holdings.append({
                "id": app_name.lower(),
                "ticker": ticker,
                "company": display_name,
                "initial": display_name[0].upper() if display_name else "A",
                "iconClass": f"icon-{app_name.lower()}",
                "value": current_value,
                "returnPct": return_pct,
                "shares": shares_qty,
                "avgCost": avg_price,
                "totalInvested": inv_amount,
                "rate": f"${rate_per_hour:.2f} / hr",
                "sparklineData": [0, 0]
            })

        total_gain = total_current_value - total_auto_invested
        total_converted_hrs = total_minutes / 60.0
        
        top_engine = "None"
        max_invested = -1.0
        
        if total_auto_invested > 0:
            for s in holdings:
                inv = s["totalInvested"]
                
                if inv > max_invested:
                    max_invested = inv
                    top_engine = s["company"]
                
        holdings.sort(key=lambda x: x["value"], reverse=True)
        
        grouped_activities = {}
        for entry in user_activity_log:
            d_str = entry["date_str"]
            if d_str not in grouped_activities:
                grouped_activities[d_str] = []
            grouped_activities[d_str].append(entry)
            
        activities_list = []
        for d_str, items in grouped_activities.items():
            activities_list.append({
                "group": d_str,
                "items": items
            })
            
        return {
            "total_auto_invested_string": f"${total_auto_invested:.2f}",
            "total_gain_string": format_gain_string(total_gain),
            "total_time_string": format_time_string(total_minutes),
            "total_converted_hrs": round(total_converted_hrs, 1),
            "top_engine": top_engine,
            "holdings": holdings,
            "activities": activities_list,
            "raw_alpaca_data": {
                "portfolio_value": float(account.portfolio_value),
                "buying_power": float(account.buying_power),
                "cash": float(account.cash)
            }
        }
    except Exception as e:
         raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/history")
def get_history(period: str = "1M"):
    try:
        history = trading.get_portfolio_history(period)
        equity = history.equity
        timestamp = history.timestamp
        
        if not equity:
            equity = [0.0, 0.0]
            timestamp = [0, 1]
            
        return {
            "equity": equity,
            "timestamp": timestamp,
            "base_value": history.base_value
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/track-usage")
def track_usage(data: UsageData):
    app_name_lower = data.app_name.lower()
    
    pref = user_preferences["apps"].get(app_name_lower)
    
    if not pref:
        return {"status": "ignored", "message": f"No investment preferences set for {data.app_name}."}
        
    rate_per_hour = pref["rate_per_hour"]
    ticker = pref["ticker"]
        
    hours_used = data.usage_minutes / 60.0
    investment_amount = hours_used * rate_per_hour
    investment_amount = round(investment_amount, 2)
    
    if app_name_lower not in user_usage_stats:
        user_usage_stats[app_name_lower] = {"time_minutes": 0, "invested_amount": 0.0, "ticker": ticker}
        
    user_usage_stats[app_name_lower]["time_minutes"] += data.usage_minutes
    user_usage_stats[app_name_lower]["invested_amount"] += investment_amount
    user_usage_stats[app_name_lower]["ticker"] = ticker
    
    if investment_amount <= 0:
        return {"status": "success_no_trade", "message": "Time tracked, but investment amount $0.00."}

    result = trading.buy_fractional_share(ticker, investment_amount)
    
    if result["success"]:
         now = datetime.now()
         time_str = now.strftime("%I:%M %p")
         if d_str := now.strftime("%Y-%m-%d") == datetime.now().strftime("%Y-%m-%d"):
             display_date = "Today"
         else:
             display_date = now.strftime("%b %d")
             
         display_app = "X" if app_name_lower == "twitter" else data.app_name.capitalize()
             
         user_activity_log.insert(0, {
             "id": result["order_id"] or str(now.timestamp()),
             "title": f"Auto-Invest {ticker.upper()}",
             "description": f"From {int(data.usage_minutes)}m {display_app}",
             "amount": f"+${investment_amount:.2f}",
             "time": time_str,
             "icon": "zap",
             "color": "green",
             "date_str": display_date
         })
         
         return {
             "status": "success", 
             "action": "buy order submitted", 
             "app": data.app_name, 
             "ticker": ticker, 
             "amount": investment_amount,
             "order_id": result["order_id"]
         }
    else:
         raise HTTPException(status_code=500, detail=f"Purchase failed: {result.get('error')}")


@app.get("/api/preferences")
def get_preferences():
    return user_preferences

@app.post("/api/preferences")
def update_preference(pref: PreferenceData):
    app_name_lower = pref.app_name.lower()
    
    user_preferences["apps"][app_name_lower] = {
        "rate_per_hour": pref.investment_rate_per_hour,
        "ticker": pref.ticker.upper()
    }
    
    return {"status": "success", "preferences": user_preferences["apps"]}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)

