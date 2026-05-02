from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class UserBase(BaseModel):
    name: str
    phone_number: str = Field(..., max_length=10, min_length=10)
    avatar_url: Optional[str] = None

class UserCreate(UserBase):
    password: str

class UserUpdate(BaseModel):
    name: Optional[str] = None
    avatar_url: Optional[str] = None

class UserInDBBase(UserBase):
    id: int
    points: int
    level: int
    level_name: str
    xp_progress: float
    achievements_count: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        orm_mode = True

class User(UserInDBBase):
    pass

class UserPasswordChange(BaseModel):
    old_password: str
    new_password: str
