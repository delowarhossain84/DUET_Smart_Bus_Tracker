from pydantic import (
    BaseModel,
    Field,
)
from app.schemas.base import BaseResponse
from datetime import date
from typing import List, Optional
from app.enums.user_enums import UserRole
class User(BaseModel):
    name:str 
    email:str
    password:str = Field(default=..., description='Password of the user', min_length=8)
    mobile: str
    dob:date
    gender:str
    full_name:str = Field(default=None, description='Full name of the user')
    role:str = Field(default=UserRole.ADMIN, description='Role of the user. Roles are [admin, patient, doctor]')

class StudentSchema(User):
    role:str = Field(default=UserRole.STUDENT, description='Role of the user. Roles are [admin, patient, doctor]')
    address:str = Field(default=None, description='Address of the user')
    student_id:str = Field(default=..., description='Student ID of the user')
    current_semester:str = Field(default=..., description='Current semester of the user')

class UserUpdateSchema(BaseModel):
    name:str|None = Field(default=None, description='Name of the user')
    email:str|None = Field(default=None, description='Email of the user')
    mobile:str|None = Field(default=None, description='Mobile number of the user')
    dob:date|None = Field(default=None, description='Date of birth of the user')
    gender:str|None = Field(default=None, description='Gender of the user')
    full_name:str|None = Field(default=None, description='Full name of the user')
    

class StudentUpdateData(BaseModel):
    address:str|None = Field(default=None, description='Address of the user')
    student_id:str|None = Field(default=None, description='Student ID of the user')
    current_semester:str|None = Field(default=None, description='Current semester of the user')

class StudentUpdateSchema(UserUpdateSchema, StudentUpdateData):
    pass


class DriverSchema(User):
    role:str = Field(default=UserRole.DRIVER, description='Role of the user. Roles are [admin, patient, doctor]')
    address:str = Field(default=None, description='Address of the user')
    license_plate:str = Field(default=None, description='License plate of the user')
    license_plate_expiry:date = Field(default=None, description='License plate expiry date of the user')
    emergency_contact_name:str = Field(default=None, description='Emergency contact name of the user')
    emergency_contact_phone:str = Field(default=None, description='Emergency contact phone number of the user')

class DriverUpdateData(BaseModel):
    address:str|None = Field(default=None, description='Address of the user')
    license_plate:str|None = Field(default=None, description='License plate of the user')
    license_plate_expiry:date|None = Field(default=None, description='License plate expiry date of the user')
    emergency_contact_name:str|None = Field(default=None, description='Emergency contact name of the user')
    emergency_contact_phone:str|None = Field(default=None, description='Emergency contact phone number of the user')

class DriverUpdateSchema(UserUpdateSchema, DriverUpdateData):
    pass

class ShowUser(BaseModel):
    name: str
    email: str
    mobile:str
    dob:date
    gender:str
    role:str = Field(default='student', description='Role of the user. Roles are [admin, patient, doctor]')

class ResponseUser(BaseResponse):
    data:ShowUser


