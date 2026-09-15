

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from sqlalchemy.exc import IntegrityError, SQLAlchemyError

from app.core.exceptions import AppException

from app.utils.logger import logging


def register_exception_handlers(app: FastAPI):

    @app.exception_handler(AppException)
    async def app_exception_handler(request: Request, exc: AppException):

        logging.warning(exc.message)

        return JSONResponse(
            status_code=exc.status_code,
            content={
                "success": False,
                "message": exc.message,
            },
        )


    @app.exception_handler(RequestValidationError)
    async def validation_handler(request: Request, exc: RequestValidationError):

        return JSONResponse(
            status_code=422,
            content={
                "success": False,
                "message": "Validation failed.",
                "errors": exc.errors(),
            },
        )


    @app.exception_handler(IntegrityError)
    async def integrity_handler(request: Request, exc: IntegrityError):

        logging.exception("Integrity Error")

        return JSONResponse(
            status_code=409,
            content={
                "success": False,
                "message": "Duplicate resource.",
            },
        )


    @app.exception_handler(SQLAlchemyError)
    async def database_handler(request: Request, exc: SQLAlchemyError):

        logging.exception("Database Error")

        return JSONResponse(
            status_code=500,
            content={
                "success": False,
                "message": "Database error.",
            },
        )


    @app.exception_handler(Exception)
    async def unknown_handler(request: Request, exc: Exception):

        logging.exception("Unexpected Exception")

        return JSONResponse(
            status_code=500,
            content={
                "success": False,
                "message": "Internal server error.",
            },
        )