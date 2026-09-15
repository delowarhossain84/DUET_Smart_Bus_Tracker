from fastapi import APIRouter, Depends, status, HTTPException, Form
from sqlalchemy.orm import Session
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Annotated

from app.db.base import get_db
from app.models.user import User
from app.schemas.user import (
    User as UserSchema,
    StudentSchema,
    DriverSchema,
    StudentUpdateSchema,
    DriverUpdateSchema
)
from app.core.hashing import Hash
from app.core.outh2 import get_current_user

from app.services import user_service

router = APIRouter(
    prefix='/users',
    tags=['users']
)

@router.post('/register', status_code=status.HTTP_201_CREATED)
async def create_user(payload:UserSchema, db:Annotated[AsyncSession, Depends(get_db)]):
    # Check if user with the same email already exists
    response = await user_service.create_new_user(db, payload)
    return response

@router.post("/register/student", status_code=status.HTTP_201_CREATED)
async def create_student(payload:StudentSchema, db:Annotated[AsyncSession, Depends(get_db)]):
    # Check if user with the same email already exists
    response = await user_service.create_new_student(db, payload)
    return response

@router.post("/register/driver", status_code=status.HTTP_201_CREATED)
async def create_driver(payload:DriverSchema, db:Annotated[AsyncSession, Depends(get_db)]):
    # Check if user with the same email already exists
    response = await user_service.create_new_driver(db, payload)
    return response

@router.patch("/student/{student_id}", status_code=status.HTTP_200_OK)
async def update_student(student_id:int, payload:StudentUpdateSchema, db:Annotated[AsyncSession, Depends(get_db)]):
    # Check if user with the same email already exists
    response = await user_service.update_student(db, student_id, payload)
    return response

@router.patch("/driver/{driver_id}", status_code=status.HTTP_200_OK)
async def update_driver(driver_id:int, payload:DriverUpdateSchema, db:Annotated[AsyncSession, Depends(get_db)]):
    # Check if user with the same email already exists
    response = await user_service.update_driver(db, driver_id, payload)
    return response

@router.patch("/user/{user_id}", status_code=status.HTTP_200_OK)
async def update_user(user_id:int, payload:UserSchema, db:Annotated[AsyncSession, Depends(get_db)]):
    # Check if user with the same email already exists
    response = await user_service.update_user(db, user_id, payload)
    return response
