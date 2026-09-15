import enum

class UserRole(str, enum.Enum):
    USER = "user"
    ADMIN = "admin"
    DRIVER = "driver"
    STUDENT = "student"

class DriverStatus(str, enum.Enum):
    ACTIVE = "active"
    INACTIVE = "inactive"
    BLOCKED = "blocked"
    DELETED = "deleted"

class CurrentSemester(str, enum.Enum):
    SEM11 = "11"
    SEM12 = "12"
    SEM21 = "21"
    SEM22 = "22"
    SEM31 = "31"
    SEM32 = "32"
    SEM41 = "41"
    SEM42 = "42"