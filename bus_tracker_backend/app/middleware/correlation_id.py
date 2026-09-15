import uuid

from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware

from app.core.context import correlation_id_ctx


class CorrelationIDMiddleware(BaseHTTPMiddleware):
    """
    Production-grade Correlation ID middleware.

    Responsibilities
    ----------------
    - Read incoming X-Correlation-ID
    - Generate one if missing
    - Store in request.state
    - Store in ContextVar
    - Return in response header
    """

    HEADER_NAME = "X-Correlation-ID"

    async def dispatch(self, request: Request, call_next):

        correlation_id = request.headers.get(self.HEADER_NAME)

        if not correlation_id:
            correlation_id = str(uuid.uuid4())

        request.state.correlation_id = correlation_id

        token = correlation_id_ctx.set(correlation_id)

        try:
            response = await call_next(request)
        finally:
            correlation_id_ctx.reset(token)

        response.headers[self.HEADER_NAME] = correlation_id

        return response