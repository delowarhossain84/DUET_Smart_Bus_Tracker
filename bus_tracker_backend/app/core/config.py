from pydantic_settings import BaseSettings, SettingsConfigDict
from pathlib import Path

class Settings(BaseSettings):
    app_name: str = "Bus Tracker"
    app_env: str = "development"
    app_port: int = 8000

    # Database
    postgres_user: str
    postgres_password: str
    postgres_host: str
    postgres_port: int
    postgres_db: str

    # SSLCommrz (payment Gateway)
    SSLCOMMERZ_STORE_ID: str
    SSLCOMMERZ_STORE_PASSWORD: str

    SSLCOMMERZ_SANDBOX: bool = True

    SSLCOMMERZ_SANDBOX_URL: str
    SSLCOMMERZ_LIVE_URL: str

    BASE_URL: str

    # Encription Decreption
    SECRET_KEY:str
    ALGORITHM: str
    ENCRYPTION_KEY:str
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8"
    )

    CONTENT_SECURITY_POLICY: str = (
        "default-src 'self'; "
        "script-src 'self'; "
        "style-src 'self' 'unsafe-inline'; "
        "img-src 'self' data: https:; "
        "font-src 'self' https: data:; "
        "connect-src 'self'; "
        "object-src 'none'; "
        "frame-ancestors 'none'; "
        "base-uri 'self'; "
        "form-action 'self';"
    )
    ALLOWED_HOSTS: list[str] = ["*"]
    CORS_ORIGINS: list[str] = []
    origins:list[str] = [
        "http://localhost:3000",
        "http://localhost:5173",
        "https://example.com",
        "https://www.example.com",
    ]


    @property
    def database_url(self) -> str:
        # postgresql+asyncpg://postgres:password@localhost/ecommerce
        # return (
        #     f"postgresql+psycopg2://"
        #     f"{self.postgres_user}:"
        #     f"{self.postgres_password}@"
        #     f"{self.postgres_host}:"
        #     f"{self.postgres_port}/"
        #     f"{self.postgres_db}"
        # )
        return (
            f"postgresql+asyncpg://"
            f"{self.postgres_user}:"
            f"{self.postgres_password}@"
            f"{self.postgres_host}:"
            f"{self.postgres_port}/"
            f"{self.postgres_db}"
        )


settings = Settings()

UPLOAD_DIR = Path("uploads/products")
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

# security



# local

SUPPORTED_LOCALES: set[str] = {
    "en",
    "bn",
}

DEFAULT_LOCALE: str = "en"



# maintanance


# Enable / disable maintenance mode
MAINTENANCE_MODE: bool = False

# Endpoints that should still work
MAINTENANCE_EXCLUDED_PATHS: set[str] = {
    "/health",
    "/docs",
    "/redoc",
    "/openapi.json",
}

# Allow these IPs during maintenance
MAINTENANCE_ALLOWED_IPS: set[str] = {
    "127.0.0.1",
}