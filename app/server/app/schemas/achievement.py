from pydantic import BaseModel, ConfigDict
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

    model_config = ConfigDict(from_attributes=True)
