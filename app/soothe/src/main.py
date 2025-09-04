import os

from fastapi import FastAPI
from fastapi.responses import HTMLResponse
from fastapi.middleware.cors import CORSMiddleware
from .utils.recommendations import recommendations
from .utils import gemini
from .model.dataclasses import HealthData
from .model.auth import Token

app = FastAPI()

# Configure CORS
origins = [
    "http://localhost",
    "http://localhost:8000",
    "http://127.0.0.1",
    "http://127.0.0.1:8000",
]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  # Allows all headers
)


# Define the HTML content for the root page
html_content = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome to Soothe</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Nunito:wght@400;700&display=swap');
        body{display:flex;justify-content:center;align-items:center;height:100vh;margin:0;background-color:#f7f9fc;font-family:'Nunito',sans-serif;color:#333}
        .container{text-align:center;background-color:white;padding:40px 60px;border-radius:16px;box-shadow:0 8px 32px rgba(0,0,0,.1)}
    </style>
</head>
<body>
    <div class="container">
        <h1>Welcome to Soothe</h1>
        <p>Your personal guide to calm and relaxation.</p>
        
        <div id="g_id_onload"
             data-client_id="191080541971-uqhed30000nbpmg2en26k1960sg882b7.apps.googleusercontent.com"
             data-context="signin"
             data-ux_mode="popup"
             data-callback="handleCredentialResponse"
             data-nonce="">
        </div>

        <div class="g_id_signin"
             data-type="standard"
             data-shape="rectangular"
             data-theme="outline"
             data-text="signin_with"
             data-size="large"
             data-logo_alignment="left">
        </div>
    </div>

    <script src="https://accounts.google.com/gsi/client" async></script>

    <script>
        function handleCredentialResponse(response) {
            // The user's ID token is in response.credential
            console.log("Encoded JWT ID token: " + response.credential);
            
            // Send this credential to your backend
            fetch('/auth/google', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                // The new token is in the 'credential' field
                body: JSON.stringify({ token: response.credential }), 
            })
            .then(res => res.json())
            .then(data => {
                console.log('Backend response:', data);
            })
            .catch(error => {
                console.error('Error sending token to backend:', error);
            });
        }
    </script>
</body>
</html>
"""

# Create the new endpoint to receive the token from the frontend
@app.post("/auth/google")
async def google_auth(token: Token):
    # Here is where you would verify the token with Google's libraries
    # For now, we'll just pretend it's valid and return a success message.
    # In a real app, you'd use a library like `google-auth` to verify
    # the token.id_token and get the user's info.
    print(f"Received token: {token.token[:30]}...") # Print first 30 chars for security

    # Placeholder for user info you would get from a real token
    user_email = "user@example.com" 
    
    return {"message": "Login successful!", "email": user_email}

@app.get("/", response_class=HTMLResponse)
def read_root():
    return html_content

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
