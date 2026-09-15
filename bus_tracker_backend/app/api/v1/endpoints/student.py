from fastapi import APIRouter, Depends, status, HTTPException, Form
from sqlalchemy.orm import Session
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Annotated

from app.services import student_services

from app.core.outh2 import get_current_user, require_role
from app.db.base import get_db

from app.schemas.websocket import StudentLocationIn
from app.schemas.user import User

router = APIRouter(tags=['student'], prefix="/student")

@router.get("/trips")
async def get_available_trips(db: Annotated[AsyncSession, Depends(get_db)], user: Annotated[User, Depends(get_current_user)], _: Annotated[User, Depends(require_role("student"))]):
    return await student_services.get_available_trips(db)


@router.get("/nearby-stops/{trip_id}")
async def get_nearby_stops(trip_id: int, payload:StudentLocationIn,  db: Annotated[AsyncSession, Depends(get_db)], user: Annotated[User, Depends(get_current_user)], _: Annotated[User, Depends(require_role("student"))]):
    return await student_services.get_nearby_stops(trip_id, payload, db)


# @router.get("/route/{route_id}/stops")
# async def get_stops():
#     return await student_services.get_stops(db, route_id)

