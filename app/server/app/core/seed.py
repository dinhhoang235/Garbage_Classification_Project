from app.core.database import get_db
from app.models.category import WasteCategory
from app.models.notification import Notification
from app.models.user import User

def seed_categories():
    db = next(get_db())
    try:
        # Always check and update existing data to ensure all fields are filled
        data = [
            {
                "id": "plastic",
                "name": "Nhựa",
                "description": "Các loại chai nhựa, túi nilon, đồ dùng nhựa...",
                "icon_name": "glass-water",
                "color_hex": "#0EA5E9",
                "examples": ["Chai nước suối", "Hộp cơm nhựa", "Túi nilon", "Ống hút"],
                "disposal_guide": "Rửa sạch, làm khô và cho vào thùng rác tái chế."
            },
            {
                "id": "paper",
                "name": "Giấy",
                "description": "Báo cũ, tạp chí, giấy carton, giấy văn phòng...",
                "icon_name": "file-text",
                "color_hex": "#F59E0B",
                "examples": ["Giấy A4", "Tạp chí", "Sách cũ", "Vở viết"],
                "disposal_guide": "Giữ cho giấy khô ráo và phẳng phiu."
            },
            {
                "id": "metal",
                "name": "Kim loại",
                "description": "Lon nước ngọt, vỏ đồ hộp, sắt thép vụn...",
                "icon_name": "hammer",
                "color_hex": "#607D8B",
                "examples": ["Lon bia", "Vỏ đồ hộp", "Thìa nĩa hỏng", "Dây điện"],
                "disposal_guide": "Làm sạch và loại bỏ các phần nhựa đính kèm nếu có."
            },
            {
                "id": "glass",
                "name": "Thủy tinh",
                "description": "Chai lọ thủy tinh, ly chén vỡ...",
                "icon_name": "wine",
                "color_hex": "#009688",
                "examples": ["Chai rượu", "Lọ nước hoa", "Ly thủy tinh vỡ"],
                "disposal_guide": "Bọc cẩn thận các mảnh vỡ để tránh gây thương tích."
            },
            {
                "id": "biological",
                "name": "Hữu cơ",
                "description": "Thức ăn thừa, vỏ trái cây, rau củ hỏng...",
                "icon_name": "leaf",
                "color_hex": "#22C55E",
                "examples": ["Vỏ cam", "Cơm thừa", "Lá cây khô", "Bã cà phê"],
                "disposal_guide": "Bỏ vào thùng rác hữu cơ để làm phân bón."
            },
            {
                "id": "battery",
                "name": "Pin & Điện tử",
                "description": "Pin cũ, linh kiện điện tử, sạc hỏng...",
                "icon_name": "zap",
                "color_hex": "#EF4444",
                "examples": ["Pin AA", "Sạc điện thoại", "Tai nghe hỏng"],
                "disposal_guide": "Phân loại riêng vì chứa chất độc hại, cần xử lý đặc biệt."
            },
            {
                "id": "cardboard",
                "name": "Carton",
                "description": "Thùng giấy, hộp bưu kiện...",
                "icon_name": "package",
                "color_hex": "#F59E0B",
                "examples": ["Thùng hàng", "Hộp pizza", "Lõi giấy"],
                "disposal_guide": "Tháo gỡ băng dính và gấp gọn trước khi bỏ vào thùng."
            },
            {
                "id": "clothes",
                "name": "Quần áo",
                "description": "Quần áo cũ, vải vụn...",
                "icon_name": "shirt",
                "color_hex": "#0EA5E9",
                "examples": ["Áo phông cũ", "Quần jean hỏng", "Vải vụn"],
                "disposal_guide": "Giặt sạch trước khi quyên góp hoặc tái chế."
            },
            {
                "id": "shoes",
                "name": "Giày dép",
                "description": "Giày dép cũ, hỏng...",
                "icon_name": "footprints",
                "color_hex": "#795548",
                "examples": ["Giày thể thao", "Dép nhựa", "Giày da"],
                "disposal_guide": "Vệ sinh sạch sẽ, tháo dây giày nếu cần."
            },
            {
                "id": "trash",
                "name": "Rác khác",
                "description": "Các loại rác không thể tái chế khác...",
                "icon_name": "trash-2",
                "color_hex": "#94A3B8",
                "examples": ["Túi bóng bẩn", "Khăn giấy ướt", "Đầu lọc thuốc lá"],
                "disposal_guide": "Bỏ vào túi rác sinh hoạt thông thường."
            }
        ]
        
        for item in data:
            existing = db.query(WasteCategory).filter(WasteCategory.id == item["id"]).first()
            if existing:
                # Update all fields to ensure data completeness
                existing.name = item["name"]
                existing.description = item["description"]
                existing.icon_name = item["icon_name"]
                existing.color_hex = item["color_hex"]
                existing.examples = item["examples"]
                existing.disposal_guide = item["disposal_guide"]
            else:
                new_cat = WasteCategory(**item)
                db.add(new_cat)
        db.commit()
    except Exception as e:
        print(f"Error seeding categories: {e}")
        db.rollback()
    finally:
        db.close()

def seed_notifications():
    db = next(get_db())
    try:
        users = db.query(User).all()
        for user in users:
            # Check if welcome notification already exists
            existing = db.query(Notification).filter(
                Notification.user_id == user.id,
                Notification.title == "Chào mừng bạn đến với Eco Sort"
            ).first()
            
            if not existing:
                welcome_notif = Notification(
                    user_id=user.id,
                    title="Chào mừng bạn đến với Eco Sort",
                    content="Cảm ơn bạn đã tham gia cùng chúng tôi trong việc bảo vệ môi trường. Hãy bắt đầu phân loại rác ngay hôm nay!",
                    is_read=False
                )
                db.add(welcome_notif)
                
                level_notif = Notification(
                    user_id=user.id,
                    title="Mẹo nhỏ cho bạn",
                    content="Bạn có biết phân loại rác đúng cách giúp tiết kiệm 70% năng lượng tái chế không?",
                    is_read=False
                )
                db.add(level_notif)
        db.commit()
    except Exception as e:
        print(f"Error seeding notifications: {e}")
        db.rollback()
    finally:
        db.close()
