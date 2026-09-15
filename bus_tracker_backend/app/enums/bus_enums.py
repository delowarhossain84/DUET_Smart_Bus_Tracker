from enum import Enum

class TripStatus(str, Enum):
    RUNNING = "running"
    ENDED = "ended"
    