from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .utils.recommendations import recommendations
from .utils import gemini
from .model.dataclasses import HealthData

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

@app.post("/recommendations/gemini")
async def get_gemini_recommendations(health_data: HealthData):
    """
    Get all available recommendations from the Gemini API.
    """
    prompt = f"""
        Analyze the following health data:
        - Heart Rate: {health_data.heart_rate} bpm
        - Blood Pressure: {health_data.blood_pressure}

        Based on this data, provide 3-4 simple, safe, and actionable home remedies or wellness tips to help promote relaxation and well-being.

        IMPORTANT:
        - Your response must start with a disclaimer: "Disclaimer: I am an AI assistant and not a medical professional. These are general wellness tips, not medical advice. Please consult a healthcare provider for any health concerns."
        - Do not provide any medical diagnoses or professional medical advice.
        - Focus on gentle, universally safe activities like breathing exercises, mindfulness, hydration, or simple stretches.
        - Format the response in clear, easy-to-read markdown with bullet points for the recommendations.
        """
    response = await gemini.get_response(prompt)
    return response
