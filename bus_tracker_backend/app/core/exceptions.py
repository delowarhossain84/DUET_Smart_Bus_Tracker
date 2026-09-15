class AppException(Exception):
    """Base application exception."""

    status_code = 500
    message = "Internal server error."

    def __init__(self, message=None):
        if message:
            self.message = message


class NotFoundException(AppException):
    status_code = 404


class AlreadyExistsException(AppException):
    status_code = 409


class UnauthorizedException(AppException):
    status_code = 401


class ForbiddenException(AppException):
    status_code = 403


class BadRequestException(AppException):
    status_code = 400


class DatabaseException(AppException):
    status_code = 500
    message = "Database error."