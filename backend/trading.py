from alpaca.trading.client import TradingClient
from alpaca.trading.requests import MarketOrderRequest, GetPortfolioHistoryRequest, GetAssetsRequest
from alpaca.trading.enums import OrderSide, TimeInForce, AssetStatus
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

def search_assets(query: str):
    """Search for tradeable assets matching the query."""
    try:
        assets = trading_client.get_all_assets(GetAssetsRequest(status=AssetStatus.ACTIVE))
        query_upper = query.upper()
        matches = []
        for asset in assets:
            if not asset.tradable:
                continue
            name_upper = (asset.name or "").upper()
            if query_upper in asset.symbol or query_upper in name_upper:
                matches.append({
                    "symbol": asset.symbol,
                    "name": asset.name or asset.symbol,
                    "exchange": asset.exchange.value if asset.exchange else "",
                    "fractionable": getattr(asset, 'fractionable', False),
                })
        # Sort: exact match first, then starts-with, then contains
        matches.sort(key=lambda x: (
            0 if x["symbol"] == query_upper else
            1 if x["symbol"].startswith(query_upper) else 2
        ))
        return matches[:20]
    except Exception as e:
        print(f"Error searching assets: {e}")
        return []


def get_asset_name(symbol: str) -> str:
    """Get the company name for a ticker symbol, cleaned up."""
    try:
        asset = trading_client.get_asset(symbol.upper())
        name = asset.name or symbol
        # Strip common suffixes (order matters — strip trailing class/stock first, then entity type)
        for _ in range(3):
            for suffix in [" Class A Common Stock", " Class B Common Stock",
                           " Class C Capital Stock", " Class C Common Stock",
                           " Common Stock",
                           " Class A", " Class B", " Class C",
                           ", Inc.", ", Inc", " Inc.", " Inc",
                           ", Ltd.", ", Ltd", " Ltd.", " Ltd",
                           ", Corp.", ", Corp", " Corp.", " Corp",
                           ", Co.", " Co."]:
                if name.endswith(suffix):
                    name = name[:-len(suffix)]
        return name.strip()
    except Exception:
        return symbol


def get_open_orders():
    """Get all open/pending orders (scheduled but not yet filled)."""
    try:
        from alpaca.trading.requests import GetOrdersRequest
        from alpaca.trading.enums import QueryOrderStatus
        request = GetOrdersRequest(status=QueryOrderStatus.OPEN)
        return trading_client.get_orders(filter=request)
    except Exception as e:
        print(f"Error fetching open orders: {e}")
        return []


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
