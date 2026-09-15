from sqlalchemy import (Column, 
                        Integer, 
                        String, 
                        DateTime, 
                        Enum, 
                        Boolean, 
                        ForeignKey, 
                        Text,
                        Enum,
                        Float
)
from app.models.base import BaseModel
from datetime import datetime, timezone

from sqlalchemy.orm import relationship

from app.enums.bus_enums import TripStatus


class Bus(BaseModel):
    __tablename__ = "buses"
    name = Column(String(50), nullable=False)
    registration_number = Column(String(50), nullable=False)
    capacity = Column(Integer, nullable=False)
    route_id = Column(Integer, ForeignKey("routes.id", ondelete="CASCADE"), nullable=False, index=True)
    is_active = Column(Boolean, nullable=False, default=True)
    # Relationships
    route = relationship(
        "Route",
        back_populates="buses",
    )

    trips = relationship(
        "Trip",
        back_populates="bus",
        cascade="all, delete-orphan",
        order_by="Trip.started_at",
    )
    

class Route(BaseModel):
    __tablename__ = "routes"
    name = Column(String(50), nullable=False)  # DUET -> DU 
    code = Column(String(50), nullable=False)  # DUET-DU
    description = Column(Text, nullable=True)
    is_active = Column(Boolean, nullable=False, default=True)

    # Relationships
    stops = relationship(
        "RouteStop",
        back_populates="route",
        cascade="all, delete-orphan",
        order_by="RouteStop.stop_order",
    )

    trips = relationship(
        "Trip",
        back_populates="route",
        cascade="all, delete-orphan",
    )

    buses = relationship(
        "Bus",
        back_populates="route",
        cascade="all, delete-orphan",
    )


class Stop(BaseModel):
    __tablename__ = "stops"
    name = Column(String(50), nullable=False)
    lattitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    is_active = Column(Boolean, nullable=False, default=True)

    route_stops = relationship(
        "RouteStop",
        back_populates="stop",
    )

class RouteStop(BaseModel):
    __tablename__ = "route_stops"
    route_id = Column(Integer, ForeignKey("routes.id", ondelete="CASCADE"), nullable=False, index=True) # 1, 1, 1, 1
    stop_id = Column(Integer, ForeignKey("stops.id", ondelete="CASCADE"), nullable=False, index=True) # 1, 2, 3, 4
    stop_order = Column(Integer, nullable=False) # 1, 2, 3, 4

    route = relationship(
        "Route",
        back_populates="stops",
    )

    stop = relationship(
        "Stop",
        back_populates="route_stops",
    )

class Trip(BaseModel):
    __tablename__ = "trips"
    bus_id = Column(Integer, ForeignKey("buses.id", ondelete="CASCADE"), nullable=False, index=True)
    trip_id = Column(String(100), nullable=False, unique=True)
    route_id = Column(Integer, ForeignKey("routes.id", ondelete="CASCADE"), nullable=False, index=True)
    device_id = Column(String(100), nullable=False)
    app_version = Column(String(100), nullable=False)
    started_at = Column(DateTime(timezone=True), nullable=False)
    status = Column(Enum(TripStatus), nullable=False, default=TripStatus.RUNNING)
    ended_at = Column(DateTime(timezone=True), nullable=True)
    
    driver_id = Column(Integer, ForeignKey("driver_info.id", ondelete="CASCADE"))
    driver = relationship("DriverInfo", back_populates="trips")
    route = relationship("Route", back_populates="trips")
    bus = relationship("Bus", back_populates="trips")

    def __repr__(self):
        return f"<Trip(id={self.id}, bus_id={self.bus_id}, route_id={self.route_id}, device_id={self.device_id}, app_version={self.app_version}, started_at={self.started_at}, ended_at={self.ended_at}, created_at={self.created_at}, updated_at={self.updated_at})>"

