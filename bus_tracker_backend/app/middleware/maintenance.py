"""
Maintenance Mode Middleware.

Responsibilities
----------------
- Block requests when maintenance mode is enabled.
- Allow configured paths.
- Allow configured IPs.
- Return HTTP 503.

This middleware should be placed early in the middleware stack.
"""

from __future__ import annotations

from ipaddress import ip_address

from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import JSONResponse

from app.core.config import settings


class MaintenanceMiddleware(BaseHTTPMiddleware):
    """
    Maintenance mode middleware.
    """

    async def dispatch(self, request: Request, call_next):

        # -------------------------------------------------------------
        # Maintenance disabled
        # -------------------------------------------------------------
        if not settings.MAINTENANCE_MODE:
            return await call_next(request)

        # -------------------------------------------------------------
        # Allow excluded paths
        # -------------------------------------------------------------
        if request.url.path in settings.MAINTENANCE_EXCLUDED_PATHS:
            return await call_next(request)

        # -------------------------------------------------------------
        # Allow whitelisted IPs
        # -------------------------------------------------------------
        client_ip = self._get_client_ip(request)

        if client_ip in settings.MAINTENANCE_ALLOWED_IPS:
            return await call_next(request)

        # -------------------------------------------------------------
        # Service unavailable
        # -------------------------------------------------------------
        return JSONResponse(
            status_code=503,
            content={
                "success": False,
                "message": (
                    "The service is temporarily unavailable due to scheduled "
                    "maintenance. Please try again later."
                ),
                "meta": {
                    "maintenance": True
                },
            },
        )

    @staticmethod
    def _get_client_ip(request: Request) -> str:
        """
        Resolve the real client IP.
        """

        for header in (
            "CF-Connecting-IP",
            "X-Forwarded-For",
            "X-Real-IP",
        ):
            value = request.headers.get(header)

            if value:
                ip = value.split(",")[0].strip()

                try:
                    return str(ip_address(ip))
                except ValueError:
                    pass

        if request.client:
            return request.client.host

        return "unknown"