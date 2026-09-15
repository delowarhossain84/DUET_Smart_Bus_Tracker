from fastapi import HTTPException, status
from datetime import datetime, timezone

from app.repositories import admin_repositories

from app.schemas.base import BaseResponse, Meta

from app.schemas.admin import BusDetailsSchema, CurrentLocationSchema, DashboardResponse, DriverDetailsSchema, TripDetailsSchema, DashboardSchema, TripDetailsSchema, DriverListSchema,DriverDetailsSchema, RouteListDataSchema,RouteDetailsSchema,  BusListDataSchema, BusDetailsSchema, TripListDataSchema

from app.websocket.manager import manager

from app.enums.user_enums import DriverStatus

def _response(status_code, success, message,lang='en', data=None):
    return BaseResponse(
        status=status_code,
        success=success,
        message=message,
        lang=lang,
        data=data,
        meta=Meta(request_id=None, timestamp=datetime.now(tz=timezone.utc))
    )

def _map_trip(trip):
    current_location = manager.get_last_bus_location(trip.trip_id) if trip.status == "running" else None
    if current_location:
        current_location = CurrentLocationSchema(latitude=current_location.lat, longitude=current_location.lng)
    else:
        current_location = None
    return TripDetailsSchema( id=trip.id,trip_id=trip.trip_id,device_id=trip.device_id,app_version=trip.app_version,
            started_at=trip.started_at,ended_at=trip.ended_at,status=trip.status,
            route_id=trip.route_id,route_name=trip.route.name,
            started_from=trip.route.stops[0].stop.name, destination=trip.route.stops[-1].stop.name,
            driver_id=trip.driver_id,driver_name=trip.driver.full_name,
            bus_id=trip.bus_id, bus_name=trip.bus.name,
            current_location=current_location
    )

def _map_driver(driver):
    return DriverDetailsSchema(
        id=driver.id, username=driver.user.username, full_name=driver.full_name, status=driver.status, address=driver.address, license_plate=driver.license_plate,
        license_plate_expiry=driver.license_plate_expiry, total_triped=driver.total_triped, joining_date=driver.created_at, emergency_contact_name=driver.emergency_contact_name, emergency_contact_phone=driver.emergency_contact_phone
    )

def _map_route(route):
    return RouteDetailsSchema(
        id=route.id, name=route.name, code=route.code, description=route.description, 
        is_active=route.is_active, starting_point=route.stops[0].stop.name, 
        ending_point=route.stops[-1].stop.name)

async def _map_bus(db, bus):
    trip = await admin_repositories.get_trip_by_bus_id(db, bus.id)

    return BusDetailsSchema(
        id=bus.id, name=bus.name, registration_number=bus.registration_number, capacity=bus.capacity, 
        route_id=bus.route_id, is_active=bus.is_active, is_running=trip.status == "running" if trip else False,
    )

async def get_dashboard(db):
    buses, total_buses = await admin_repositories.get_buses_for_dashboard(db)
    routes, total_routes = await admin_repositories.get_routes_dashboard(db)
    drivers, total_drivers = await admin_repositories.get_drivers(db, None)
    trips, total_trips = await admin_repositories.get_trips(db, None)

    trips_data = [_map_trip(trip) for trip in trips]
    drivers_data = [_map_driver(driver) for driver in drivers]
    routes_data = [_map_route(route) for route in routes]
    buses_data = [await _map_bus(db, bus) for bus in buses]

    return DashboardResponse(
        status=status.HTTP_200_OK,
        success=True,
        lang='en',
        message="Dashboard retrieved successfully.",
        data=DashboardSchema(trips=TripListDataSchema(data=trips_data, total=total_trips), drivers=DriverListSchema(data=drivers_data, total=total_drivers), routes=RouteListDataSchema(data=routes_data, total=total_routes), buses=BusListDataSchema(data=buses_data, total=total_buses)),
        meta=Meta(request_id=None, timestamp=datetime.now(tz=timezone.utc))
    )







    
