from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session, joinedload
from typing import List

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.history import History
from app.schemas.history import History as HistorySchema, HistoryCreate
from app.core.storage import build_public_image_url, normalize_public_image_reference

from app.core.notifications import create_notification
from app.services.achievement_service import AchievementService

router = APIRouter(prefix="/history", tags=["history"])


def _to_history_schema(item: History) -> HistorySchema:
    payload = HistorySchema.model_validate(item)
    payload.image_url = build_public_image_url(item.image_url)
    return payload

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
    return [_to_history_schema(item) for item in history_items]

@router.post("", response_model=HistorySchema)
def create_history_item(
    item_in: HistoryCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Create a new history item for the current user.
    """
    old_level = current_user.level
    
    history_item = History(
        user_id=current_user.id,
        category_id=item_in.category_id,
        title=item_in.title,
        confidence=item_in.confidence,
        image_url=normalize_public_image_reference(item_in.image_url),
        location=item_in.location,
        latitude=item_in.latitude,
        longitude=item_in.longitude,
        points_earned=item_in.points_earned
    )
    
    # Update points, XP and Level
    if item_in.points_earned:
        current_user.points += item_in.points_earned
        
        # Synchronize with Mobile UI Level Thresholds
        LEVEL_THRESHOLDS = [0, 200, 500, 1000, 1500, 2000, 3000, 5000, 8000, 12000]
        XP_PER_SCAN = 20
        
        scan_count = db.query(History).filter(History.user_id == current_user.id).count()
        new_total_xp = (scan_count + 1) * XP_PER_SCAN
        
        new_level = 1
        for i, threshold in enumerate(LEVEL_THRESHOLDS):
            if new_total_xp >= threshold:
                new_level = i + 1
            else:
                break
        
        if new_level >= len(LEVEL_THRESHOLDS):
            current_user.xp_progress = float(new_total_xp - LEVEL_THRESHOLDS[-1])
            current_user.level = len(LEVEL_THRESHOLDS)
        else:
            base_xp = LEVEL_THRESHOLDS[new_level - 1]
            current_user.xp_progress = float(new_total_xp - base_xp)
            current_user.level = new_level

        # Check for Level Up Notification
        if current_user.level > old_level:
            create_notification(
                db,
                current_user.id,
                "Lên cấp mới! 🚀",
                f"Chúc mừng! Bạn đã đạt Level {current_user.level} - {current_user.level_name}. Hãy tiếp tục bảo vệ môi trường nhé!"
            )

        db.commit()
        db.add(current_user)
        
    db.add(history_item)
    db.commit()
    
    # Check for new achievements
    AchievementService.check_and_notify_achievements(db, current_user, item_in.category_id)
    
    history_item = db.query(History).options(joinedload(History.category)).filter(History.id == history_item.id).first()
    return _to_history_schema(history_item)
