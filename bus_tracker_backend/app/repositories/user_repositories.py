from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from sqlalchemy.orm import Session
from app.repositories.base_repo import BaseGeneric, add_data, base_update
from app.models.user import User, UserSession, StudentInfo, DriverInfo


async def get_user(db, email=None, user_id=None):
    user_repo = BaseGeneric(User, db)
    filters = []
    if user_id is not None:
        filters.append(User.id == user_id)
    if email is not None:
        filters.append(User.email == email)

    user = await user_repo.first(
        filters=filters
    )
    
    return user

async def create_user(db, data):
    user_repo = BaseGeneric(User, db)
    new_user = await user_repo.create(**data)
    await db.commit()
    return new_user

async def create_session(db, data):
    session_repo = BaseGeneric(UserSession, db)
    new_session = await session_repo.create(**data)
    await db.commit()
    return new_session


async def create_student_info(db, data):
    await add_data(db, StudentInfo, data)

async def create_driver_info(db, data):
    await add_data(db, DriverInfo, data)

async def update_user(db, user_id, data): await base_update(db, User, data, filters=[User.id == user_id])
async def update_student(db, student_id, data): await base_update(db, StudentInfo, data, filters=[StudentInfo.id == student_id])
async def update_driver(db, driver_id, data): await base_update(db, DriverInfo, data, filters=[DriverInfo.id == driver_id])
    

