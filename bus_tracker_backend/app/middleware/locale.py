"""
Locale Middleware.

Responsibilities
----------------
- Detect user's locale.
- Validate supported locales.
- Store locale in request.state.
- Store locale in ContextVar.

Priority:

1. X-Locale header
2. Accept-Language header
3. Default application locale
"""

from __future__ import annotations

from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware

from app.core.config import settings
from app.core.context import locale_ctx


class LocaleMiddleware(BaseHTTPMiddleware):
    """
    Middleware for locale detection.
    """

    LOCALE_HEADER = "X-Locale"

    async def dispatch(self, request: Request, call_next):
        locale = self._detect_locale(request)

        request.state.locale = locale

        token = locale_ctx.set(locale)

        try:
            response = await call_next(request)
        finally:
            locale_ctx.reset(token)

        response.headers["Content-Language"] = locale

        return response

    def _detect_locale(self, request: Request) -> str:
        """
        Detect the preferred locale.
        """

        # --------------------------------------------------------
        # Highest priority
        # --------------------------------------------------------
        locale = request.headers.get(self.LOCALE_HEADER)

        if locale:
            locale = locale.lower()

            if locale in settings.SUPPORTED_LOCALES:
                return locale

        # --------------------------------------------------------
        # Accept-Language
        # --------------------------------------------------------
        accept_language = request.headers.get("Accept-Language")

        if accept_language:

            languages = [
                item.split(";")[0].strip().lower()
                for item in accept_language.split(",")
            ]

            for language in languages:

                language = language.split("-")[0]

                if language in settings.SUPPORTED_LOCALES:
                    return language

        # --------------------------------------------------------
        # Default
        # --------------------------------------------------------
        return settings.DEFAULT_LOCALE