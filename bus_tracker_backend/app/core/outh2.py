from fastapi import Depends, HTTPException, status, WebSocket
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from jose import jwt, JWTError
from cryptography.fernet import Fernet

# from . import access_token, models
from app.models import user as user_models

from app.core.config import settings
from app.repositories.user_repositories import (
    get_user
)

from app.db.base import (
    get_db, 
    AsyncSessionLocal
)


from app.utils.logger import logging

oauth2_scheme = OAuth2PasswordBearer(tokenUrl='/login')
fernet = Fernet(settings.ENCRYPTION_KEY)



    
# oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/login")

async def get_current_user_ws(
    websocket: WebSocket,
    db: Session = Depends(get_db),
) -> user_models.User:

    authorization = websocket.headers.get("authorization")

    if not authorization:
        await websocket.close(code=1008)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authorization header missing",
        )
    

    try:
        scheme, token = authorization.split(" ", 1)

        if scheme.lower() != "bearer":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Authorization header must start with Bearer",
            )
        
        decrypt_token = fernet.decrypt(token.encode()).decode()


        payload = jwt.decode(
            decrypt_token,
            settings.SECRET_KEY,
            algorithms=[settings.ALGORITHM]
        )
        user = payload.get("user")

        if user.get("role").lower() != "student":
            await websocket.close(code=1008)
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User should be student to access this websocket",
            )
        
        if not user:
            await websocket.close(code=1008)
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Could not validate credentials",
            )

        email = user.get("email")
        user_id = int(user.get("user_uid"))

    except (JWTError, ValueError, TypeError):
        await websocket.close(code=1008)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
        )

    current_user = await get_user(
        db,
        email=email,
        user_id=user_id
    )

    if not current_user:
        await websocket.close(code=1008)
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"User not found with id {user_id}"
        )

    return current_user


async def get_current_user(
        token: str = Depends(oauth2_scheme),
        db: Session =Depends(get_db)
)-> user_models.User:
    cred_exc = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        decrypt_token = fernet.decrypt(token.encode()).decode()
        payload = jwt.decode(decrypt_token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        
        user = payload.get("user")
        email = user.get("email")
        user_id = int(user.get('user_uid'))

        if not user:
            raise cred_exc
    except JWTError:
        raise cred_exc
    # user = db.query(user_models.User).filter(user_models.User.email == email,
    #                                          user_models.User.id==user_id).first()

    user = await get_user(db, email=email, user_id=user_id)
    if not user :
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"User not found with id {user_id}")
    
    if not user:
        raise cred_exc
    return user


def require_role(*roles:str):
    """
    Docstring for require_role
    
    :param roles: only owner and admin get acccess to some features
    :type roles: str
    Usege: Depends(require_role("admin", "owner"))
    """
    async def dependency(current_user: user_models.User = Depends(get_current_user)):
        # db = AsyncSessionLocal()
        # role = db.query(user_models.User.role).filter(user_models.User.id==current_user.id).first()
        # role = await get_user(db, current_user.id)
        logging.info(f"Trying to access the user {current_user} and role")

        # if role[0] not in roles:
        if current_user.role not in roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail='Insufficient Role'
            )
        return current_user
    return dependency


def get_current_token(token:str = Depends(oauth2_scheme)):
    return token

