from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .utils.recommendations import recommendations

app = FastAPI()

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  # Allows all headers
)

@app.get("/")
def read_root():
    return {"message": "Welcome to the Soothe API"}

@app.get("/recommendations/{category}")
def get_recommendations(category: str):
    """
    Get recommendations for a specific category.
    Categories can be: 'stress', 'heart_rate', 'blood_pressure'
    """
    return recommendations.get(category, {"error": "Category not found"})

@app.get("/recommendations")
def get_all_recommendations():
    """
    Get all available recommendations.
    """
    return recommendations
