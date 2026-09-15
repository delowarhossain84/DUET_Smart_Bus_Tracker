from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends
from typing import Annotated
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import TypeAdapter, ValidationError
from datetime import datetime, timezone

from app.core.outh2 import get_current_user, require_role, get_current_user_ws
from app.schemas.user import User
from app.schemas.student import StudentWebSocketSchema

from app.websocket.manager import manager
# from app.services.student_service import StudentService
from app.utils.logger import logging

from app.db.base import get_db

from app.schemas.websocket import DistanceUpdate, StudentLocationIn, WSError
from app.services.geo import estimate_eta_seconds, haversine_distance_m


adapter = TypeAdapter(StudentWebSocketSchema)

router = APIRouter(
    prefix="/ws"
)

@router.websocket("/trip/{trip_id}")
async def trip_websocket(websocket:WebSocket, trip_id:str, user: Annotated[User, Depends(get_current_user_ws)]):
    await manager.connect(trip_id, user.id, websocket)
    # await manager.connect(trip_id, 1, websocket)
    try:
        while True:
            raw = await websocket.receive_json()
            try:
                msg = StudentLocationIn.model_validate(raw)
            except ValidationError as exc:
                await manager.send_to(
                    websocket, WSError(message=str(exc)).model_dump(mode="json")
                )
                continue
            print(f"Update student location: lat={msg.lat}, lng={msg.lng} for trip {trip_id}")
            
            await manager.update_student_location(
                trip_id, websocket, msg.lat, msg.lng, datetime.now(tz=timezone.utc)
            )
            # bus_location = manager.get_last_bus_location(trip_id)
            # if bus_location is None:
            #     await manager.send_to(
            #         websocket,
            #         WSError(message="No bus location yet for this trip").model_dump(mode="json"),
            #     )
            #     continue
            # distance_m = haversine_distance_m(
            #     msg.lat, msg.lng, bus_location.lat, bus_location.lng
            # )

            # eta = estimate_eta_seconds(distance_m, bus_location.speed_kmh)
            # update = DistanceUpdate(
            #     type="distance_update",
            #     trip_id=trip_id,
            #     distance_meters=round(distance_m, 1),
            #     eta_seconds=round(eta, 1) if eta is not None else None,
            #     bus_timestamp=bus_location.timestamp,
            #     student_timestamp=datetime.now(tz=timezone.utc),
            # )
            # await manager.send_to(websocket, update.model_dump(mode="json"))
    except WebSocketDisconnect:
        manager.disconnect(trip_id, websocket)
    except Exception:
        logging.exception("Unexpected error on trip %s websocket", trip_id)

