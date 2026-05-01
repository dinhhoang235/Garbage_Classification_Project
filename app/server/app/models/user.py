from sqlalchemy import Column, Integer, String, Float, DateTime
from sqlalchemy.sql import func
from app.core.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    phone_number = Column(String(20), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    avatar_url = Column(String(1024), nullable=True)
    points = Column(Integer, default=0)
    level = Column(Integer, default=1)
    xp_progress = Column(Float, default=0.0)
    achievements_count = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    @property
    def level_name(self) -> str:
        names = [
            'Người mới',
            'Người khám phá',
            'Người bạn xanh',
            'Người bảo vệ',
            'Chiến binh Eco',
            'Người hùng hành tinh',
            'Nhà vô địch Eco',
            'Bậc thầy xanh',
            'Huyền thoại Eco',
            'Thần Eco',
        ]
        if self.level <= 0: return names[0]
        if self.level > len(names): return names[-1]
        return names[self.level - 1]
