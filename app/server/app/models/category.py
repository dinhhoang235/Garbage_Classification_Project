from sqlalchemy import Column, String, Text, JSON
from app.core.database import Base

class WasteCategory(Base):
    __tablename__ = "waste_categories"

    id = Column(String(50), primary_key=True, index=True) # e.g., 'plastic', 'paper'
    name = Column(String(100), nullable=False)
    description = Column(Text, nullable=True)
    icon_name = Column(String(50), nullable=True) # Lucide icon name
    color_hex = Column(String(10), nullable=True) # e.g., '#RRGGBB'
    examples = Column(JSON, nullable=True) # List of strings
    disposal_guide = Column(Text, nullable=True)
