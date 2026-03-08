# trading.py
from alpaca.trading.client import TradingClient
from alpaca.trading.requests import MarketOrderRequest
from alpaca.trading.enums import OrderSide, TimeInForce
from config import settings

# Initialize the Alpaca Trading Client
trading_client = TradingClient(
    api_key=settings.ALPACA_API_KEY,
    secret_key=settings.ALPACA_SECRET_KEY,
    paper=settings.ALPACA_PAPER
)

def get_account():
    return trading_client.get_account()

def get_portfolio_positions():
    return trading_client.get_all_positions()

def buy_fractional_share(ticker: str, notional_amount: float):
    """
    Submits a market order to buy a fractional share based on a dollar amount (notional).
    """
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
