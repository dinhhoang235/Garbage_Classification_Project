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

    class Config:
        env_file = env_path
        env_file_encoding = "utf-8"


settings = Settings()
