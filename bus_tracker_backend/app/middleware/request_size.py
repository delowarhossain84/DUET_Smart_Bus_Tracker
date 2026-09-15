"""
Request Size Middleware.

Responsibilities
----------------
- Reject oversized HTTP requests.
- Return HTTP 413.
- Skip requests without Content-Length.
- Store request size for downstream middleware.

This middleware does not read the request body.
"""

from __future__ import annotations

from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import JSONResponse

from app.core.config import settings


class RequestSizeMiddleware(BaseHTTPMiddleware):
    """
    Reject requests larger than the configured limit.
    """

    async def dispatch(self, request: Request, call_next):

        content_length = request.headers.get("Content-Length")

        if content_length is not None:

            try:
                size = int(content_length)
            except ValueError:
                return JSONResponse(
                    status_code=400,
                    content={
                        "success": False,
                        "message": "Invalid Content-Length header.",
                    },
                )

            request.state.request_size = size

            if size > settings.MAX_REQUEST_SIZE:
                return JSONResponse(
                    status_code=413,
                    content={
                        "success": False,
                        "message": "Request payload is too large.",
                        "meta": {
                            "max_size": settings.MAX_REQUEST_SIZE,
                            "received": size,
                        },
                    },
                )

        else:
            request.state.request_size = None

        return await call_next(request)