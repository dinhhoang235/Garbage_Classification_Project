from sqlalchemy.orm import Session
from app.models.notification import Notification

def create_notification(db: Session, user_id: int, title: str, content: str):
    """
    Utility function to create a notification for a specific user.
    """
    notification = Notification(
        user_id=user_id,
        title=title,
        content=content,
        is_read=False
    )
    db.add(notification)
    try:
        db.commit()
        return notification
    except Exception as e:
        db.rollback()
        print(f"Error creating notification: {e}")
        return None
