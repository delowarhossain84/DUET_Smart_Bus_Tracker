from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload, joinedload

from app.repositories.base_repo import BaseGeneric, get_data_by_filter, add_data, base_update, base_bulk_update_many
from app.models.buses import Trip, Route, Stop, RouteStop
from app.enums.bus_enums import TripStatus

async def get_available_trips(db):
    return await get_data_by_filter(db, Trip,is_first=False, filters=[Trip.status == TripStatus.RUNNING],
                options=[selectinload(Trip.route).options(selectinload(Route.stops).options(joinedload(RouteStop.stop)))])

async def get_trip(db, trip_id):
    return await get_data_by_filter(db, Trip, filters=[Trip.id == trip_id],
                        options=[selectinload(Trip.route).options(selectinload(Route.stops).options(joinedload(RouteStop.stop)))])