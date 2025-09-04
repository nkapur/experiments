from pydantic import BaseModel

class HealthData(BaseModel):
    stress: float
    heart_rate: int
    blood_pressure: str  # e.g., "120/80"