"""
IP Filter Middleware.

Responsibilities
----------------
- Block denied IP addresses
- Allow only whitelisted IPs (optional)
- Support proxy-aware IP detection
- Return HTTP 403 for blocked clients

This middleware is intended for business rules,
not DDoS protection.
"""

from __future__ import annotations

from ipaddress import ip_address
from typing import Final

from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import JSONResponse

from app.core.config import settings


class IPFilterMiddleware(BaseHTTPMiddleware):
    """
    Middleware for IP allowlist/blocklist enforcement.
    """

    CLIENT_IP_HEADERS: Final[tuple[str, ...]] = (
        "CF-Connecting-IP",
        "X-Forwarded-For",
        "X-Real-IP",
    )

    async def dispatch(self, request: Request, call_next):
        client_ip = self._get_client_ip(request)

        # Store for downstream use
        request.state.client_ip = client_ip

        # ------------------------------------------------------------------
        # Blocklist
        # ------------------------------------------------------------------
        if client_ip in settings.BLOCKED_IPS:
            return self._forbidden(client_ip)

        # ------------------------------------------------------------------
        # Allowlist (optional)
        # ------------------------------------------------------------------
        if settings.ALLOWED_IPS:
            if client_ip not in settings.ALLOWED_IPS:
                return self._forbidden(client_ip)

        return await call_next(request)

    @classmethod
    def _get_client_ip(cls, request: Request) -> str:
        """
        Resolve the real client IP behind common reverse proxies.
        """

        for header in cls.CLIENT_IP_HEADERS:
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

    @staticmethod
    def _forbidden(ip: str) -> JSONResponse:
        """
        Standard 403 response.
        """

        return JSONResponse(
            status_code=403,
            content={
                "success": False,
                "message": "Access denied.",
                "meta": {
                    "client_ip": ip
                }
            },
        )