from fastapi import FastAPI

from app.core.database import Base, engine

from app.api.auth import router as auth_router

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Import models so SQLAlchemy registers them
from app.models import User, Resume, ResumeAnalysis


from app.api.resumes import router as resumes_router
from app.api.analysis import router as analysis_router

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="AI Resume Analyzer API",
    version="1.0.0",
    swagger_ui_persist_authorization=True
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",
        "http://127.0.0.1:5173",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router)
app.include_router(resumes_router)
app.include_router(analysis_router)


@app.get("/")
def root():
    return {
        "message": "AI Resume Analyzer API"
    }


@app.get("/health")
def health():
    return {
        "status": "healthy"
    }