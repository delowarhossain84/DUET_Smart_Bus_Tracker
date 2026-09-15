from fastapi import APIRouter, Depends, status, HTTPException, Request, Response

from fastapi.security import OAuth2PasswordRequestForm

from sqlalchemy.orm import Session
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Annotated

from datetime import datetime, timezone, timedelta


# from . import schemas, database, models, access_token

from app.core.hashing import Hash
from app.models import user as user_models
from app.models.user import UserSession, User

from app.db.base import get_db
from app.core import access_token
from app.schemas.security import ( 
                                  RefreshTokenRequest )

from app.core.outh2 import get_current_token
from app.core.access_token import create_access_token

from app.repositories.user_repositories import get_user
from app.services.user_service import create_new_session

REFRESH_TOKEN_EXPIRY = 2


router = APIRouter(
    prefix='/auth',
    tags=['authentication']
)


@router.post('/login')
async def login(
    request: Request,
    response: Response,
    form_data: Annotated[OAuth2PasswordRequestForm, Depends()],
    db:Annotated[AsyncSession, Depends(get_db)]
):


    user= await get_user(db, email=form_data.username)

    if not user or not Hash.verify(user.password, form_data.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials"
        )

    # Create tokens
    access_token, _ = create_access_token(
        data={
            'email': user.email,
            'user_uid': str(user.id),
            "role":user.role
        }
    )
    refresh_token, expire = create_access_token(
        data={
            'email': user.email,
            'user_uid': str(user.id),
            "role":user.role
        },
        refresh=True,
        expiry=timedelta(days=REFRESH_TOKEN_EXPIRY)
    )



    # refresh_token, expire = create_refresh_token(
    #     data={
    #         'email': user.email,
    #         'user_uid': str(user.id)
    #     }
    # )

    response.set_cookie(
        key="access_token",
        value=access_token,
        httponly=True,
        secure=True,
        samesite="lax",
        max_age=15 * 60,  # 15 minutes
        path="/"
    )
    
    response.set_cookie(
        key="refresh_token",
        value=refresh_token,
        httponly=True,
        secure=True,
        samesite="strict",
        max_age=REFRESH_TOKEN_EXPIRY * 24 * 60 * 60,  # 2 days
        path="/auth/refresh"
    )


    # Create session
    session = await create_new_session(db, request, user.id, refresh_token, expire)

    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer"
    }

 

# @router.post('/refresh-token', response_model=TokenResponse)
# def refresh_access_token(
#     request: RefreshTokenRequest,
#     db: Session = Depends(get_db)
# ):
#     """
#             Refresh Token

#             A refresh token is a long-lived authentication token used to obtain
#             a new access token after the current access token expires.

#             Access tokens are usually short-lived (e.g., 10–15 minutes) for security reasons.
#             When an access token expires, the user does not need to log in again.
#             Instead, the client sends the refresh token to the server to request
#             a new access token.

#             Purpose:
#             - Improves security by keeping access tokens short-lived.
#             - Provides a smooth user experience without frequent re-login.
#             - Allows the server to manage sessions (revoke, rotate, or invalidate tokens).

#             Security Notes:
#             - Refresh tokens should be stored securely (HTTP-only cookies or secure storage).
#             - They should have a longer expiration time than access tokens.
#             - They can be stored in the database to allow logout and session revocation.
#             - Refresh token rotation is recommended to prevent replay attacks.

#             In summary:
#             Access Token = short-term access credential.
#             Refresh Token = long-term credential used to generate new access tokens.
#         """

#     credential_exception = HTTPException(
#         status_code=status.HTTP_401_UNAUTHORIZED,
#         detail="Invalid refresh token"
#     )

#     try:
#         payload = jwt.decode(
#             request.refresh_token,
#             SECRET_KEY,
#             algorithms=[ALGORITHM]
#         )

#         user_id = payload.get("sub")

#         if not user_id:
#             raise credential_exception

#     except JWTError:
#         raise credential_exception

#     # Find session
#     session = db.query(UserSession).filter(
#         UserSession.refresh_token == request.refresh_token
#     ).first()

#     if not session:
#         raise credential_exception

#     if session.is_revoked:
#         raise credential_exception

#     if session.expires_at < datetime.now(timezone.utc):
#         raise credential_exception

#     # Rotate refresh token
#     new_refresh_token, expire = create_refresh_token(
#         data={"sub": str(user_id)}
#     )

#     session.refresh_token = new_refresh_token
#     session.expires_at = expire
#     session.last_used_at = datetime.now(timezone.utc)

#     db.commit()

#     # Create new access token
#     new_access_token = create_access_token(
#         data={"sub": str(user_id)}
#     )

#     return {
#         "access_token": new_access_token,
#         "refresh_token": new_refresh_token,
#         "token_type": "bearer"
#     }

@router.post('/logout')
def logout(
    request: RefreshTokenRequest,
    db: Session = Depends(get_db)
):

    session = db.query(UserSession).filter(
        UserSession.refresh_token == request.refresh_token
    ).first()

    if not session:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid session"
        )

    session.is_revoked = True
    db.commit()

    return {
        "message": "Logged out successfully"
    }

@router.post("/logout-all")
def logout_all(current_user: User = Depends(get_current_token),
               db: Session = Depends(get_db)):

    db.query(UserSession).filter(
        UserSession.user_id == current_user.id
    ).update({"is_revoked": True})

    db.commit()

    return {"message": "Logged out from all devices"}

# POST   /auth/register
# POST   /auth/login
# POST   /auth/logout
# POST   /auth/refresh-token
# GET    /auth/me

# POST   /auth/register/patient
# POST   /auth/register/doctor
# POST   /auth/register/admin

