import uuid

from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware

from app.core.context import request_id_ctx


class RequestIDMiddleware(BaseHTTPMiddleware):
    """
    Production-grade Request ID middleware.

    Features:
    - Uses incoming X-Request-ID if present
    - Generates UUID4 if absent
    - Stores in request.state
    - Stores in ContextVar
    - Returns X-Request-ID response header
    """

    HEADER_NAME = "X-Request-ID"

    async def dispatch(self, request: Request, call_next):
        request_id = request.headers.get(self.HEADER_NAME)

        if not request_id:
            request_id = str(uuid.uuid4())

        request.state.request_id = request_id

        token = request_id_ctx.set(request_id)

        try:
            response = await call_next(request)
        finally:
            request_id_ctx.reset(token)

        response.headers[self.HEADER_NAME] = request_id

        return response