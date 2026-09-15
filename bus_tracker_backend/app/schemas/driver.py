from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class DriverLocationUpdateSchema(BaseModel):
    trip_id: str = Field(
        ...,
        description="Active trip identifier"
    )

    latitude: float = Field(
        ...,
        ge=-90,
        le=90,
        description="GPS latitude"
    )

    longitude: float = Field(
        ...,
        ge=-180,
        le=180,
        description="GPS longitude"
    )

    speed: float = Field(
        ...,
        ge=0,
        description="Current speed in km/h"
    )

    heading: float = Field(
        ...,
        ge=0,
        le=360,
        description="Compass heading in degrees"
    )

    accuracy: float = Field(
        ...,
        ge=0,
        description="GPS accuracy in meters"
    )

    captured_at: datetime = Field(
        ...,
        description="Timestamp when GPS location was captured"
    )

    model_config = ConfigDict(
        extra="forbid",
        json_schema_extra={
            "example": {
                "trip_id": "trip_987654",
                "latitude": 23.727871,
                "longitude": 90.394583,
                "speed": 34.5,
                "heading": 185.2,
                "accuracy": 5.2,
                "captured_at": "2026-08-06T10:05:12Z"
            }
        }
    )


class DriverTripStartSchema(BaseModel):
    bus_id: int|None = Field(None, description="Bus identifier")
    route_id: int|None = Field(None,description="Route identifier")
    device_id: str|None = Field(None, description="Device identifier")

    app_version: str|None = Field(None,description="App version")

class DriverStatusSchema(BaseModel):
    trip_id: str = Field(..., description="Active trip identifier")
    battery_level: int = Field(..., description="Battery level in percentage")
    network_status: str = Field(..., description="Network status")
    gps_enabled: bool = Field(..., description="GPS enabled or not")


class DriverTripEndSchema(BaseModel):
    trip_id: str = Field(..., description="Active trip identifier")
    