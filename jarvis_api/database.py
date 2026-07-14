"""Database connection and ORM setup"""
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import declarative_base, sessionmaker
from sqlalchemy import text
import structlog

from jarvis_api.config import Settings

logger = structlog.get_logger(__name__)

settings = Settings()

# Async database engine
engine = create_async_engine(
    settings.database_url,
    echo=settings.db_echo,
    pool_pre_ping=True,
    pool_size=20,
    max_overflow=0,
)

# Async session factory
AsyncSessionLocal = sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)

# Base class for all models
Base = declarative_base()

async def init_db():
    """Initialize database connection and run migrations"""
    try:
        async with engine.begin() as conn:
            # Test connection
            await conn.execute(text("SELECT 1"))
        logger.info("database_initialized", status="connected")
    except Exception as exc:
        logger.error("database_initialization_failed", error=str(exc))
        raise

async def get_db():
    """Dependency for FastAPI to provide database sessions"""
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()
