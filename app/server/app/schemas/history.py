from pydantic import BaseModel
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
    points_earned: Optional[int] = 0

class HistoryCreate(HistoryBase):
    pass

class History(HistoryBase):
    id: int
    user_id: int
    created_at: datetime
    category: Optional[Category] = None

    class Config:
        orm_mode = True
