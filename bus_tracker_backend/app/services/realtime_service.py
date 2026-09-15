from fastapi import WebSocket

# from app.realtime.bus_store import live_bus_store
from app.utils.data_class import live_bus_store

from app.utils.student_store import student_store
# from app.realtime.websocket_manager import websocket_manager
from app.websocket.manager import websocket_manager
from app.utils.geo import haversine

class RealtimeService:
    PROXIMITY_RADIUS = 30  # meters
    async def evaluate_student(
            self,
            websocket:WebSocket
    )-> None:
        student = student_store.get(websocket)
        if student is None:
            return

        if student.bus_id is None:
            return

        if student.latitude is None or student.longitude is None:
            return

        bus = await live_bus_store.get(student.bus_id)
        if bus is None:
            return
        distance = haversine(
            student.latitude,
            student.longitude,
            bus.latitude,
            bus.longitude,
        )
        response = {
            "event": "bus_update",
            "bus_id": bus.bus_id,
            "latitude": bus.latitude,
            "longitude": bus.longitude,
            "speed": bus.speed,
            "heading": bus.heading,
            "distance": round(distance, 2),
            "nearby": distance <= self.PROXIMITY_RADIUS,
            "updated_at": bus.updated_at.isoformat(),
        }
        await websocket_manager.send_json(
            websocket,
            response,
        )

    async def bus_location_update(
            self,
            bus_id:int,
    ) -> None:
        students = student_store.get_student_by_bus(bus_id)
        if not students:
            return
        for student in students:
            if (student.latitude is None or student.longitude is None):
                continue
            bus = await live_bus_store.get(bus_id)
            if bus is None:
                continue

            distance = haversine(
                student.latitude,
                student.longitude,
                bus.latitude,
                bus.longitude,
            )

            response = {
                "event": "bus_update",
                "bus_id": bus.bus_id,
                "latitude": bus.latitude,
                "longitude": bus.longitude,
                "speed": bus.speed,
                "heading": bus.heading,
                "distance": round(distance, 2),
                "nearby": distance <= self.PROXIMITY_RADIUS,
                "updated_at": bus.updated_at.isoformat(),
            }

            await websocket_manager.send_json(
                student.websocket,
                response,
            )

realtime_service = RealtimeService()
