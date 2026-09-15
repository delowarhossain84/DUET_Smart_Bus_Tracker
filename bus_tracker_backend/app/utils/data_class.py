from dataclasses import dataclass
from datetime import datetime


@dataclass
class BusLocation:
    bus_id: int
    latitude: float
    longitude: float
    speed: float
    heading: float
    captured_at: datetime


class LiveBusStore:

    def __init__(self):
        self.locations = {}

    async def update(
        self,
        bus_id: int,
        latitude: float,
        longitude: float,
        speed: float,
        heading: float,
        captured_at: datetime,
    ):
        self.locations[bus_id] = BusLocation(
            bus_id=bus_id,
            latitude=latitude,
            longitude=longitude,
            speed=speed,
            heading=heading,
            captured_at=captured_at,
        )

    async def get(self, bus_id: int):
        return self.locations.get(bus_id)


live_bus_store = LiveBusStore()