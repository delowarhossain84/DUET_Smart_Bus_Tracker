# app/realtime/student_store.py

from dataclasses import dataclass, field
from datetime import datetime, UTC
from fastapi import WebSocket


@dataclass
class StudentConnection:
    student_id: int
    websocket: WebSocket

    # Selected bus
    bus_id: int | None = None

    # Latest GPS
    latitude: float | None = None
    longitude: float | None = None

    connected_at: datetime = field(default_factory=lambda: datetime.now(UTC))
    updated_at: datetime | None = None


class StudentStore:

    def __init__(self) -> None:
        self._connections: dict[WebSocket, StudentConnection] = {}

    # -------------------------------------------------
    # Connection Management
    # -------------------------------------------------

    async def add(
        self,
        websocket: WebSocket,
        student_id: int,
    ) -> StudentConnection:

        connection = StudentConnection(
            student_id=student_id,
            websocket=websocket,
        )

        self._connections[websocket] = connection

        return connection

    async def remove(
        self,
        websocket: WebSocket,
    ) -> None:

        self._connections.pop(websocket, None)

    # -------------------------------------------------
    # Update Methods
    # -------------------------------------------------

    async def subscribe_bus(
        self,
        websocket: WebSocket,
        bus_id: int,
    ) -> None:

        student = self._connections.get(websocket)

        if student is None:
            return

        student.bus_id = bus_id

    async def update_location(
        self,
        websocket: WebSocket,
        latitude: float,
        longitude: float,
    ) -> None:

        student = self._connections.get(websocket)

        if student is None:
            return

        student.latitude = latitude
        student.longitude = longitude
        student.updated_at = datetime.now(UTC)

    # -------------------------------------------------
    # Query Methods
    # -------------------------------------------------

    def get(
        self,
        websocket: WebSocket,
    ) -> StudentConnection | None:

        return self._connections.get(websocket)

    def get_by_student_id(
        self,
        student_id: int,
    ) -> StudentConnection | None:

        for student in self._connections.values():

            if student.student_id == student_id:
                return student

        return None

    def get_students_by_bus(
        self,
        bus_id: int,
    ) -> list[StudentConnection]:

        return [
            student
            for student in self._connections.values()
            if student.bus_id == bus_id
        ]

    def get_all(self) -> list[StudentConnection]:

        return list(self._connections.values())

    def total_connections(self) -> int:

        return len(self._connections)

    # -------------------------------------------------
    # Utility
    # -------------------------------------------------

    def is_connected(
        self,
        websocket: WebSocket,
    ) -> bool:

        return websocket in self._connections

    def clear(self) -> None:

        self._connections.clear()


student_store = StudentStore()