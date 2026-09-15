from __future__ import annotations
from sqlalchemy.orm import Session
from fastapi import HTTPException

from typing import Any, Generic, Optional, Sequence, Type, TypeVar

from sqlalchemy import delete as sa_delete
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.sql import Select

T = TypeVar("T")

class BaseRepository:
    def __init__(self, model):
        self.model = model
    def create(self, db, data):
        obj = self.model(**data)
        db.add(obj)
        db.commit()
        db.refresh(obj)
        return obj
    
    # def filter_elements(self, filters):
    #     return self.db.query(self.model).filter(**filters).all()

    # def remove_filter():
    #     pass







class BaseGeneric(Generic[T]):
    """
    Generic async repository.

    IMPORTANT — Unit of Work contract:
    This repository NEVER commits or rolls back the transaction.
    It only `add`s / `flush`es. The calling service (or a UnitOfWork
    context manager) owns the transaction boundary and is responsible
    for `commit()` / `rollback()`. This lets a service compose multiple
    repository calls (e.g. create order + reserve stock + write outbox
    event) into a single atomic transaction.

    `flush()` is used instead of `commit()` where a generated PK or
    server-side default is needed before continuing — flush pushes SQL
    to the DB within the current transaction without ending it.
    """

    def __init__(self, model: Type[T], db: AsyncSession):
        self.model = model
        self.db = db

    # ==========================================================
    # Query Builder
    # ==========================================================

    def query(self) -> Select:
        return select(self.model)

    def build_query(
        self,
        *,
        filters: Optional[Sequence[Any]] = None,
        filter_by: Optional[dict] = None,
        joins: Optional[Sequence[Any]] = None,
        outer_joins: Optional[Sequence[Any]] = None,
        options: Optional[Sequence[Any]] = None,
        order_by: Optional[Sequence[Any]] = None,
        group_by: Optional[Sequence[Any]] = None,
        having: Optional[Sequence[Any]] = None,
        distinct: bool = False,
        offset: Optional[int] = None,
        limit: Optional[int] = None,
        with_for_update: bool = False,
        skip_locked: bool = False,
        nowait: bool = False,
    ) -> Select:
        query = self.query()

        if joins:
            for join in joins:
                query = query.join(join)
            

        if outer_joins:
            for join in outer_joins:
                query = query.outerjoin(join)
            
            
        if options:
            query = query.options(*options)

        if filters:
            query = query.filter(*filters)

        if filter_by:
            query = query.filter_by(**filter_by)

        if group_by:
            query = query.group_by(*group_by)

        if having:
            query = query.having(*having)

        if order_by:
            query = query.order_by(*order_by)

        if distinct:
            query = query.distinct()

        if offset is not None:
            query = query.offset(offset)

        if limit is not None:
            query = query.limit(limit)

        # Row locking — use for inventory reservation, payment attempt
        # claiming, or any read-then-write step that must not race.
        # skip_locked is useful for worker/queue-style claiming where you
        # want to skip rows another transaction already holds rather than
        # block on them.
        if with_for_update:
            query = query.with_for_update(
                nowait=nowait,
                skip_locked=skip_locked,
            )

        return query

    # ==========================================================
    # CREATE
    # ==========================================================

    async def create(self, **kwargs) -> T:
        obj = self.model(**kwargs)
        self.db.add(obj)
        await self.db.flush()
        return obj

    async def bulk_create(self, objects: list[dict]) -> list[T]:
        instances = [self.model(**obj) for obj in objects]
        self.db.add_all(instances)
        await self.db.flush()
        return instances

    # ==========================================================
    # READ
    # ==========================================================

    async def get_by_id(self, id: Any, *, options=None) -> Optional[T]:
        query = self.query().where(self.model.id == id)

        if options:
            query = query.options(*options)

        result = await self.db.execute(query)
        return result.scalar_one_or_none()

    async def get_by_id_for_update(
        self, id: Any, *, skip_locked: bool = False, nowait: bool = False
    ) -> Optional[T]:
        """Fetch a row with FOR UPDATE lock — use for stock decrements,
        payment attempt claiming, or any read-modify-write under concurrency."""
        query = (
            self.query()
            .where(self.model.id == id)
            .with_for_update(nowait=nowait, skip_locked=skip_locked)
        )
        result = await self.db.execute(query)
        return result.scalar_one_or_none()

    async def first(self, **kwargs) -> Optional[T]:
        result = await self.db.execute(self.build_query(**kwargs))
        return result.scalars().first()

    async def one(self, **kwargs) -> T:
        result = await self.db.execute(self.build_query(**kwargs))
        return result.scalars().one()

    async def one_or_none(self, **kwargs) -> Optional[T]:
        result = await self.db.execute(self.build_query(**kwargs))
        return result.scalars().one_or_none()

    async def all(self, **kwargs) -> list[T]:
        result = await self.db.execute(self.build_query(**kwargs))
        return list(result.scalars().all())

    async def paginate(
        self,
        *,
        page: int = 1,
        per_page: int = 20,
        **kwargs,
    ) -> list[T]:
        kwargs["offset"] = (page - 1) * per_page
        kwargs["limit"] = per_page
        return await self.all(**kwargs)

    async def count(self, **kwargs) -> int:
        # Drop order_by/offset/limit — irrelevant (and invalid) for a count query
        kwargs.pop("order_by", None)
        kwargs.pop("offset", None)
        kwargs.pop("limit", None)

        base_query = self.build_query(**kwargs).order_by(None)
        count_query = select(func.count()).select_from(base_query.subquery())

        result = await self.db.execute(count_query)
        return result.scalar_one()

    async def exists(self, **kwargs) -> bool:
        kwargs["limit"] = 1
        result = await self.db.execute(self.build_query(**kwargs))
        return result.scalars().first() is not None

    # ==========================================================
    # UPDATE
    # ==========================================================

    async def update(self, obj: T, **kwargs) -> T:
        for key, value in kwargs.items():
            setattr(obj, key, value)

        await self.db.flush()
        return obj

    # ==========================================================
    # DELETE
    # ==========================================================

    async def delete(self, obj: T) -> None:
        await self.db.delete(obj)
        await self.db.flush()

    async def delete_by_id(self, id: Any) -> bool:
        obj = await self.get_by_id(id)

        if obj is None:
            return False

        await self.db.delete(obj)
        await self.db.flush()
        return True

    async def bulk_delete(self, **kwargs) -> int:
        """Delete matching rows without loading them into memory first."""
        filters = kwargs.get("filters")
        filter_by = kwargs.get("filter_by")

        stmt = sa_delete(self.model)

        if filters:
            stmt = stmt.where(*filters)
        if filter_by:
            stmt = stmt.filter_by(**filter_by)

        result = await self.db.execute(stmt)
        await self.db.flush()
        return result.rowcount

    # ==========================================================
    # SESSION-LEVEL HELPERS
    # (transaction boundaries stay owned by the caller / UnitOfWork)
    # ==========================================================

    def add(self, obj: T) -> None:
        self.db.add(obj)

    def add_all(self, objs: Sequence[T]) -> None:
        self.db.add_all(objs)

    async def flush(self) -> None:
        await self.db.flush()

    async def refresh(self, obj: T) -> None:
        await self.db.refresh(obj)
    
