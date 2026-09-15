# src/api/hashing.py
from passlib.context import CryptContext

pwd_cxt = CryptContext(
    schemes=["bcrypt_sha256", "bcrypt"],  # bcrypt kept for backward-compat
    deprecated="auto"
)

class Hash:
    @staticmethod
    def hash(password: str) -> str:
        # Will produce a bcrypt_sha256 hash for new passwords
        return pwd_cxt.hash(password)

    @staticmethod
    def verify(hashed_password: str, plain_password: str) -> bool:
        # Verifies bcrypt_sha256 OR legacy bcrypt transparently
        return pwd_cxt.verify(plain_password, hashed_password)
