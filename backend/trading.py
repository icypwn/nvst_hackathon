from alpaca.trading.client import TradingClient
from alpaca.trading.requests import MarketOrderRequest, GetPortfolioHistoryRequest
from alpaca.trading.enums import OrderSide, TimeInForce
from config import settings

trading_client = TradingClient(
    api_key=settings.ALPACA_API_KEY,
    secret_key=settings.ALPACA_SECRET_KEY,
    paper=settings.ALPACA_PAPER
)

def get_account():
    return trading_client.get_account()

def get_portfolio_history(period: str = "1M"):
    # Map requested period to Alpaca params
    if period == "1D":
        timeframe = "15Min"
        alpaca_period = "1D"
    elif period == "1W":
        timeframe = "1H"
        alpaca_period = "1W"
    else: # Default 1M
        timeframe = "1D"
        alpaca_period = "1M"
        
    request = GetPortfolioHistoryRequest(
        period=alpaca_period,
        timeframe=timeframe
    )
    return trading_client.get_portfolio_history(request)

def get_portfolio_positions():
    return trading_client.get_all_positions()

def buy_fractional_share(ticker: str, notional_amount: float):
    try:
        order_data = MarketOrderRequest(
            symbol=ticker,
            notional=notional_amount,
            side=OrderSide.BUY,
            time_in_force=TimeInForce.DAY
        )
        order = trading_client.submit_order(order_data=order_data)
        return {"success": True, "order_id": order.id, "symbol": order.symbol, "notional": notional_amount}
    except Exception as e:
        print(f"Error placing order for {ticker}: {e}")
        return {"success": False, "error": str(e)}
