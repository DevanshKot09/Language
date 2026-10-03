from typing import Generator
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker, Session
from app.core.config import settings

# Configure database engine
connect_args = {}
engine_kwargs = {
    "pool_pre_ping": True,
}

if settings.DATABASE_URL.startswith("sqlite"):
    connect_args["check_same_thread"] = False
else:
    connect_args["keepalives"] = 1
    connect_args["keepalives_idle"] = 30
    connect_args["keepalives_interval"] = 10
    connect_args["keepalives_count"] = 5
    engine_kwargs["pool_recycle"] = 60
    engine_kwargs["pool_pre_ping"] = True
    engine_kwargs["pool_size"] = 5
    engine_kwargs["max_overflow"] = 10

engine = create_engine(
    settings.DATABASE_URL,
    connect_args=connect_args,
    **engine_kwargs,
)

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
)

Base = declarative_base()


def get_db() -> Generator[Session, None, None]:
    """FastAPI dependency for injecting transactional database sessions."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
