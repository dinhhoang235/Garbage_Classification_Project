from pydantic import BaseModel
from typing import Optional

class Achievement(BaseModel):
    id: str
    title: str
    description: str
    is_unlocked: bool
    progress: float # 0.0 to 1.0
    target_count: int
    current_count: int
    icon_name: Optional[str] = "award"

    class Config:
        orm_mode = True
