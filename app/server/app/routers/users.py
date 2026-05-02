from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import Any, List

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.storage import generate_avatar_presigned_url
from app.core.auth import verify_password, get_password_hash
from app.models.user import User
from app.schemas.user import User as UserSchema, UserUpdate, UserPasswordChange
from app.schemas.achievement import Achievement
from app.services.achievement_service import AchievementService

router = APIRouter(prefix="/users", tags=["users"])

@router.get("/me", response_model=UserSchema)
def read_user_me(current_user: User = Depends(get_current_user)) -> Any:
    """
    Get current user.
    """
    return current_user

@router.get("/me/achievements", response_model=List[Achievement])
def read_user_achievements(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Get current user achievements.
    """
    return AchievementService.get_user_achievements(db, current_user)


@router.get("/me/avatar-upload-url")
def get_avatar_upload_url(
    content_type: str = Query(default="image/jpeg", description="MIME type of the image, e.g. image/jpeg or image/png"),
    current_user: User = Depends(get_current_user),
) -> Any:
    """
    Return a presigned PUT URL so the mobile app can upload the avatar
    directly to MinIO without going through the server.

    Flow:
      1. GET /users/me/avatar-upload-url?content_type=image/jpeg
         -> { upload_url, public_url, object_name }
      2. Client PUTs the image file to `upload_url` (Content-Type must match)
      3. Client calls PUT /users/me with { avatar_url: public_url } to persist
    """
    try:
        result = generate_avatar_presigned_url(current_user.id, content_type)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Could not generate upload URL: {e}")

@router.put("/me", response_model=UserSchema)
def update_user_me(
    user_in: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Update current user.
    """
    if user_in.name is not None:
        current_user.name = user_in.name
    if user_in.avatar_url is not None:
        current_user.avatar_url = user_in.avatar_url
    
    db.add(current_user)
    db.commit()
    db.refresh(current_user)
    return current_user

@router.post("/me/change-password")
def change_password_me(
    pass_in: UserPasswordChange,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Change current user password.
    """
    if not verify_password(pass_in.old_password, current_user.hashed_password):
        raise HTTPException(status_code=400, detail="Mật khẩu cũ không chính xác")
    
    current_user.hashed_password = get_password_hash(pass_in.new_password)
    db.add(current_user)
    db.commit()
    return {"message": "Đổi mật khẩu thành công"}

@router.delete("/me")
def delete_user_me(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Delete current user account and all associated data.
    """
    from app.models.history import History
    
    # 1. Delete user's history records
    db.query(History).filter(History.user_id == current_user.id).delete()
    
    # 2. Delete the user
    db.delete(current_user)
    db.commit()
    
    return {"message": "Tài khoản đã được xóa thành công"}

