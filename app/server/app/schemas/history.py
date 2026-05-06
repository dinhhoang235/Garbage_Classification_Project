from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import datetime
from app.schemas.category import Category
from app.schemas.user import User

class HistoryBase(BaseModel):
    category_id: str
    title: str
    confidence: float
    image_url: Optional[str] = None
    location: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    points_earned: Optional[int] = 0

class HistoryCreate(HistoryBase):
    pass

class History(HistoryBase):
    id: int
    user_id: int
    created_at: datetime
    category: Optional[Category] = None

    model_config = ConfigDict(from_attributes=True)
