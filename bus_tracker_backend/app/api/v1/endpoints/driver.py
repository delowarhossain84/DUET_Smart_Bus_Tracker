from fastapi import APIRouter, Depends, status, HTTPException, Form
from sqlalchemy.orm import Session
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Annotated
from datetime import datetime, timezone

from app.core.outh2 import get_current_user, require_role


from app.schemas.driver import DriverLocationUpdateSchema, DriverTripStartSchema, DriverStatusSchema, DriverTripEndSchema
from app.schemas.user import User
from app.schemas.websocket import BusLocationBroadcast, BusLocationIn
from app.websocket.manager import manager

from app.services import driver_services

from app.db.base import get_db

router = APIRouter(
    prefix='/driver',
    tags=['drivers']
)

@router.post("/trips/start", status_code=200)
async def starting_trip(payload: DriverTripStartSchema, db: Annotated[AsyncSession, Depends(get_db)], user: Annotated[User, Depends(get_current_user)], _: Annotated[User, Depends(require_role("driver"))]):
    return  await driver_services.start_trip(db, payload, user.id)

@router.post("/location", status_code=200)
async def share_location(
    payload: BusLocationIn,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
    _: Annotated[User, Depends(require_role("driver"))],
):
    """
    Bus device/app pushes its current location here. We fan it out to every
    student websocket subscribed to this trip_id. Wire in a repository call
    here if you also want to persist location history for analytics/replay.
    """

    broadcast = BusLocationBroadcast(
        trip_id=payload.trip_id,
        bus_id=payload.bus_id,
        lat=payload.lat,
        lng=payload.lng,
        speed_kmh=payload.speed_kmh,
        heading=payload.heading,
        timestamp=datetime.now(tz=timezone.utc),
    )

    await manager.update_bus_location(payload.trip_id, broadcast)

    
    # Update live location
    # Broadcast WebSocket
    # Update ETA
    return {
        "success": True,
        "message": "Location updated successfully."
    }

@router.post("/herartbeat", status_code=200)
async def herartbeat(payload: DriverStatusSchema, db: Annotated[AsyncSession, Depends(get_db)]):
    # Check if user is driver
    # Check if trip is started
    # Update live location
    # Broadcast WebSocket
    return {
        "success": True,
        "message": "Location updated successfully."
    }

@router.post("/trips/end", status_code=200)
async def ending_trip(payload: DriverTripEndSchema, db: Annotated[AsyncSession, Depends(get_db)]):
    # Check if user is driver
    # Check if trip is started
    # Update live location
    # Broadcast WebSocket
    return  await driver_services.end_trip(db, payload)