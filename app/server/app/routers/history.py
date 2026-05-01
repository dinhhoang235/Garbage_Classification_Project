from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.history import History
from app.schemas.history import History as HistorySchema, HistoryCreate

router = APIRouter(prefix="/history", tags=["history"])

@router.get("", response_model=List[HistorySchema])
def read_history(
    skip: int = 0, 
    limit: int = 100, 
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Retrieve classification history for the current user.
    """
    history_items = db.query(History).filter(History.user_id == current_user.id).order_by(History.created_at.desc()).offset(skip).limit(limit).all()
    return history_items

@router.post("", response_model=HistorySchema)
def create_history_item(
    item_in: HistoryCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Create a new history item for the current user.
    """
    history_item = History(
        user_id=current_user.id,
        category_id=item_in.category_id,
        title=item_in.title,
        confidence=item_in.confidence,
        image_url=item_in.image_url,
        location=item_in.location,
        points_earned=item_in.points_earned
    )
    
    # Optionally add points to user
    if item_in.points_earned:
        current_user.points += item_in.points_earned
        db.add(current_user)
        
    db.add(history_item)
    db.commit()
    db.refresh(history_item)
    return history_item
