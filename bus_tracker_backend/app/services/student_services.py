from fastapi import status, HTTPException
from datetime import datetime, timezone

from app.repositories import student_repositories
from app.schemas.student import AvailableTrips

from app.schemas.base import *
from app.schemas.student import AvailableTrip, AvailableTrips, RouteDetail
from app.core.context import get_request_id
from app.services.geo import haversine_distance_m

def _response(status_code, success, message, data=None):
    return BaseResponse(
        status=status_code,
        success=success,
        message=message,
        lang="en",
        data=data or [],
        meta=Meta(timestamp=datetime.now(timezone.utc), request_id=get_request_id())
    )

async def get_available_trips(db):
    trips, total = await student_repositories.get_available_trips(db)
    output = []
    for trip in trips:
        output.append(
            AvailableTrip(
                id=trip.id,
                trip_id=trip.trip_id,
                bus_id=trip.bus_id,
                started_at=trip.started_at,
                route=RouteDetail(
                    route_id=trip.route.id,
                    name=trip.route.name,
                    code=trip.route.code,
                    starting_stop=trip.route.stops[0].stop.name ,
                    ending_stop=trip.route.stops[-1].stop.name ,
                    )
                )
        )
    return AvailableTrips(
        status=status.HTTP_200_OK, 
        message="Available trips fetched successfully",
        lang="en", success=True, data=output, 
        meta=Meta(pagination=PaginationMeta(page=1, per_page=len(output), returned_items=total, total_items=total, total_pages=1, has_next=False, has_previous=False),
                    timestamp=datetime.now(timezone.utc)), request_id=get_request_id()
        )

async def get_nearby_stops(trip_id, payload, db):
    trip = await student_repositories.get_trip(db, trip_id)
    if trip is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Trip not found")

    nearest_stop = None
    nearest_distance = None
    for stop in trip.route.stops:
        distance = haversine_distance_m(payload.lat, payload.lng, stop.stop.lattitude, stop.stop.longitude)
        if nearest_stop is None or distance < nearest_distance:
            nearest_stop = stop
            nearest_distance = distance

    return _response(status_code=status.HTTP_200_OK, success=True, message="Nearest stop fetched successfully", data=[{
        "stop_id": nearest_stop.stop.id,
        "name": nearest_stop.stop.name,
        "latitude": nearest_stop.stop.lattitude,
        "longitude": nearest_stop.stop.longitude,
        "distance": nearest_distance
    }])


        
        
