from pathlib import Path

from dotenv import load_dotenv
from pydantic import BaseSettings


env_path = Path(__file__).resolve().parents[2] / ".env"
load_dotenv(dotenv_path=env_path)


class Settings(BaseSettings):
    database_url: str
    model_path: str
    backend_port: int = 8000
    mysql_port: int = 3306
    mysql_root_password: str | None = None
    mysql_database: str | None = None
    mysql_user: str | None = None
    mysql_password: str | None = None
    
    # Auth settings
    secret_key: str = "09d25e094faa6ca2556c818166b7a9563b93f7099f6f0f4caa6cf63b88e8d3e7"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 15 # 15 minutes for access token
    refresh_token_expire_minutes: int = 43200 # 30 days for refresh token

    # MinIO
    minio_endpoint: str = "minio:9000" # internal docker network
    public_minio_endpoint: str = "localhost" # public endpoint for mobile app via Nginx
    minio_root_user: str = "admin"
    minio_root_password: str = "admin123"
    minio_secure: bool = False



    class Config:
        env_file = env_path
        env_file_encoding = "utf-8"


settings = Settings()
