# Soothe Recommendations App
This is a Python FastAPI backend for a Gen AI application that provides home remedy recommendations for reducing stress, heart rate, and blood pressure.


## Running the Application
1. Start the FastAPI server:

    ```
    uvicorn src.main:app --reload
    ```

2. Open your web browser and go to http://127.0.0.1:8000

   You should see the welcome message: 
   ```
   {"message":"Welcome to the Soothe API"}
   ```

3. Explore the API documentation:

   FastAPI provides automatic interactive API documentation. You can access it at:

   - http://127.0.0.1:8000/docs (Swagger UI)

   - http://127.0.0.1:8000/redoc (ReDoc)

## API Endpoints
`GET /`: Welcome message.
`GET /recommendations`: Get all available recommendations.
`GET /recommendations/{category}`: Get recommendations for a specific category.

Available categories: stress, heart_rate, blood_pressure

**Example Usage**
- To get stress recommendations: http://127.0.0.1:8000/recommendations/stress
- To get heart rate recommendations: http://127.0.0.1:8000/recommendations/heart_rate
- To get blood pressure recommendations: http://127.0.0.1:8000/recommendations/blood_pressure
