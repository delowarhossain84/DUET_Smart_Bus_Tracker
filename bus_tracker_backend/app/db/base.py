# Import all ORM models here so migrations can discover metadata.
from sqlalchemy.orm import sessionmaker, DeclarativeBase
# from app.db.session import SessionLocal
from app.core.database import AsyncSessionLocal

# Base = declarative_base()
class Base(DeclarativeBase):
    pass

# def get_db():
#     db = SessionLocal()
#     try:
#         yield db
#     finally:
#         db.close()

async def get_db():
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        