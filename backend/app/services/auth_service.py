from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.progress import Progress
from app.models.user import User
from app.schemas.auth import UserLogin, UserRegister
from app.utils.security import create_access_token, hash_password, verify_password


def register_user(db: Session, payload: UserRegister) -> User:
    existing_user = db.scalar(select(User).where(User.email == payload.email))
    if existing_user:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email already registered")

    user = User(
        name=payload.name,
        email=payload.email,
        password=hash_password(payload.password),
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    progress = Progress(user_id=user.id)
    db.add(progress)
    db.commit()

    return user


def login_user(db: Session, payload: UserLogin) -> str:
    user = db.scalar(select(User).where(User.email == payload.email))
    if not user or not verify_password(payload.password, user.password):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
    return create_access_token(str(user.id))
