from fastapi import APIRouter, Depends, status, HTTPException, Form
from sqlalchemy.orm import Session
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Annotated

from app.core.outh2 import get_current_user, require_role
from app.db.base import get_db

from app.services import admin_service


from app.schemas.user import User
from app.schemas.admin import BusCreateSchema, BusFilterSchema, StopCreateSchema, StopListFileterSchema, RouteCreateSchema, RouteListFileterSchema, RouteStopCreateSchema

from app.enums.user_enums import DriverStatus
from app.enums.bus_enums import TripStatus

router = APIRouter(
    prefix='/admin',
    tags=['admin']
)

@router.get("/dashboard", status_code=200)
async def get_dashboard(db: Annotated[AsyncSession, Depends(get_db)], user: Annotated[User, Depends(get_current_user)], _: Annotated[User, Depends(require_role("admin"))]):
    return await admin_service.get_dashboard(db)

# =============================================================================
#                             Bus Management
# =============================================================================

@router.post("/buses", status_code=201) # Create bus
async def create_bus(payload: BusCreateSchema, db: Annotated[AsyncSession, Depends(get_db)], user: Annotated[User, Depends(get_current_user)], _: Annotated[User, Depends(require_role("admin"))]):
    return await admin_service.create_bus(payload, db)

@router.get("/buses", status_code=200) # List all buses
async def get_buses(payload:Annotated[BusFilterSchema, Depends()],  db: Annotated[AsyncSession, Depends(get_db)]):
    return await admin_service.get_buses(db, payload)


@router.get("/buses/{bus_id}", status_code=200) # Get bus details
async def get_bus_details(bus_id:int, db: Annotated[AsyncSession, Depends(get_db)]):
    return await admin_service.get_bus_details(bus_id, db)

@router.patch("/buses/{bus_id}", status_code=200) # Update bus details
async def update_bus_details(bus_id:int, payload:BusCreateSchema, db: Annotated[AsyncSession, Depends(get_db)]):
    return await admin_service.update_bus_details(bus_id, payload, db)


@router.delete("/buses/{bus_id}", status_code=200) # Delete bus
async def delete_bus(bus_id:int, db: Annotated[AsyncSession, Depends(get_db)]):
    await admin_service.delete_bus(bus_id, db)



# =============================================================================
#                             Stop Management
# =============================================================================
@router.post("/stops", status_code=201) # Create stop
async def create_stop(payload: StopCreateSchema, db: Annotated[AsyncSession, Depends(get_db)], user: Annotated[User, Depends(get_current_user)], _: Annotated[User, Depends(require_role("admin"))]):
    return await admin_service.create_stop(payload, db)
    

@router.get("/stops", status_code=200) # List all stops
async def get_stops(payload: Annotated[StopListFileterSchema, Depends()], db: Annotated[AsyncSession, Depends(get_db)], user: Annotated[User, Depends(get_current_user)], _: Annotated[User, Depends(require_role("admin"))]):
    return await admin_service.get_stops(payload, db)


@router.get("/stops/{stop_id}", status_code=200) # Get stop details
async def get_stop_details(stop_id:int, db: Annotated[AsyncSession, Depends(get_db)], user: Annotated[User, Depends(get_current_user)], _: Annotated[User, Depends(require_role("admin"))]):
    return await admin_service.get_stop_details(stop_id, db)

@router.patch("/stops/{stop_id}", status_code=200) # Update stop details
async def update_stop_details(stop_id:int,payload:StopCreateSchema, db: Annotated[AsyncSession, Depends(get_db)], user: Annotated[User, Depends(get_current_user)], _: Annotated[User, Depends(require_role("admin"))]):
    return await admin_service.update_stop_details(stop_id,payload, db)

@router.delete("/stops/{stop_id}", status_code=200) # Delete stop
async def delete_stop(stop_id:int, db: Annotated[AsyncSession, Depends(get_db)], user: Annotated[User, Depends(get_current_user)], _: Annotated[User, Depends(require_role("admin"))]):
    return await admin_service.delete_stop(stop_id, db)


# =============================================================================
#                             Route Management
# =============================================================================
@router.post("/routes", status_code=201) # Create route
async def create_route(payload: RouteCreateSchema, db: Annotated[AsyncSession, Depends(get_db)], user: Annotated[User, Depends(get_current_user)], _: Annotated[User, Depends(require_role("admin"))]):
    return await admin_service.create_route(payload, db)
    

