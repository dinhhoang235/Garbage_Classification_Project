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
