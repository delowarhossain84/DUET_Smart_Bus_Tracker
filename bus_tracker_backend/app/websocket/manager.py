from __future__ import annotations
import asyncio
from dataclasses import dataclass, field
from datetime import datetime
from fastapi import WebSocket, WebSocketDisconnect
from collections import defaultdict

from app.schemas.websocket import BusLocationBroadcast, WSError, DistanceUpdate
from app.services.geo import estimate_eta_seconds, haversine_distance_m
from app.utils.data_class import live_bus_store
from app.utils.logger import logging

@dataclass
class StudentState:
    student_id: str
    lat: float | None = None
    lng: float | None = None
    timestamp: datetime | None = None

@dataclass
class TripRoom:
    connections: dict[WebSocket, StudentState] = field(default_factory=dict)  # ws -> student_id
    last_bus_location:BusLocationBroadcast | None = None
    lock:asyncio.Lock = field(default_factory=asyncio.Lock)


class ConnectionManager:
    def __init__(self):
        self._rooms:dict[str, TripRoom] = {}

    def _get_room(self, trip_id:str) -> TripRoom:
        return self._rooms.setdefault(trip_id, TripRoom())

    async def connect(self, trip_id:str, student_id:str, websocket:WebSocket) -> None:
        await websocket.accept()
        room = self._get_room(trip_id)
        async with room.lock:
            room.connections[websocket] = StudentState(student_id=student_id)
        # Send whatever we already know so the student doesn't wait for
        # the next bus ping. distance stays None until they send a fix.
        if room.last_bus_location is not None:
            await websocket.send_json(room.last_bus_location.model_dump(mode="json"))

    def disconnect(self, trip_id:str, websocket:WebSocket) -> None:
        room = self._get_room(trip_id)
        if room is None:
            return
        room.connections.pop(websocket, None)

        if not room.connections and room.last_bus_location is None:
            self._rooms.pop(trip_id, None)

    async def update_bus_location(self, trip_id:str, location:BusLocationBroadcast) -> None:
        room = self._get_room(trip_id)
        room.last_bus_location = location
        await self.broadcast(trip_id, location.model_dump(mode="json"))

    async def broadcast(self, trip_id:str, message:dict) -> None:
        room = self._get_room(trip_id)
        if room is None:
            return
        async with room.lock:
            targets = list(room.connections.items())
        dead:list[WebSocket] = []
        print("length: ", len(targets))
        for ws, state in targets:
            print(f"broadcasting to student {state.student_id}, lat={state.lat}, lng={state.lng}")
            try:
                # await ws.send_json(message)
                await self._send_update(
                    ws, trip_id, message, state.lat, state.lng, state.timestamp
                )
            except Exception:
                logging.warning("Dropping dead websocket for trip %s", trip_id)
                dead.append(ws)
        for ws in dead:
            self.disconnect(trip_id, ws)

    async def send_to(self, websocket: WebSocket, payload: dict) -> None:
        await websocket.send_json(payload)

    async def update_student_location(
        self,
        trip_id: str,
        websocket: WebSocket,
        lat: float,
        lng: float,
        timestamp: datetime,
    ) -> bool:
        """Returns False (and sends an error) if there's no bus fix yet for this trip."""
        room = self._get_room(trip_id)
        state = room.connections.get(websocket)
        if state is None:
            return False
        state.lat, state.lng, state.timestamp = lat, lng, timestamp
        print(f"Updated student {state.student_id} location: lat={lat}, lng={lng}, timestamp={timestamp}")
        
        if room.last_bus_location is None:
            await self.send_error(websocket, "No bus location yet for this trip")
            return False
 
        await self._send_update(websocket, trip_id, room.last_bus_location, lat, lng, timestamp)
        return True

    async def _send_update(
        self,
        websocket: WebSocket,
        trip_id: str,
        location: BusLocationBroadcast,
        student_lat: float | None,
        student_lng: float | None,
        student_timestamp: datetime | None,
    ) -> None:
        
        distance_m = eta = None
        print(f"sending update: lat={student_lat}, lng={student_lng}")

        if student_lat is not None and student_lng is not None:
            distance_m = round(haversine_distance_m(student_lat, student_lng, location.lat, location.lng), 1)
            eta = estimate_eta_seconds(distance_m, location.speed_kmh)
            eta = round(eta, 1) if eta is not None else None

        print(f"distance_m={distance_m}, eta={eta}, bus_timestamp={location.timestamp}, student_timestamp={student_timestamp}")
        update = DistanceUpdate(
            trip_id=trip_id,
            bus_id=location.bus_id,
            bus_lat=location.lat,
            bus_lng=location.lng,
            bus_speed_kmh=location.speed_kmh,
            bus_heading=location.heading,
            bus_timestamp=location.timestamp,
            distance_meters=distance_m,
            eta_seconds=eta,
            student_timestamp=student_timestamp,
        )
        
        await websocket.send_json(update.model_dump(mode="json"))

    async def send_error(self, websocket: WebSocket, message: str) -> None:
        await websocket.send_json(WSError(message=message).model_dump(mode="json"))
 
            
    def get_last_bus_location(self, trip_id: str) -> BusLocationBroadcast | None:
        room = self._rooms.get(trip_id)
        return room.last_bus_location if room else None


manager = ConnectionManager()

    