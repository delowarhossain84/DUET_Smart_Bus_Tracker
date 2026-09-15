from datetime import datetime, timedelta, timezone
from jose import JWTError, jwt
# from . import schemas
from app.schemas.security import TokenData
from app.core.config import settings

from cryptography.fernet import Fernet



ACCESS_TOKEN_EXPIRE_MINUTES = 30
fernet = Fernet(settings.ENCRYPTION_KEY)

def create_access_token(data: dict, expiry:timedelta=None, refresh:bool = False):
    expire = datetime.now(timezone.utc) + (
        expiry if expiry is not None else timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    payload = {}
    payload['user'] = data
    payload['exp'] = expire
    # payload['jti'] = str(uuid.uuid4())
    payload['refresh'] = refresh
    token = jwt.encode(
        payload, key=settings.SECRET_KEY, algorithm=settings.ALGORITHM
    )
    
    # encrypt the toke
    encrypt_token = fernet.encrypt(token.encode()).decode()
    return encrypt_token, expire

    # to_encode = data.copy()
    
    # expire = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    # to_encode.update({"exp": expire})
    # encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    # return encoded_jwt

def verify_token(token:str, credentials_exception):
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
        token_data = TokenData(email=email)
        return token_data
    
    except JWTError:
        raise credentials_exception

# REFRESH_TOKEN_EXPIRE_DAYS = 7
# def create_refresh_token(data:dict):
#     to_encode = data.copy()
#     expire = datetime.now(timezone.utc) + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)

#     to_encode.update({'exp': expire})
#     encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

#     return encoded_jwt, expire