
from fastapi import FastAPI
from routes.user_routes import router as user_router

app = FastAPI()

# Include routes
app.include_router(user_router)

@app.get("/")
def root():
    return {"message": "Welcome to SmartLife API!"}
