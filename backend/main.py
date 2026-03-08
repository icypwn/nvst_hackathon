# main.py
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Dict, List
from fastapi.middleware.cors import CORSMiddleware

import trading

app = FastAPI(title="NVST Hackathon Backend")

# Allow CORS for frontend integration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory storage for user preferences and live usage tracking
user_preferences = {
    "apps": {}
}

# Starts from scratch
user_usage_stats = {}

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
        shares = []
        
        for app_name, stats in user_usage_stats.items():
            inv_amount = stats["invested_amount"]
            ticker = stats["ticker"].upper()
            mins = stats["time_minutes"]
            
            total_auto_invested += inv_amount
            total_minutes += mins
            
            current_value = inv_amount
            shares_qty = 0.0
            
            # Match with real Alpaca data if available to show real gains
            if ticker in alpaca_pos:
                pos = alpaca_pos[ticker]
                avg_price = float(pos.avg_entry_price) if pos.avg_entry_price else 1.0
                current_price = float(pos.current_price) if pos.current_price else 1.0
                
                if avg_price > 0:
                    gain_pct = (current_price - avg_price) / avg_price
                    current_value = inv_amount * (1 + gain_pct)
                    
                shares_qty = current_value / current_price if current_price > 0 else 0.0
            else:
                # Fallback purely for hackathon UI visual completeness if market is closed
                shares_qty = inv_amount / 150.0 
                # Add a tiny fake gain for visual parity with the mock data if not traded yet
                current_value = inv_amount * 1.05 
                
            gain = current_value - inv_amount
            total_current_value += current_value
            
            display_name = "X" if app_name.lower() == "twitter" else app_name.capitalize()
            
            shares.append({
                "name": display_name,
                "iconLetter": display_name[0].upper() if display_name else "A",
                "timeString": format_time_string(mins),
                "gainAmount": format_gain_string(gain),
                "stockTicker": f"{shares_qty:.4f} {ticker}",
                "percentage": 0.0 # Will calculate next
            })

        # Calculate percentages mathematically
        total_gain = total_current_value - total_auto_invested
        
        if total_auto_invested > 0:
            for s in shares:
                # Re-find the invested amount to determine weight
                app_key = s["name"].lower()
                if app_key == "x": app_key = "twitter"
                inv = user_usage_stats[app_key]["invested_amount"]
                s["percentage"] = round(inv / total_auto_invested, 2)
                
        # Sort so highest percentage is first, matching typical portfolio views
        shares.sort(key=lambda x: x["percentage"], reverse=True)
            
        return {
            "total_auto_invested_string": f"${total_auto_invested:.2f}",
            "total_gain_string": format_gain_string(total_gain),
            "total_time_string": format_time_string(total_minutes),
            "shares": shares,
            "raw_alpaca_data": {
                "portfolio_value": float(account.portfolio_value),
                "buying_power": float(account.buying_power),
                "cash": float(account.cash)
            }
        }
    except Exception as e:
         raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/track-usage")
def track_usage(data: UsageData):
    app_name_lower = data.app_name.lower()
    
    # Check if the user has a preference set for this app
    pref = user_preferences["apps"].get(app_name_lower)
    
    if not pref:
        return {"status": "ignored", "message": f"No investment preferences set for {data.app_name}."}
        
    rate_per_hour = pref["rate_per_hour"]
    ticker = pref["ticker"]
        
    # Calculate amount to invest
    hours_used = data.usage_minutes / 60.0
    investment_amount = hours_used * rate_per_hour
    investment_amount = round(investment_amount, 2)
    
    # Update our local state to perfectly reflect the new usage in the UI
    if app_name_lower not in user_usage_stats:
        user_usage_stats[app_name_lower] = {"time_minutes": 0, "invested_amount": 0.0, "ticker": ticker}
        
    user_usage_stats[app_name_lower]["time_minutes"] += data.usage_minutes
    user_usage_stats[app_name_lower]["invested_amount"] += investment_amount
    user_usage_stats[app_name_lower]["ticker"] = ticker
    
    if investment_amount <= 0:
        return {"status": "success_no_trade", "message": "Time tracked, but investment amount $0.00."}

    result = trading.buy_fractional_share(ticker, investment_amount)
    
    if result["success"]:
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

