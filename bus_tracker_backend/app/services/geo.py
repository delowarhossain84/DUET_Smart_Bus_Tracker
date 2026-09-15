from math import asin, cos, radians, sin, sqrt
 
EARTH_RADIUS_M = 6_371_000
 
 
def haversine_distance_m(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """Great-circle distance between two points, in meters."""
    lat1_r, lng1_r, lat2_r, lng2_r = map(radians, (lat1, lng1, lat2, lng2))
    dlat = lat2_r - lat1_r
    dlng = lng2_r - lng1_r
    a = sin(dlat / 2) ** 2 + cos(lat1_r) * cos(lat2_r) * sin(dlng / 2) ** 2
    c = 2 * asin(sqrt(a))
    return EARTH_RADIUS_M * c
 
 
def estimate_eta_seconds(distance_m: float, speed_kmh: float | None) -> float | None:
    """Rough ETA from the bus's last reported speed. None if speed is unknown/near-zero."""
    if not speed_kmh or speed_kmh <= 0.5:
        return None
    speed_m_s = speed_kmh * 1000 / 3600
    return distance_m / speed_m_s