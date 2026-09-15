from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload, joinedload,contains_eager
from sqlalchemy import select, func

from app.repositories.base_repo import BaseGeneric, get_data_by_filter, add_data, base_update, base_bulk_update_many, base_delete, add_bulk_data
from app.models.buses import Bus, Route, Trip, Stop, RouteStop
from app.models.user import DriverInfo

from app.enums.admin_enums import BusFilterStatus

async def create_bus(db, data): return await add_data(db, Bus, data)

async def get_buses_for_dashboard(db):
    return await get_data_by_filter(db, Bus,is_first=False, filters=[Bus.is_active == True])

async def get_trip_by_bus_id(db, bus_id):
    return await get_data_by_filter(db, Trip, filters=[Trip.bus_id == bus_id])

async def get_buses(db, payload):
    query = select(Bus).distinct()

    if payload.status == BusFilterStatus.RUNNING:
        query = query.join(
            Trip,
            Trip.bus_id == Bus.id
        ).where(
            Trip.status == "running"
        )

    elif payload.status == BusFilterStatus.INACTIVE:
        query = query.where(
            Bus.is_active.is_(False)
        )

    elif payload.status == BusFilterStatus.ACTIVE:
        query = query.where(
            Bus.is_active.is_(True)
        )

    if payload.route_id is not None:
        query = query.where(
            Bus.route_id == payload.route_id
        )

    result = await db.execute(query)

    return result.scalars().all()

    # filters = []
    
    # if payload.status == BusFilterStatus.RUNNING:
    #     filters.append(Trip.status == "running")
    # if payload.route_id is not None:
    #     filters.append(Bus.route_id == payload.route_id)
    # if payload.status == BusFilterStatus.INACTIVE:
    #     filters.append(Bus.is_active == False)
    # if payload.status == BusFilterStatus.ACTIVE:
    #     filters.append(Bus.is_active == True)
    # return await get_data_by_filter(db, Bus, filters=filters,is_first=False, order_by=Bus.id.desc(), joins=[Trip])

async def get_bus_details(db, bus_id):
    bus = await get_data_by_filter(db, Bus, filters=[Bus.id == bus_id])
    if bus is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Bus not found")
    trip = await get_data_by_filter(db, Trip, filters=[Trip.bus_id == bus_id])
    # if trip is None:
    #     raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Trip not found")
    
    return bus, trip

async def update_bus_details(db, bus_id, payload):
    return await base_update(db, Bus, payload, filters=[Bus.id == bus_id])

async def delete_bus(db, bus_id):
    return await base_delete(db, Bus, filters=[Bus.id == bus_id])

# =============================================================================
#                             Stop Management
# =============================================================================
async def create_stop(db, payload):
    return await add_data(db, Stop, payload)

async def get_stops(db, payload):
    column = {"created_at": Stop.created_at, "updated_at": Stop.updated_at, "name": Stop.name}.get(payload.sort_by, Stop.created_at)
    order_clause = column.desc() if payload.sort_order == "desc" else column.asc()

    query = (
        select(Stop)
        # .join(RouteStop, RouteStop.stop_id == Stop.id)
        # .where(RouteStop.route_id == payload.route_id)
        .order_by(order_clause)
        .distinct()
    )
    if payload.route_id is not None:
        query = query.join(RouteStop, RouteStop.stop_id == Stop.id)
        query = query.where(RouteStop.route_id == payload.route_id)

    
    if payload.is_active is not None:
        query = query.where(Stop.is_active == payload.is_active)

    count_query = (
        select(func.count(func.distinct(Stop.id)))
        .select_from(Stop)
        # .join(RouteStop, RouteStop.stop_id == Stop.id)
        # .where(RouteStop.route_id == payload.route_id)
    )

    if payload.route_id is not None:
        count_query = count_query.join(RouteStop, RouteStop.stop_id == Stop.id)
        count_query = count_query.where(RouteStop.route_id == payload.route_id)

    if payload.is_active is not None:
        count_query = count_query.where(Stop.is_active == payload.is_active)

    total = (await db.execute(count_query)).scalar_one()

    query = query.offset((payload.page - 1) * payload.per_page).limit(payload.per_page)

    result = await db.execute(query)
    items = result.unique().scalars().all()

    return items, total

    # filters = []
    # if payload.route_id is not None:
    #     filters.append(RouteStop.route_id == payload.route_id)
    # if payload.is_active is not None:
    #     filters.append(Stop.is_active == payload.is_active)

    # column = {"created_at": Stop.created_at, "updated_at": Stop.updated_at, "name": Stop.name}.get(payload.sort_by, Stop.created_at)
    # repo = BaseGeneric(Stop, db)
    # items = await repo.paginate(page=payload.page, per_page=payload.per_page, filters=filters, 
    #                             order_by=[column.desc() if payload.sort_order == "desc" else column.asc()], 
    #                             joins=[(RouteStop, RouteStop.stop_id == Stop.id)], options=[selectinload(Stop.route_stops)])
    # return {"items": items, "total": await repo.count(filters=filters), "page": payload.page, "per_page": (payload.page - 1) * payload.per_page}

