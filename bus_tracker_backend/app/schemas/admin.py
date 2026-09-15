from pydantic import BaseModel, ConfigDict, Field
from typing import List
from datetime import datetime
from app.schemas.base import BaseResponse, Meta

from app.enums.admin_enums import BusFilterStatus


# =============================================================================
#                             Bus Management
# =============================================================================

class BusCreateSchema(BaseModel):
    name: str|None = Field(None, description="Bus name")
    registration_number: str|None = Field(None, description="Bus registration number")
    capacity: int|None = Field(None, description="Bus capacity")
    route_id: int|None = Field(None, description="Route id")
    is_active: bool|None = Field(None, description="Bus active or not")

class BusFilterSchema(BaseModel):
    status: BusFilterStatus | None = Field(None, description="Bus status")
    route_id: int|None = Field(None, description="Route id")

class CurrentLocationSchema(BaseModel):
    latitude: float = Field(..., description="Current latitude")
    longitude: float = Field(..., description="Current longitude")

class BusDetailsSchema(BaseModel):
    id: int = Field(..., description="Bus id")
    name: str = Field(..., description="Bus name")
    registration_number: str|None = Field(None, description="Bus registration number")
    capacity: int|None = Field(None, description="Bus capacity")
    route_id: int|None = Field(None, description="Route id")
    is_active: bool|None = Field(None, description="Bus active or not")
    is_running: bool|None = Field(None, description="Bus running or not")
    current_location: CurrentLocationSchema|None = Field(None, description="Current location")

class BusListDataSchema(BaseModel):
    data:list[BusDetailsSchema]|None = Field(None, description="Bus list")
    total:int|None = Field(None, description="Total number of buses")


# =============================================================================
#                             Stop Management
# =============================================================================
class StopCreateSchema(BaseModel):
    name: str = Field(None, description="Stop name")
    lattitude: float = Field(None, description="Stop lattitude")
    longitude: float = Field(None, description="Stop longitude")
    is_active: bool = Field(None, description="Stop active or not")


class StopListFileterSchema(BaseModel):
    route_id: int | None = Field(None, description="Route id")
    is_active: bool = Field(True, description="Stop active or not")

    sort_by: str = Field(None, description="Sort by")
    sort_order: str = Field(None, description="Sort order")
    page: int = Field(1, description="Page number")
    per_page: int = Field(20, description="Number of items per page")

# =============================================================================
#                             Route Management
# =============================================================================
class RouteStopCreateSchema(BaseModel):
    stop_id: int = Field(None, description="Stop id")
    stop_order: int = Field(None, description="Stop order")

class RouteCreateSchema(BaseModel):
    name: str = Field(None, description="Route name")
    code: str = Field(None, description="Route code")
    description: str = Field(None, description="Route description")
    is_active: bool = Field(True, description="Route active or not")
    stop_ids: list[RouteStopCreateSchema] = Field(None, description="Stop ids with order")

class RouteListFileterSchema(BaseModel):
    name: str|None = Field(None, description="Route name")
    is_active: bool|None = Field(True, description="Route active or not")
    search: str|None = Field(None, description="Search")
    sort_by: str|None = Field(None, description="Sort by")
    sort_order: str|None = Field(None, description="Sort order")

class RoutePointSchema(BaseModel):
    id: int = Field(..., description="Route point id")
    name:str|None = Field(None, description="Route point name")
    lattitude:float|None = Field(None, description="Route point lattitude")
    longitude:float|None = Field(None, description="Route point longitude")
    is_active:bool|None = Field(None, description="Route point active or not")

class RouteDetailsSchema(BaseModel):
    id: int = Field(..., description="Route id")
    name:str|None = Field(None, description="Route name")
    code:str|None = Field(None, description="Route code")
    description:str|None = Field(None, description="Route description")
    is_active:bool|None = Field(None, description="Route active or not")
    starting_point:str|None = Field(None, description="Route starting point")
    ending_point:str|None = Field(None, description="Route ending point")
    points:list[RoutePointSchema]|None = Field(None, description="Route points")

class RouteListDataSchema(BaseModel):
    data:list[RouteDetailsSchema]|None = Field(None, description="Route list")
    total:int|None = Field(None, description="Total number of routes")
    
    

# =============================================================================
#                             Driver Management
# =============================================================================
class DriverDetailsSchema(BaseModel):
    id: int = Field(..., description="Driver id")
    username: str|None = Field(None, description="Driver username")
    full_name: str|None = Field(None, description="Driver full name")
    status: str|None = Field(None, description="Driver status")
    address: str|None = Field(None, description="Driver address")
    license_plate: str|None = Field(None, description="Driver license plate")
    license_plate_expiry: datetime|None = Field(None, description="Driver license plate expiry")
    total_triped: int|None = Field(None, description="Driver total triped")
    joining_date: datetime|None = Field(None, description="Driver joining date")
    emergency_contact_name: str|None = Field(None, description="Driver emergency contact name")
    emergency_contact_phone: str|None = Field(None, description="Driver emergency contact phone")
    current_status: str|None = Field(None, description="Driver current status")

class DriverListSchema(BaseModel):
    data: List[DriverDetailsSchema] = Field(..., description="Driver list")
    total: int = Field(..., description="Total number of drivers")
    # online: int = Field(..., description="Total number of online drivers")


# =============================================================================
#                             Trip Management
# =============================================================================
class TripDetailsSchema(BaseModel):
    id: int = Field(..., description="Trip id")
    trip_id: str|None = Field(None, description="trip id to associate business logic")
    device_id: str|None = Field(None, description="Trip device id")
    app_version: str|None = Field(None, description="Trip app version")
    started_at: datetime|None = Field(None, description="Trip started at")
    ended_at: datetime|None = Field(None, description="Trip ended at")
    status: str|None = Field(None, description="Trip status")

    route_id: int|None = Field(None, description="Trip route id")
    route_name: str|None = Field(None, description="Trip route name")

    started_from: str|None = Field(None, description="Trip started from")
    destination: str|None = Field(None, description="Trip destination")

    driver_name: str|None = Field(None, description="Trip driver name")
    driver_id: int|None = Field(None, description="Trip driver id")

    bus_id: int|None = Field(None, description="Trip bus id")
    bus_name: str|None = Field(None, description="Trip bus name")

    current_location: CurrentLocationSchema|None = Field(None, description="Current location")
    driver: DriverDetailsSchema|None = Field(None, description="Driver details")

class TripListDataSchema(BaseModel):
    data: List[TripDetailsSchema] = Field(..., description="Trip list")
    total: int = Field(..., description="Total number of trips")
# =============================================================================
#                             Dashboard Management
# =============================================================================




class DashboardSchema(BaseModel):
    trips : TripListDataSchema|None = Field(None, description="Trips")
    drivers: DriverListSchema|None = Field(None, description="Driver list")
    routes: RouteListDataSchema|None = Field(None, description="Route list")
    buses: BusListDataSchema|None = Field(None, description="Bus list")
    number_student_tracking: int|None = Field(None, description="Number of students tracking")

class DashboardResponse(BaseResponse):
    data: DashboardSchema = Field(..., description="Dashboard data")