#===============================================================================
#                             Bus Management
#===============================================================================


async def create_bus(payload, db):
    bus = {
        "name": payload.name,
        "registration_number": payload.registration_number,
        "capacity": payload.capacity,
        "route_id": payload.route_id,
        "is_active": payload.is_active,
    
    }

    await admin_repositories.create_bus(db, bus)
    return _response(status_code=status.HTTP_201_CREATED, success=True, message="Bus created successfully.")

async def get_buses(db, payload):
    buses = await admin_repositories.get_buses(db, payload)
    data = [
        {'id': bus.id, 'name': bus.name, 'registration_number': bus.registration_number, 'capacity': bus.capacity, 'route_id': bus.route_id, 'is_active': bus.is_active} for bus in buses
    ]
    return _response(status_code=status.HTTP_200_OK, success=True, message="Buses retrieved successfully.", data=data)

async def get_bus_details(bus_id, db):
    bus, trip = await admin_repositories.get_bus_details(db, bus_id)
    if trip:
        current_location = manager.get_last_bus_location(trip.trip_id) if trip.status == "running" else None
    else:
        current_location = None
    if current_location:
        current_location = CurrentLocationSchema(latitude=current_location.lat, longitude=current_location.lng)
    else:
        current_location = None

    output = BusDetailsSchema(
        id=bus.id,
        name=bus.name,
        registration_number=bus.registration_number,
        capacity=bus.capacity,
        route_id=bus.route_id,
        is_active=bus.is_active,
        is_running=trip.status == "running" if trip else False,
        current_location=current_location,
    )
    return _response(status_code=status.HTTP_200_OK, success=True, message="Bus details retrieved successfully.", data=output)

async def update_bus_details(bus_id, payload, db):
    bus = {}
    if payload.name is not None:
        bus["name"] = payload.name
    if payload.registration_number is not None:
        bus["registration_number"] = payload.registration_number
    if payload.capacity is not None:
        bus["capacity"] = payload.capacity
    if payload.route_id is not None:
        bus["route_id"] = payload.route_id
    if payload.is_active is not None:
        bus["is_active"] = payload.is_active
    await admin_repositories.update_bus_details(db, bus_id, bus)
    return _response(status_code=status.HTTP_200_OK, success=True, message="Bus details updated successfully.")

async def delete_bus(bus_id, db):
    await admin_repositories.delete_bus(db, bus_id)
    return _response(status_code=status.HTTP_200_OK, success=True, message="Bus deleted successfully.")

#===============================================================================
#                             Stop Management
#===============================================================================
async def create_stop(payload, db):
    stop = {
        "name": payload.name,
        "lattitude": payload.lattitude,
        "longitude": payload.longitude,
        "is_active": True,
    }
    await admin_repositories.create_stop(db, stop)
    return _response(status_code=status.HTTP_201_CREATED, success=True, message="Stop created successfully.", data=[])

async def get_stops(payload, db):
    items, total = await admin_repositories.get_stops(db, payload)
    data = [
        {'id': stop.id, 'name': stop.name, 'lattitude': stop.lattitude, 'longitude': stop.longitude, 'is_active': stop.is_active}
        for stop in items
    ]
    
    return _response(status_code=status.HTTP_200_OK, success=True, message="Stops retrieved successfully.", data={"data": data, "total": total, "page": payload.page, "per_page": (payload.page - 1) * payload.per_page}) 

async def get_stop_details(stop_id, db):
    stop = await admin_repositories.get_stop_details(db, stop_id)
    if stop is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Stop not found")
    return _response(status_code=status.HTTP_200_OK, success=True, message="Stop details retrieved successfully.", data={"name": stop.name, "lattitude": stop.lattitude, "longitude": stop.longitude, "is_active": stop.is_active})

