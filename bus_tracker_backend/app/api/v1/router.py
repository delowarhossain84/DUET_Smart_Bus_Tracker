from fastapi import APIRouter
from app.api.v1.endpoints import authentication, user, student, driver, admin, websocket


api_router = APIRouter()
api_router.include_router(user.router)
api_router.include_router(authentication.router)
api_router.include_router(student.router)
api_router.include_router(driver.router)
api_router.include_router(admin.router)
api_router.include_router(websocket.router)

