from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    ALPACA_API_KEY: str = "PKHT5Y5K4HGOLQICDBJ5WNLKFC"
    ALPACA_SECRET_KEY: str = "FR9YWJ62xq3mgXHJGYpqha9TfiUY7HHGWfDrYEvaRhAD"
    ALPACA_PAPER: bool = True
    
    model_config = SettingsConfigDict(env_file=".env")

settings = Settings()
