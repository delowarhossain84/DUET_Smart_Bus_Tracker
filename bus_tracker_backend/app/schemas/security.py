from pydantic import (
    BaseModel,
)

from app.schemas.base import BaseResponse
class Login(BaseModel):
    username: str
    password:str

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: str | None = None

class LogOut(BaseModel):
    message:str
    
class LogOutResponse(BaseResponse):
    data:LogOut

from pydantic import BaseModel

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class RefreshTokenRequest(BaseModel):
    refresh_token: str