async def base_update(db, model, payload, filters):
    repo = BaseGeneric(model, db)
    obj = await repo.first(filters=filters)

    if obj is None:
        raise HTTPException(404, detail=f"{model.__name__} not found")

    update_data = payload.model_dump(exclude_unset=True) if type(payload) != dict else payload
    if not update_data:
        return obj

    updated = await repo.update(obj, **update_data)
    await db.commit()
    return updated

async def base_bulk_update_many(db, model, items: list[dict], id_field="id", is_commit=True):
    """
    Each item in `items` must include its own id_field plus the fields to change.
    e.g. [{"id": 1, "priority": 5}, {"id": 2, "status": "ACTIVE"}]
    """
    repo = BaseGeneric(model, db)
    updated = []

    for item in items:
        item = dict(item)  # avoid mutating caller's dict
        obj_id = item.pop(id_field)

        obj = await repo.get_by_id(obj_id)
        if obj is None:
            raise HTTPException(404, detail=f"{model.__name__} {obj_id} not found")

        updated.append(await repo.update(obj, **item))
    if is_commit:
        await db.commit()
    return updated

async def add_data(db, model, data, is_commit=True):
    repo = BaseGeneric(model, db)
    output = await repo.create(**data)
    if is_commit:
        await db.commit()   
    return output

async def add_bulk_data(db, model, data, is_commit=True):
    repo = BaseGeneric(model, db)
    output = await repo.bulk_create(data)
    if is_commit:
        await db.commit()   
    return output


async def get_data_by_filter(db, model,is_first=True, **kwargs):
    repo = BaseGeneric(model, db)
    if is_first :
        return await repo.first(
            **kwargs
        )

    total = await repo.count(filters=kwargs["filters"])
    return await repo.all(
            **kwargs
        ), total

async def base_delete(db, model, filters):
    repo = BaseGeneric(model, db)
    obj = await repo.first(filters=filters)
    if obj is None:
        raise HTTPException(404, detail=f"{model.__name__} not found")
    await repo.delete(obj)
    return True
