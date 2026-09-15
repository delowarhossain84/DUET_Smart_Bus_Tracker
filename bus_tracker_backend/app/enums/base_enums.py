
from sqlalchemy import Enum as SAEnum
from enum import Enum

def sa_enum(enum_cls: type, name: str):
    return SAEnum(
        enum_cls,
        name=name,
        native_enum=False,
        validate_strings=True,
        values_callable=lambda x: [e.value for e in x],
    )

class Status(Enum):
    active = "ACTIVE"
    inactive = "INACTIVE"

class WarningCode(str, Enum):
    RELATED_PRODUCT_NOT_FOUND = "RELATED_PRODUCT_NOT_FOUND"
    RELATED_PRODUCTS_SKIPPED = "RELATED_PRODUCTS_SKIPPED"
    DUPLICATE_TAG_REMOVED = "DUPLICATE_TAG_REMOVED"
    IMAGE_OPTIMIZATION_FAILED = "IMAGE_OPTIMIZATION_FAILED"
    PROMOTION_SKIPPED = "PROMOTION_SKIPPED"
    CACHE_UPDATE_FAILED = "CACHE_UPDATE_FAILED"
