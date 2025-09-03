from fastapi import FastAPI

app = FastAPI()


@app.get("/")
async def root():
    return {"message": "Hello World. It's me, auto_govern on FastAPI!"}