from app.db.base import Base
from sqlalchemy import Table, Column, Integer, ForeignKey, DateTime, func

class BaseModel(Base):
    __abstract__ = True
    id = Column(Integer, primary_key=True, index=True)
    created_at = Column(DateTime(timezone=True), default=func.now())
    deleted_at = Column(DateTime(timezone=True), nullable=True)
    updated_at = Column(DateTime(timezone=True), default=func.now(), onupdate=func.now())

