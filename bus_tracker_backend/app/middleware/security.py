"""
Security middleware.

Responsibilities
----------------
- Add HTTP security headers
- Harden browser security
- Prevent clickjacking
- Prevent MIME sniffing
- Control referrer information
- Enable HSTS (HTTPS only)

This middleware should not perform authentication,
authorization, or CORS handling.
"""

from __future__ import annotations

from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware

from app.core.config import settings


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    """
    Add standard HTTP security headers to every response.
    """

    async def dispatch(self, request: Request, call_next):
        response = await call_next(request)

        # ---------------------------------------------------------------------
        # Prevent Clickjacking
        # ---------------------------------------------------------------------
        response.headers["X-Frame-Options"] = "DENY"

        # ---------------------------------------------------------------------
        # Prevent MIME type sniffing
        # ---------------------------------------------------------------------
        response.headers["X-Content-Type-Options"] = "nosniff"

        # ---------------------------------------------------------------------
        # Control referrer information
        # ---------------------------------------------------------------------
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"

        # ---------------------------------------------------------------------
        # Restrict browser features
        # ---------------------------------------------------------------------
        response.headers[
            "Permissions-Policy"
        ] = (
            "camera=(), "
            "microphone=(), "
            "geolocation=(), "
            "payment=(), "
            "usb=(), "
            "accelerometer=(), "
            "gyroscope=(), "
            "magnetometer=()"
        )

        # ---------------------------------------------------------------------
        # Content Security Policy
        # ---------------------------------------------------------------------
        response.headers[
            "Content-Security-Policy"
        ] = settings.CONTENT_SECURITY_POLICY

        # ---------------------------------------------------------------------
        # Cross-Origin Policies
        # ---------------------------------------------------------------------
        response.headers["Cross-Origin-Opener-Policy"] = "same-origin"

        response.headers["Cross-Origin-Resource-Policy"] = "same-origin"

        response.headers["Cross-Origin-Embedder-Policy"] = "require-corp"

        # ---------------------------------------------------------------------
        # DNS Prefetch
        # ---------------------------------------------------------------------
        response.headers["X-DNS-Prefetch-Control"] = "off"

        # ---------------------------------------------------------------------
        # Download protection
        # ---------------------------------------------------------------------
        response.headers["X-Download-Options"] = "noopen"

        # ---------------------------------------------------------------------
        # XSS Protection
        #
        # Modern browsers ignore this header, but it is harmless.
        # ---------------------------------------------------------------------
        response.headers["X-XSS-Protection"] = "1; mode=block"

        # ---------------------------------------------------------------------
        # Remove server fingerprint
        # ---------------------------------------------------------------------
        if "server" in response.headers:
            del response.headers["server"]

        # ---------------------------------------------------------------------
        # HSTS
        #
        # Only send over HTTPS.
        # ---------------------------------------------------------------------
        if request.url.scheme == "https":
            response.headers[
                "Strict-Transport-Security"
            ] = (
                "max-age=31536000;"
                " includeSubDomains;"
                " preload"
            )

        return response