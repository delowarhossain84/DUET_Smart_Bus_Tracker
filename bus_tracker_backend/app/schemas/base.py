from pydantic import(BaseModel, 
                     Field
                    )

from datetime import datetime
from typing import Any, Generic, List, Optional, TypeVar, Dict


from pydantic.generics import GenericModel
from app.enums.base_enums import WarningCode

T = TypeVar("T")


class PaginationMeta(BaseModel):
    page: int | None = None
    per_page: int | None = None
    returned_items: Optional[int] = None
    total_items: int | None = None
    total_pages: int | None = None
    has_next: bool | None = None
    has_previous: bool | None = None


class SortMeta(BaseModel):
    field: Optional[str] = None
    direction: Optional[str] = None

class WarningMessage(BaseModel):
    code: WarningCode
    message: str
    details: dict[str, Any] = Field(default_factory=dict)

class Meta(BaseModel):
    request_id: Optional[str] = None
    timestamp: datetime
    pagination: Optional[PaginationMeta] = None
    sort: Optional[SortMeta] = None
    filters: Optional[dict[str, Any]] = None

class ErrorDetail(BaseModel):
    code: str
    field: Optional[str] = None
    message: str


class BaseResponse(GenericModel, Generic[T]):
    status: int = Field(description='status code of the request')
    success:bool = Field(description='success of the request')
    message: str = Field(description='message of the status')
    lang: str = Field(description='language which you are return')
    # data:List[Optional[Dict]]
    data:T
    warnings:WarningMessage|None = None
    meta:Meta


class ErrorResponse(BaseModel):
    success: bool = False
    message: str
    errors: List[ErrorDetail] = Field(default_factory=list)
    meta: Optional[Meta] = None

