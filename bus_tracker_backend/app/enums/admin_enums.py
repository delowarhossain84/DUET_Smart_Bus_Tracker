from enum import Enum

class BusFilterStatus(str, Enum):
    ACTIVE = "active"
    INACTIVE = "inactive"
    RUNNING = "running"
