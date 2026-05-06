from pathlib import Path

from dotenv import load_dotenv
from pydantic_settings import BaseSettings, SettingsConfigDict


env_path = Path(__file__).resolve().parents[2] / ".env"
load_dotenv(dotenv_path=env_path)


class Settings(BaseSettings):
    database_url: str
    model_path: str
    backend_port: int
    mysql_port: int
    mysql_root_password: str | None = None
    mysql_database: str | None = None
    mysql_user: str | None = None
    mysql_password: str | None = None
    
    # Auth settings
    secret_key: str
    algorithm: str
    access_token_expire_minutes: int # 15 minutes for access token
    refresh_token_expire_minutes: int # 30 days for refresh token

    # MinIO
    minio_endpoint: str # internal docker network
    public_minio_endpoint: str # public endpoint for mobile app via Nginx
    minio_root_user: str
    minio_root_password: str
    minio_secure: bool
    minio_bucket: str
    minio_avatar_bucket: str



    model_config = SettingsConfigDict(
        env_file=env_path,
        env_file_encoding="utf-8",
        extra="ignore",
    )


settings = Settings()
