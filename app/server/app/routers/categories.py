from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.models.category import WasteCategory
from app.schemas.category import Category

router = APIRouter(prefix="/categories", tags=["categories"])

@router.get("", response_model=List[Category])
def read_categories(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """
    Retrieve categories.
    """
    categories = db.query(WasteCategory).offset(skip).limit(limit).all()
    return categories
