import httpx
import os
import logging
from dotenv import load_dotenv
from fastapi import HTTPException

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Set up client environment
load_dotenv()
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if not GEMINI_API_KEY:
    raise HTTPException(status_code=500, detail="Gemini API key not configured on the server.")
GEMINI_API_URL = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent?key={GEMINI_API_KEY}"

async def get_response(prompt: str):
    """
    Get a response from the Gemini API.
    """
    payload = {
        "contents": [{"parts": [{"text": prompt}]}]
    }
    failure_response = {"response": "Could not generate a response at this time."}
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(GEMINI_API_URL, json=payload, timeout=30.0)
            response.raise_for_status()
            result = response.json()
            logger.info(f"Gemini API response: {result}")  # too verbose - disable

            # Safely access the generated text
            if "candidates" in result and result["candidates"]:
                candidate = result["candidates"][0]
                if "content" in candidate and "parts" in candidate["content"] and candidate["content"]["parts"]:
                    text = candidate["content"]["parts"][0].get("text", "No content generated.")
                    return {"response": text}

            return failure_response

    except httpx.RequestError as e:
        logger.error(HTTPException(status_code=503, detail=f"Error communicating with the Gemini API: {e}"))
        return failure_response
    except Exception as e:
        logger.error(HTTPException(status_code=500, detail=f"An unexpected error occurred: {e}"))
        return failure_response
