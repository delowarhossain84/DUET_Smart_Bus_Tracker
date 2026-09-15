from pydantic import BaseModel, ConfigDict, Field
from typing import Literal, Union
from datetime import datetime

from app.schemas.base import BaseResponse


class BaseWebSocketSchema(BaseModel):
    model_config = ConfigDict(extra="forbid")

    event: str

class SubscribeBusSchema(BaseWebSocketSchema):
    event: Literal["subscribe_bus"]

    bus_id: int
    

class StudentLocationUpdateSchema(BaseModel):
    event: Literal["location_update"]

    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)

    accuracy: float = Field(..., ge=0)

    heading: float | None = Field(None, ge=0, le=360)

    speed: float | None = Field(None, ge=0)

    captured_at: datetime



class PingSchema(BaseModel):
    event: Literal["ping"]

StudentWebSocketSchema = Union[
    SubscribeBusSchema,
    StudentLocationUpdateSchema,
    PingSchema,
]

class RouteDetail(BaseModel):
    route_id: int | None = None
    name: str | None = None
    code: str | None = None
    starting_stop: str | None = None
    ending_stop: str | None = None

class AvailableTrip(BaseModel):
    id: int | None = None
    trip_id: str | None = None
    bus_id: int | None = None
    route:RouteDetail|None = None
    started_at: datetime | None = None

class AvailableTrips(BaseResponse):
    data: list[AvailableTrip]
