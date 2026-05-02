from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List
from app.models.history import History
from app.models.user import User
from app.schemas.achievement import Achievement

class AchievementService:
    @staticmethod
    def get_user_achievements(db: Session, user: User) -> List[Achievement]:
        # Get counts per category
        category_counts = db.query(
            History.category_id, 
            func.count(History.id).label('count')
        ).filter(History.user_id == user.id).group_by(History.category_id).all()
        
        counts_dict = {cat_id: count for cat_id, count in category_counts}
        total_count = sum(counts_dict.values())
        
        # Achievement definitions
        definitions = [
            {
                "id": "beginner",
                "title": "Người mới bắt đầu",
                "description": "Phân loại rác lần đầu tiên",
                "target_count": 1,
                "current_count": total_count,
                "icon": "award"
            },
            {
                "id": "plastic_hero",
                "title": "Siêu anh hùng nhựa",
                "description": "Phân loại 5 sản phẩm nhựa",
                "target_count": 5,
                "current_count": counts_dict.get("plastic", 0),
                "icon": "recycle"
            },
            {
                "id": "paper_warrior",
                "title": "Chiến binh giấy",
                "description": "Phân loại 5 sản phẩm giấy",
                "target_count": 5,
                "current_count": counts_dict.get("paper", 0),
                "icon": "file-text"
            },
            {
                "id": "sorting_master",
                "title": "Bậc thầy phân loại",
                "description": "Phân loại tổng cộng 20 sản phẩm",
                "target_count": 20,
                "current_count": total_count,
                "icon": "layers"
            },
            {
                "id": "forest_protector",
                "title": "Người bảo vệ rừng",
                "description": "Phân loại 10 sản phẩm từ gỗ hoặc giấy",
                "target_count": 10,
                "current_count": counts_dict.get("paper", 0) + counts_dict.get("wood", 0),
                "icon": "tree-pine"
            },
            {
                "id": "energy_saver",
                "title": "Tiết kiệm năng lượng",
                "description": "Phân loại 5 sản phẩm kim loại",
                "target_count": 5,
                "current_count": counts_dict.get("metal", 0),
                "icon": "zap"
            },
            {
                "id": "organic_expert",
                "title": "Chuyên gia hữu cơ",
                "description": "Phân loại 10 sản phẩm hữu cơ",
                "target_count": 10,
                "current_count": counts_dict.get("organic", 0),
                "icon": "leaf"
            },
            {
                "id": "inspiration",
                "title": "Người truyền cảm hứng",
                "description": "Đạt cấp độ 5",
                "target_count": 5,
                "current_count": user.level,
                "icon": "star"
            },
        ]
        
        achievements = []
        for d in definitions:
            is_unlocked = d["current_count"] >= d["target_count"]
            progress = min(1.0, d["current_count"] / d["target_count"]) if d["target_count"] > 0 else 0.0
            
            achievements.append(Achievement(
                id=d["id"],
                title=d["title"],
                description=d["description"],
                is_unlocked=is_unlocked,
                progress=progress,
                target_count=d["target_count"],
                current_count=d["current_count"],
                icon_name=d["icon"]
            ))
            
        return achievements

    @staticmethod
    def check_and_notify_achievements(db: Session, user: User, category_id: str):
        """
        Check if the latest activity unlocked any new achievements and send notifications.
        """
        from app.core.notifications import create_notification
        
        # Get counts
        category_counts = db.query(
            History.category_id, 
            func.count(History.id).label('count')
        ).filter(History.user_id == user.id).group_by(History.category_id).all()
        
        counts_dict = {cat_id: count for cat_id, count in category_counts}
        total_count = sum(counts_dict.values())
        
        # Define milestones to check
        # We only notify if the count is EXACTLY the target_count (meaning it was just reached)
        
        # 1. Total count milestones
        if total_count == 1:
            create_notification(db, user.id, "Thành tựu mới! 🎖️", "Chúc mừng! Bạn đã nhận được huy hiệu 'Người mới bắt đầu'.")
        elif total_count == 20:
            create_notification(db, user.id, "Thành tựu mới! 🏆", "Tuyệt vời! Bạn đã trở thành 'Bậc thầy phân loại' với 20 sản phẩm.")
            
        # 2. Category specific milestones
        cat_count = counts_dict.get(category_id, 0)
        
        if category_id == "plastic" and cat_count == 5:
            create_notification(db, user.id, "Thành tựu mới! 🦸", "Bạn đã mở khóa huy hiệu 'Siêu anh hùng nhựa' (5 sản phẩm nhựa).")
            
        elif category_id == "paper" and cat_count == 5:
            create_notification(db, user.id, "Thành tựu mới! 📄", "Bạn đã mở khóa huy hiệu 'Chiến binh giấy' (5 sản phẩm giấy).")
            
        elif category_id in ["paper", "wood"]:
            wood_paper_count = counts_dict.get("paper", 0) + counts_dict.get("wood", 0)
            if wood_paper_count == 10:
                create_notification(db, user.id, "Thành tựu mới! 🌲", "Bạn đã mở khóa huy hiệu 'Người bảo vệ rừng' (10 sản phẩm giấy/gỗ).")
                
        elif category_id == "metal" and cat_count == 5:
            create_notification(db, user.id, "Thành tựu mới! ⚡", "Bạn đã mở khóa huy hiệu 'Tiết kiệm năng lượng' (5 sản phẩm kim loại).")
            
        elif category_id == "organic" and cat_count == 10:
            create_notification(db, user.id, "Thành tựu mới! 🍃", "Bạn đã mở khóa huy hiệu 'Chuyên gia hữu cơ' (10 sản phẩm hữu cơ).")
