from contextvars import ContextVar

request_id_ctx: ContextVar[str | None] = ContextVar(
    "request_id",
    default=None
)

def get_request_id():
    return request_id_ctx.get()


correlation_id_ctx: ContextVar[str | None] = ContextVar(
    "correlation_id",
    default=None
)


locale_ctx: ContextVar[str] = ContextVar(
    "locale",
    default="en",
)