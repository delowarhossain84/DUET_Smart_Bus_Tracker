from fastapi import HTTPException, status
from datetime import datetime, timezone

from app.utils.data_class import live_bus_store
from app.schemas.driver import DriverLocationUpdateSchema

from app.repositories import driver_repositories
from app.schemas.base import BaseResponse, Meta

def _response(status_code, success, message,lang='en', data=None):
    return BaseResponse(
        status=status_code,
        success=success,
        message=message,
        lang='en',
        data=data,
        meta=Meta(request_id=None, timestamp=datetime.now(tz=timezone.utc))
    )

def generate_trip_id() -> str:
    now = datetime.now(timezone.utc)

    return now.strftime("TRIP-%Y%m%d-%H%M%S-%f")[:-3]

# Update latest location



async def update_live_location(payload:DriverLocationUpdateSchema):
        if payload.speed > 140:
                raise HTTPException(status_code=status.HTTP_406_NOT_ACCEPTABLE, detail=f"Bus speed can not be {payload.speed}. check it again")

        
        await live_bus_store.update(
            bus_id="##",
            latitude=payload.latitude,
            longitude=payload.longitude,
            speed=payload.speed,
            heading=payload.heading,
            captured_at=payload.captured_at,
        )


async def start_trip(db, payload, user_id):
    # Check if trip is not started
    trip = await driver_repositories.get_trip(db, payload.bus_id)
    
    if trip is not None and trip.started_at == datetime.now(tz=timezone.utc):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Trip already started")

    route = await driver_repositories.get_route(db, payload.route_id)
    if route is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Route not found")
    
    trip = {
          "bus_id": payload.bus_id,
          "route_id": payload.route_id,
          "trip_id": generate_trip_id(),
          "device_id": payload.device_id,
          "app_version": payload.app_version,
          "started_at": datetime.now(tz=timezone.utc),
          "ended_at": None,
          "driver_id": user_id,
    }
    await driver_repositories.create_trip(db, trip)

    # Update live location
    # Broadcast WebSocket
    return _response(status_code=status.HTTP_200_OK, success=True, message="Trip started successfully.")


async def end_trip(db, payload, user_id):
    trip = await driver_repositories.get_trip(db, payload.trip_id)
    driver = await driver_repositories.get_driver(db, user_id)
    if trip is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Trip not found")
    
    if trip.driver_id != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You are not the driver of this trip")
    
    trip.ended_at = datetime.now(tz=timezone.utc)
    await driver_repositories.update_trip(db, trip)

    driver.total_triped += 1
    await driver_repositories.update_driver(db, driver)

    return _response(status_code=status.HTTP_200_OK, success=True, message="Trip ended successfully.")