async def update_stop_details(stop_id, payload, db):
    stop = {}
    if payload.name is not None:
        stop["name"] = payload.name
    if payload.lattitude is not None:
        stop["lattitude"] = payload.lattitude
    if payload.longitude is not None:
        stop["longitude"] = payload.longitude
    if payload.is_active is not None:
        stop["is_active"] = payload.is_active
    await admin_repositories.update_stop_details(db, stop_id, stop)
    return _response(status_code=status.HTTP_200_OK, success=True, message="Stop details updated successfully.")

async def delete_stop(stop_id, db):
    await admin_repositories.delete_stop(db, stop_id)
    return _response(status_code=status.HTTP_200_OK, success=True, message="Stop deleted successfully.")

#===============================================================================
#                             Route Management
#===============================================================================
async def create_route(payload, db):
    route = {
        "name": payload.name,
        "code": payload.code,
        "description": payload.description,
        "is_active": payload.is_active,
    }
    route = await admin_repositories.create_route(db, route)
    if payload.stop_ids is not None:
        stops = []
        for stop in payload.stop_ids:
            stops.append({
                "stop_id": stop.stop_id,
                "stop_order": stop.stop_order,
                "route_id": route.id
            })
        await admin_repositories.add_stop_to_route(db, stops)
    return _response(status_code=status.HTTP_201_CREATED, success=True, message="Route created successfully.")

async def get_routes(payload, db):
    routes = await admin_repositories.get_routes(db, payload)
    data = [
        {'id': route.id, 'name': route.name, 'code': route.code, 'description': route.description, 'is_active': route.is_active} 
        for route in routes['items']
    ]
    return _response(status_code=status.HTTP_200_OK, success=True, message="Routes retrieved successfully.", data={"data": data, "total": routes["total"]})

async def get_route_details(route_id, db):
    route = await admin_repositories.get_route_details(db, route_id)
    if route is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Route not found")
    stops = [{
        "id": stop.id,
        "name": stop.stop.name,
        "lattitude": stop.stop.lattitude,
        "longitude": stop.stop.longitude,
        "is_active": stop.stop.is_active,
        "stop_order": stop.stop_order
    } for stop in route.stops]
    return _response(status_code=status.HTTP_200_OK, success=True, message="Route details retrieved successfully.", data={"id": route.id, "name": route.name, "code": route.code, "description": route.description, "is_active": route.is_active, "stops": stops})

async def update_route_details(route_id, payload, db):
    route = {}
    if payload.name is not None:
        route["name"] = payload.name
    if payload.code is not None:
        route["code"] = payload.code
    if payload.description is not None:
        route["description"] = payload.description
    if payload.is_active is not None:
        route["is_active"] = payload.is_active
    await admin_repositories.update_route_details(db, route_id, route)
    return _response(status_code=status.HTTP_200_OK, success=True, message="Route details updated successfully.")

async def delete_route(route_id, db):
    await admin_repositories.delete_route(db, route_id)
    return _response(status_code=status.HTTP_200_OK, success=True, message="Route deleted successfully.")

async def add_stop_to_route(route_id, payload, db):
    route = await admin_repositories.get_route_details(db, route_id)
    if route is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Route not found")
    
    route_stops, _ = await admin_repositories.get_route_stops(db, route_id)
    
    order_changed_stops = []
    for stop in route_stops:
        if stop.stop_order >= payload.stop_order:
            stop.stop_order += 1
            order_changed_stops.append({"id": stop.id, "stop_order": stop.stop_order})
    if len(order_changed_stops) > 0:
        await admin_repositories.update_route_stops(db, route_id, order_changed_stops)

    new_stop = {
        "stop_id": payload.stop_id,
        "stop_order": payload.stop_order,
        "route_id": route_id
    }
    await admin_repositories.add_stop_to_route(db, [new_stop])
    return _response(status_code=status.HTTP_200_OK, success=True, message="Stop added successfully.")

