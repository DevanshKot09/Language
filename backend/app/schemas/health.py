from pydantic import BaseModel

class HealthResponse(BaseModel):
    status: str
    service: str
    boundary: str
    version: str
    environment: str