async def get_stop_details(db, stop_id):
    return await get_data_by_filter(db, Stop, filters=[Stop.id == stop_id])

async def update_stop_details(db, stop_id, payload):
    return await base_update(db, Stop, payload, filters=[Stop.id == stop_id])

async def delete_stop(db, stop_id):
    return await base_delete(db, Stop, filters=[Stop.id == stop_id])


# =============================================================================
#                             Route Management
# =============================================================================
async def create_route(db, payload):
    return await add_data(db, Route, payload, is_commit=False)

async def add_stop_to_route(db, payload):
    return await add_bulk_data(db, RouteStop, payload, is_commit=False)

async def get_routes(db, payload):
    filters = []
    if payload.name is not None:
        filters.append(Route.name.like(f"%{payload.name}%"))
    if payload.is_active is not None:
        filters.append(Route.is_active == payload.is_active)
    if payload.search is not None:
        filters.append(Route.name.like(f"%{payload.search}%"))
    column = {"created_at": Route.created_at, "updated_at": Route.updated_at, "name": Route.name}.get(payload.sort_by, Route.created_at)
    repo = BaseGeneric(Route, db)
    items = await repo.paginate(filters=filters, order_by=[column.desc() if payload.sort_order == "desc" else column.asc()])
    return {"items": items, "total": await repo.count(filters=filters)}

async def get_routes_dashboard(db):
    return await get_data_by_filter(db, Route,is_first=False,filters=[Route.is_active==True], options=[selectinload(Route.stops).options(selectinload(RouteStop.stop))])

async def get_route_details(db, route_id):
    return await get_data_by_filter(db, Route, filters=[Route.id == route_id], options=[selectinload(Route.stops).options(selectinload(RouteStop.stop))])

async def update_route_details(db, route_id, payload):
    return await base_update(db, Route, payload, filters=[Route.id == route_id])

async def delete_route(db, route_id):
    return await base_delete(db, Route, filters=[Route.id == route_id])

async def update_route_stops(db, route_id, payload):
    return await base_bulk_update_many(db, RouteStop, payload, is_commit=False)

async def get_route_stops(db, route_id):
    return await get_data_by_filter(db, RouteStop,is_first=False, filters=[RouteStop.route_id == route_id])

async def remove_stop_from_route(db, stop_id):
    return await base_delete(db, RouteStop, filters=[RouteStop.id == stop_id])


# =============================================================================
#                             Driver Management
# =============================================================================
async def get_driver_details(db, driver_id):
    return await get_data_by_filter(db, DriverInfo, filters=[DriverInfo.id == driver_id])

async def get_driver_details_with_trip(db, driver_id):
    driver = await get_data_by_filter(db, DriverInfo, filters=[DriverInfo.id == driver_id], options=[selectinload(DriverInfo.user)])
    if driver is None:
        return None, None
    trip = await get_data_by_filter(db, Trip, filters=[Trip.driver_id == driver_id], order_by=[Trip.started_at.desc()])
    return driver, trip
    
async def update_driver_details(db, driver_id, payload):
    return await base_update(db, DriverInfo, payload, filters=[DriverInfo.id == driver_id])

async def get_drivers(db, status):
    filters = []
    if status is not None: filters.append(DriverInfo.status == status)
    return await get_data_by_filter(db, DriverInfo,is_first=False, filters=filters, options=[selectinload(DriverInfo.user)])

# =============================================================================
#                             Trip Management
# =============================================================================
async def get_trips(db, status):
    filters = []
    if status is not None:
        filters.append(Trip.status == status)

    return await get_data_by_filter(db, Trip, filters=filters, is_first=False,
                            options=[
                                selectinload(Trip.driver),
                                selectinload(Trip.bus),
                                selectinload(Trip.route).options(selectinload(Route.stops).options(selectinload(RouteStop.stop)))
                            ])


async def get_trip_details(db, trip_id):
    return await get_data_by_filter(db, Trip, filters=[Trip.id == trip_id], options=[selectinload(Trip.driver)])