async def remove_stop_from_route(route_id, stop_id, db):
    route = await admin_repositories.get_route_details(db, route_id)
    if route is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Route not found")
    route_stops, _ = await admin_repositories.get_route_stops(db, route_id)
    if len(route_stops) == 1:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="There must be at least one stop in the route")
    deleted_stop = [stop for stop in route_stops if stop.stop_id == stop_id][0]
    chnaged_stops = []
    for stop in route_stops:
        if stop.stop_id > deleted_stop.stop_id:
            stop.stop_order -= 1
            chnaged_stops.append({"id": stop.id, "stop_order": stop.stop_order})
    await admin_repositories.update_route_stops(db, route_id, chnaged_stops)
    await admin_repositories.remove_stop_from_route(db, stop_id)
    return _response(status_code=status.HTTP_200_OK, success=True, message="Stop removed successfully.")


# =============================================================================
#                             Driver Management
# =============================================================================
async def activate_driver(driver_id, db):
    driver = await admin_repositories.get_driver_details(db, driver_id)
    if driver is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Driver not found")
    driver.status = DriverStatus.ACTIVE
    await admin_repositories.update_driver_details(db, driver_id, {"status": driver.status})
    return _response(status_code=status.HTTP_200_OK, success=True, message="Driver activated successfully.")

async def get_drivers(payload, db):
    drivers, total = await admin_repositories.get_drivers(db, payload)
    output =[
        {'id': driver.id, 'name': driver.user.username, 'status': driver.status} 
        for driver in drivers
    ]
    return _response(status_code=status.HTTP_200_OK, success=True, message="Drivers retrieved successfully.", data={"data": output, "total": total})

async def get_driver_details(driver_id, db):
    driver, latest_trip = await admin_repositories.get_driver_details_with_trip(db, driver_id)
    if driver is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Driver not found")
    output = DriverDetailsSchema(
        id=driver.id,
        username=driver.user.username,
        full_name=driver.full_name,
        status=driver.status,
        address=driver.address,
        license_plate=driver.license_plate,
        license_plate_expiry=driver.license_plate_expiry,
        total_triped=driver.total_triped,
        joining_date=driver.created_at,
        emergency_contact_name=driver.emergency_contact_name,
        emergency_contact_phone=driver.emergency_contact_phone,
        current_status=latest_trip.status if latest_trip else None,
    )
    return _response(status_code=status.HTTP_200_OK, success=True, message="Driver details retrieved successfully.", data=output)


# =============================================================================
#                             Trip Management
# =============================================================================
async def get_trips(status, db):
    trips = await admin_repositories.get_trips(db, status)
    output =[
        {'id': trip.id, 'bus_id': trip.bus_id, 'route_id': trip.route_id, 'device_id': trip.device_id, 'app_version': trip.app_version, 'started_at': trip.started_at, 'ended_at': trip.ended_at, 'status': trip.status} 
        for trip in trips
    ]
    return _response(status_code=status.HTTP_200_OK, success=True, message="Trips retrieved successfully.", data={"data": output})

async def get_trip_details(trip_id, db):
    trip = await admin_repositories.get_trip_details(db, trip_id)
    if trip is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Trip not found")
    current_location = manager.get_last_bus_location(trip.trip_id) if trip.status == "running" else None
    if current_location:
        current_location = CurrentLocationSchema(latitude=current_location.lat, longitude=current_location.lng)
    else:
        current_location = None
    output = TripDetailsSchema(
        id=trip.id,
        bus_id=trip.bus_id,
        route_id=trip.route_id,
        device_id=trip.device_id,
        app_version=trip.app_version,
        started_at=trip.started_at,
        ended_at=trip.ended_at,
        status=trip.status,
        current_location=current_location,
        driver=DriverDetailsSchema(
            id=trip.driver_id,
            full_name=trip.driver.name,
            status=trip.driver.status,
        )
    )
    return _response(status_code=status.HTTP_200_OK, success=True, message="Trip details retrieved successfully.", data=output)

    