import re

from app.repositories import user_repositories


from app.schemas.base import BaseResponse

from fastapi import status, HTTPException
from datetime import datetime, timezone

from app.core.hashing import Hash

from app.schemas.user import (
    User as UserSchema,
    ShowUser,
    ResponseUser,
    UserUpdateSchema,
    StudentUpdateData,
    DriverUpdateData
)

from app.schemas.base import BaseResponse, Meta
from app.core.context import get_request_id

from app.enums.user_enums import DriverStatus

def _response(status_code, success, message,lang='en', data=None):
    return BaseResponse(status=status_code, success=success,message=message, lang='en', data=data,meta=Meta(request_id=None, timestamp=datetime.now(tz=timezone.utc)))

def _get_update_data(schema):
    return {
        key:value for key, value in schema.model_dump().items() 
        if value is not None
    }

async def create_new_user(db, payload):
    if payload.password is None or len(payload.password) < 8:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Password must be at least 8 characters long"
        )
    if not re.search(r"[A-Za-z]", payload.password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Password must contain at least one letter"
        )
    
    
    user = await user_repositories.get_user(db, email=payload.email)
    if user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    data = {
        "username":payload.name,
        "email":payload.email,
        "password":Hash.hash(payload.password),
        "dob":payload.dob,
        'mobile':payload.mobile,
        "gender":payload.gender,
        "role":payload.role
    }

    new_user = await user_repositories.create_user(db, data)

    return ResponseUser(
        status=status.HTTP_201_CREATED,
        success=True,
        message="User created successfully",
        lang="en",
        data=ShowUser(
            name=new_user.username,
            email=new_user.email,
            mobile=new_user.mobile,
            dob=new_user.dob,
            gender=new_user.gender,
            role=new_user.role
        ),
        meta=Meta(
            request_id=get_request_id(),
            timestamp = datetime.now(tz=timezone.utc)
        )
    )

async def create_new_student(db, payload):
    user = await user_repositories.get_user(db, email=payload.email)
    if user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    data = {
        "username":payload.name,
        "email":payload.email,
        "password":Hash.hash(payload.password),
        "dob":payload.dob,
        'mobile':payload.mobile,
        "gender":payload.gender,
        "role":payload.role,
    }
    new_user = await user_repositories.create_user(db, data)
    user_info = {
        "user_id":new_user.id,
        "full_name":payload.name,
        "status":DriverStatus.ACTIVE,
        "address":payload.address,
        "student_id":payload.student_id,
        "current_semester":payload.current_semester
    }
    await user_repositories.create_student_info(db, user_info)
    return ResponseUser(
        status=status.HTTP_201_CREATED,
        success=True,
        message="User created successfully",
        lang="en",
        data=ShowUser(
            name=new_user.username,
            email=new_user.email,
            mobile=new_user.mobile,
            dob=new_user.dob,
            gender=new_user.gender,
            role=new_user.role
        ),
        meta=Meta(
            request_id=get_request_id(),
            timestamp = datetime.now(tz=timezone.utc)
        )
    )

async def update_student(db, student_id, payload):
    user = await user_repositories.get_user(db, student_id)
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    user_info = UserUpdateSchema.model_validate(payload)
    student_info = StudentUpdateData.model_validate(payload)
    await user_repositories.update_user(db, user.id, _get_update_data(user_info))
    await user_repositories.update_student(db, student_id, _get_update_data(student_info))
    return _response(status_code=status.HTTP_200_OK, success=True, message="User updated successfully")

async def create_new_driver(db, payload):    
    user = await user_repositories.get_user(db, email=payload.email)
    if user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    data = {
        "username":payload.name,
        "email":payload.email,
        "password":Hash.hash(payload.password),
        "dob":payload.dob,
        'mobile':payload.mobile,
        "gender":payload.gender,
        "role":payload.role,
    }
    new_user = await user_repositories.create_user(db, data)
    user_info = {
        "user_id":new_user.id,
        "full_name":payload.name,
        "status":DriverStatus.INACTIVE,
        "address":payload.address,
        "license_plate":payload.license_plate,
        "license_plate_expiry":payload.license_plate_expiry,
        "emergency_contact_name":payload.emergency_contact_name,
        "emergency_contact_phone":payload.emergency_contact_phone
    }
    await user_repositories.create_driver_info(db, user_info)
    return ResponseUser(
        status=status.HTTP_201_CREATED,
        success=True,
        message="User created successfully",
        lang="en",
        data=ShowUser(
            name=new_user.username,
            email=new_user.email,
            mobile=new_user.mobile,
            dob=new_user.dob,
            gender=new_user.gender,
            role=new_user.role
        ),
        meta=Meta(
            request_id=get_request_id(),
            timestamp = datetime.now(tz=timezone.utc)
        )
    )

async def update_driver(db, driver_id, payload):
    user = await user_repositories.get_user(db, driver_id)
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    user_info = UserUpdateSchema.model_validate(payload)
    driver_info = DriverUpdateData.model_validate(payload)
    await user_repositories.update_user(db, user.id, _get_update_data(user_info))
    await user_repositories.update_driver(db, driver_id, _get_update_data(driver_info))
    return _response(status_code=status.HTTP_200_OK, success=True, message="User updated successfully")


async def create_new_session(db,request, user_id, refresh_token, expire):
    # Extract device info
    ip_address = request.headers.get(
        "x-forwarded-for", request.client.host
    )
    user_agent = request.headers.get("user-agent")

    session = {
        "user_id":user_id,
        "refresh_token":refresh_token,
        "device_name":"unknown",
        "device_type":"unknown",
        "ip_address":ip_address,
        "user_agent":user_agent,
        "expires_at":expire,
        "is_revoked":False,
        "created_at":datetime.now(timezone.utc),
        "last_used_at":datetime.now(timezone.utc)
    }

    session = await user_repositories.create_session(db, session)
    return session


