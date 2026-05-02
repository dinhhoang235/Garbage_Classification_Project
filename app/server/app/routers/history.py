from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session, joinedload
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
    history_items = db.query(History).options(joinedload(History.category)).filter(History.user_id == current_user.id).order_by(History.created_at.desc()).offset(skip).limit(limit).all()
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
    
    # Update points, XP and Level
    if item_in.points_earned:
        current_user.points += item_in.points_earned
        
        # Synchronize with Mobile UI Level Thresholds
        # L1: 0, L2: 200, L3: 500, L4: 1000, L5: 1500, L6: 2000, L7: 3000, L8: 5000, L9: 8000, L10: 12000
        LEVEL_THRESHOLDS = [0, 200, 500, 1000, 1500, 2000, 3000, 5000, 8000, 12000]
        XP_PER_SCAN = 20 # 10 items = 200 XP (Level 2)
        
        # Calculate new total XP from scratch based on scan history
        # This fixes users who had incorrect high levels from legacy logic
        scan_count = db.query(History).filter(History.user_id == current_user.id).count()
        new_total_xp = (scan_count + 1) * XP_PER_SCAN
        
        # Determine new level and relative progress
        new_level = 1
        for i, threshold in enumerate(LEVEL_THRESHOLDS):
            if new_total_xp >= threshold:
                new_level = i + 1
            else:
                break
        
        # Calculate xp_progress relative to the current level
        if new_level >= len(LEVEL_THRESHOLDS):
            current_user.xp_progress = float(new_total_xp - LEVEL_THRESHOLDS[-1])
            current_user.level = len(LEVEL_THRESHOLDS)
        else:
            base_xp = LEVEL_THRESHOLDS[new_level - 1]
            current_user.xp_progress = float(new_total_xp - base_xp)
            current_user.level = new_level

        db.commit()
        db.add(current_user)
        
    db.add(history_item)
    db.commit()
    history_item = db.query(History).options(joinedload(History.category)).filter(History.id == history_item.id).first()
    return history_item
