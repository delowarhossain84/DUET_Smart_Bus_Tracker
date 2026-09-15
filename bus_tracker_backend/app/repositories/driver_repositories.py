from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.repositories.base_repo import BaseGeneric, get_data_by_filter, add_data, base_update, base_bulk_update_many
from app.models.buses import Trip, Route
from app.models.user import DriverInfo

async def get_trip(db, bus_id):
    trip_repo = BaseGeneric(Trip, db)
    trip =   await trip_repo.all(filters=[Trip.bus_id == bus_id], order_by=[Trip.started_at.desc()], limit=1)
    if len(trip) == 0:
        return None
    return trip[0]

async def create_trip(db, data): return await add_data(db, Trip, data)

async def get_route(db, route_id): return await get_data_by_filter(db, Route, filters=[Route.id == route_id])

async def get_driver(db, user_id): return await get_data_by_filter(db, DriverInfo, filters=[DriverInfo.user_id == user_id])