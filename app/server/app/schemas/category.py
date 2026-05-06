from pydantic import BaseModel, ConfigDict
from typing import Optional, List

class CategoryBase(BaseModel):
    id: str
    name: str
    description: Optional[str] = None
    icon_name: Optional[str] = None
    color_hex: Optional[str] = None
    examples: Optional[List[str]] = None
    disposal_guide: Optional[str] = None

class CategoryCreate(CategoryBase):
    pass

class Category(CategoryBase):
    model_config = ConfigDict(from_attributes=True)
