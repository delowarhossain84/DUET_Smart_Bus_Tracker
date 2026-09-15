from fastapi import FastAPI
from fastapi.middleware.httpsredirect import HTTPSRedirectMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.middleware.cors import CORSMiddleware

from app.middleware.request_id import RequestIDMiddleware
from app.middleware.security import SecurityHeadersMiddleware

from app.core.config import settings

def register_middleware(app:FastAPI):
    # app.add_middleware(MaintenanceMiddleware)

    # app.add_middleware(RequestSizeMiddleware)

    app.add_middleware(
        TrustedHostMiddleware,
        allowed_hosts=settings.ALLOWED_HOSTS,
    )

    app.add_middleware(RequestIDMiddleware)

    # app.add_middleware(CorrelationIDMiddleware)

    app.add_middleware(SecurityHeadersMiddleware)

    app.add_middleware(
        GZipMiddleware,
        minimum_size=1000,
        compresslevel=5,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.CORS_ORIGINS,
        allow_credentials=True,
        allow_methods=[
            "GET",
            "POST",
            "PUT",
            "PATCH",
            "DELETE",
            "OPTIONS",
        ],
        allow_headers=["*"],
        expose_headers=[
            "Content-Disposition",
            "X-Request-ID",
            "X-Correlation-ID",
        ],
        max_age=86400,
    )

    # app.add_middleware(LoggingMiddleware)