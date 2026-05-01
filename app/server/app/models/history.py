from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Float
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.core.database import Base

class History(Base):
    __tablename__ = "classification_history"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    category_id = Column(String(50), ForeignKey("waste_categories.id"), nullable=False)
    title = Column(String(255), nullable=False) # e.g., 'Chai nhựa PET'
    confidence = Column(Float, nullable=False)
    image_url = Column(String(1024), nullable=True)
    location = Column(String(255), nullable=True)
    points_earned = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User")
    category = relationship("WasteCategory")
