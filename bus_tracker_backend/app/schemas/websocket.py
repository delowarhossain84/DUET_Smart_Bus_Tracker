from __future__ import annotations
 
from datetime import datetime, timezone
from typing import Literal, Optional
 
from pydantic import BaseModel, Field

class BusLocationIn(BaseModel):
    """Payload for POST /api/v1/bus/location"""
    bus_id: int|None = Field(None, description="Bus identifier")
    trip_id: str|None = Field(None, description="Trip identifier")
    lat: float = Field(ge=-90, le=90)
    lng: float = Field(ge=-180, le=180)
    speed_kmh: Optional[float] = None
    heading: Optional[float] = None
    # timestamp: datetime = Field(default_factory=datetime.now(timezone.utc))

class BusLocationBroadcast(BaseModel):
    """Server -> student(s): the bus moved."""
    type: Literal["bus_location"] = "bus_location"
    trip_id: str
    bus_id: int
    lat: float
    lng: float
    speed_kmh: Optional[float] = None
    heading: Optional[float] = None
    timestamp: datetime

class StudentLocationIn(BaseModel):
    """Payload a student sends over the websocket."""
    type: Literal["location_update"] = "location_update"
    lat: float = Field(ge=-90, le=90)
    lng: float = Field(ge=-180, le=180)
    # timestamp: datetime = Field(default_factory=datetime.utcnow)

class DistanceUpdate(BaseModel):
    """Server -> one student: here's how far the bus is from you."""
    type: Literal["distance_update"] = "distance_update"
    trip_id: str|None = None
    bus_id: int|None = None
    bus_lat:float | None = None
    bus_lng:float|None = None
    bus_speed_kmh: Optional[float] = None
    bus_heading: Optional[float] = None
    bus_timestamp: datetime | None = None
    
    distance_meters: float | None = None
    eta_seconds: Optional[float] = None
    student_timestamp: datetime | None = None

class WSError(BaseModel):
    type: Literal["error"] = "error"
    message: str