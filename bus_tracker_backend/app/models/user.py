from sqlalchemy import (Column, 
                        Integer, 
                        String, 
                        DateTime, 
                        Enum, 
                        Boolean, 
                        ForeignKey, 
                        Text,
                        Enum
)
from sqlalchemy.sql import func
from datetime import datetime
from sqlalchemy.orm import relationship, Mapped, mapped_column
import enum

from app.db.base import Base

from app.models.base import BaseModel
from app.enums.user_enums import UserRole, DriverStatus, CurrentSemester



class User(BaseModel):
    __tablename__ = "users"

    username = Column(String(100), nullable=False)
    email = Column(String(255), unique=True, nullable=False, index=True)
    password = Column(String(255), nullable=False)
    dob = Column(DateTime, nullable=False)
    mobile = Column(String(20), nullable=False)
    gender = Column(String(20), nullable=False)

    role = Column(Enum(UserRole), default=UserRole.STUDENT, nullable=False)
    driver_info = relationship("DriverInfo", back_populates="user")
    student_info = relationship("StudentInfo", back_populates="user")

class StudentInfo(BaseModel):
    __tablename__ = "student_info"
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    full_name = Column(String(255), nullable=True)
    status = Column(Enum(DriverStatus), nullable=False, default=DriverStatus.ACTIVE)
    address = Column(String(255), nullable=True)
    student_id = Column(String(255), nullable=True, unique=True)
    current_semester = Column(Enum(CurrentSemester), nullable=True) # 11, 12, 21, 22, 31, 32, 41, 41
    user = relationship("User", back_populates="student_info")


class DriverInfo(BaseModel):
    __tablename__ = "driver_info"
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    full_name = Column(String(255), nullable=True)
    status = Column(Enum(DriverStatus), nullable=False, default=DriverStatus.INACTIVE)
    address = Column(String(255), nullable=True)
    license_plate = Column(String(255), nullable=False)
    license_plate_expiry = Column(DateTime, nullable=False)
    total_triped = Column(Integer, nullable=False, default=0)
    
    emergency_contact_name = Column(String(255), nullable=False)
    emergency_contact_phone = Column(String(255), nullable=False)

    user = relationship("User", back_populates="driver_info")
    trips = relationship("Trip", back_populates="driver", cascade="all, delete-orphan")


class UserSession(BaseModel):
    __tablename__ = "user_sessions"
    user_id:Mapped[int] = mapped_column(Integer, ForeignKey("users.id", ondelete='CASCADE'))
    refresh_token:Mapped[str] = mapped_column(Text, nullable=False)
    
    device_name:Mapped[str] = mapped_column(String(100))
    device_type:Mapped[str] = mapped_column(String(50))
    ip_address:Mapped[str] = mapped_column(String(45))
    user_agent:Mapped[str] = mapped_column(Text)

    is_revoked:Mapped[str] = mapped_column(Boolean, default=False)

    expires_at:Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    last_used_at:Mapped[datetime] = mapped_column(DateTime(timezone=True))
