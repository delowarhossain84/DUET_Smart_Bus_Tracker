# from fastapi import WebSocket

# from app.models.user import User
# # from app.realtime.student_store import student_store
# from app.utils.student_store import student_store
# from app.websocket.manager import websocket_manager

# # from app.websocket.manager import WebSocket
# from app.services.realtime_service import realtime_service
# from app.schemas.student import (
#     SubscribeBusSchema,
#     StudentLocationUpdateSchema,
#     PingSchema,
# )

# class StudentService:
#     async def connect(
#             self, 
#             websocket:WebSocket,
#             student:User
#     )-> None:
#         await websocket_manager.connect(websocket)
#         await student_store.add(
#             websocket=websocket,
#             student_id=student.id,
#         )
#         await websocket_manager.send_json(
#             websocket,
#             {
#                 "event": "connected",
#                 "student_id": student.id
#             }
#         )
#     async def disconnect(
#             self,
#             websocket:WebSocket
#     )->None:
#         await student_store.remove(websocket)

#         await websocket_manager.disconnect(websocket)
#     async def handle_message(
#             self,
#             websocket:WebSocket,
#             student:User,
#             payload,
#     ) -> None:

#         # subcribe bus
#         if isinstance(payload, SubscribeBusSchema):
#             await student_store.subscribe_bus(
#                 websocket=websocket,
#                 bus_id=payload.bus_id,
#             )

#             await websocket_manager.send_json(
#                 websocket,
#                 {
#                     "event": "subscribed",
#                     "bus_id": payload.bus_id,
#                 },
#             )

#             await realtime_service.student_location_updated(
#                 websocket=websocket
#             )

#             return
#         if isinstance(payload, StudentLocationUpdateSchema):
#             await student_store.update_location(
#                 websocket=websocket,
#                 latitude=payload.latitude,
#                 longitude=payload.longitude,
#             )
#             await realtime_service.student_location_updated(
#                 websocket=websocket
#             )
#             return
#         if isinstance(payload, PingSchema):

#             await websocket_manager.send_json(
#                 websocket,
#                 {
#                     "event": "pong"
#                 },
#             )

#             return
        
#         # Unknown event
#         await websocket_manager.send_json(
#             websocket,
#             {
#                 "event": "error",
#                 "message": "Unknown event"
#             },
#         )

# student_service = StudentService()