@router.get("/routes", status_code=200) # List all routes
async def get_routes(payload:Annotated[RouteListFileterSchema, Depends()], db: Annotated[AsyncSession, Depends(get_db)], user: Annotated[User, Depends(get_current_user)], _: Annotated[User, Depends(require_role("admin"))]):
    return await admin_service.get_routes(payload, db)

@router.get("/routes/{route_id}", status_code=200) # Get route details
async def get_route_details(route_id:int, db: Annotated[AsyncSession, Depends(get_db)]):
    return await admin_service.get_route_details(route_id, db)

@router.patch("/routes/{route_id}", status_code=200) # Update route details
async def update_route_details(route_id:int,payload:RouteCreateSchema, db: Annotated[AsyncSession, Depends(get_db)]):
    return await admin_service.update_route_details(route_id, payload, db)


@router.delete("/routes/{route_id}", status_code=200) # Delete route
async def delete_route(route_id:int, db: Annotated[AsyncSession, Depends(get_db)], user: Annotated[User, Depends(get_current_user)], _: Annotated[User, Depends(require_role("admin"))]):
    return await admin_service.delete_route(route_id, db)


@router.post("/routes/{route_id}/stops", status_code=201) # Add stop to route
async def add_stop_to_route(route_id:int, payload:RouteStopCreateSchema, db: Annotated[AsyncSession, Depends(get_db)], user: Annotated[User, Depends(get_current_user)], _: Annotated[User, Depends(require_role("admin"))]):
    return await admin_service.add_stop_to_route(route_id, payload, db)


@router.delete("/routes/{route_id}/stops/{stop_id}", status_code=200) # Remove stop from route
async def remove_stop_from_route(route_id:int, stop_id:int, db: Annotated[AsyncSession, Depends(get_db)], user: Annotated[User, Depends(get_current_user)], _: Annotated[User, Depends(require_role("admin"))]):
    return await admin_service.remove_stop_from_route(route_id, stop_id, db)


# @router.patch("routes/{route_id}/stops", status_code=200) # Update stop order in route
# async def update_stop_order_in_route(route_id, db: Annotated[AsyncSession, Depends(get_db)]):
#     pass



# =============================================================================
#                             Driver Management
# =============================================================================

@router.patch("/drivers/{driver_id}", status_code=201) # Activate Driver
async def activate_driver(driver_id:int, db: Annotated[AsyncSession, Depends(get_db)], user: Annotated[User, Depends(get_current_user)], _: Annotated[User, Depends(require_role("admin"))]):
    return await admin_service.activate_driver(driver_id, db)
    

@router.get("/drivers", status_code=200) # List all drivers
async def get_drivers(status:DriverStatus, db: Annotated[AsyncSession, Depends(get_db)], user: Annotated[User, Depends(get_current_user)], _: Annotated[User, Depends(require_role("admin"))]):
    return await admin_service.get_drivers(status, db)

@router.get("/drivers/{driver_id}", status_code=200) # Get driver details
async def get_driver_details(driver_id:int, db: Annotated[AsyncSession, Depends(get_db)], user: Annotated[User, Depends(get_current_user)], _: Annotated[User, Depends(require_role("admin"))]):
    return await admin_service.get_driver_details(driver_id, db)


# @router.patch("/drivers/{driver_id}", status_code=200) # Update driver details
# async def update_driver_details(driver_id, db: Annotated[AsyncSession, Depends(get_db)], user: Annotated[User, Depends(get_current_user)], _: Annotated[User, Depends(require_role("admin"))]):
#     pass

@router.delete("/drivers/{driver_id}", status_code=200) # Delete driver
async def delete_driver(driver_id:int, db: Annotated[AsyncSession, Depends(get_db)]):
    return await admin_service.delete_driver(driver_id, db)

"""
i will add assigning bus to driver and route to driver in the future
"""


# =============================================================================
#                             Trip Management
# =============================================================================
@router.get("/trips", status_code=200) # List all trips
async def get_trips(status:TripStatus, db: Annotated[AsyncSession, Depends(get_db)], user: Annotated[User, Depends(get_current_user)], _: Annotated[User, Depends(require_role("admin"))]):
    return await admin_service.get_trips(status, db)

@router.get("/trips/{trip_id}", status_code=200) # Get trip details inlcuding location
async def get_trip_details(trip_id:int, db: Annotated[AsyncSession, Depends(get_db)]):
    return await admin_service.get_trip_details(trip_id, db)






