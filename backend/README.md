# Smart Study Planner Backend

A production-ready FastAPI backend for student task management, study scheduling, reminders, and progress tracking.

## Tech Stack

- FastAPI
- SQLite
- SQLAlchemy ORM
- Pydantic validation
- JWT authentication
- Passlib (bcrypt)

## Project Structure

backend/

- app/
  - main.py
  - database.py
  - core/
    - config.py
    - dependencies.py
  - models/
    - user.py
    - subject.py
    - task.py
    - study_plan.py
    - progress.py
  - schemas/
    - auth.py
    - subject.py
    - task.py
    - study_plan.py
    - progress.py
  - routes/
    - auth.py
    - subjects.py
    - tasks.py
    - study_plan.py
    - progress.py
  - services/
    - auth_service.py
    - task_service.py
    - planner_service.py
    - progress_service.py
  - utils/
    - security.py
- requirements.txt
- README.md

## Setup

1. Create and activate a virtual environment.
2. Install dependencies:

```bash
pip install -r requirements.txt
```

3. Create your environment file:

```bash
cp .env.example .env
```

4. Configure environment variables (recommended):

- JWT_SECRET_KEY
- JWT_ALGORITHM (default: HS256)
- ACCESS_TOKEN_EXPIRE_MINUTES (default: 60)
- DATABASE_URL (default: sqlite:///./study_planner.db)

5. Run the API:

```bash
uvicorn app.main:app --reload
```

## API Base URL

- http://127.0.0.1:8000
- OpenAPI docs: http://127.0.0.1:8000/docs

## Endpoints

### Auth

- POST /api/v1/auth/register
- POST /api/v1/auth/login
- GET /api/v1/auth/me

### Subjects

- POST /api/v1/subjects
- GET /api/v1/subjects
- DELETE /api/v1/subjects/{id}

### Tasks

- POST /api/v1/tasks
- GET /api/v1/tasks
  - Supports pagination: page, page_size
  - Filters: subject_id, status
  - Search: search
  - Sorted by priority (High > Medium > Low), then nearest deadline
- PUT /api/v1/tasks/{id}
- DELETE /api/v1/tasks/{id}
  - Soft delete
- PATCH /api/v1/tasks/{id}/complete
- GET /api/v1/tasks/reminders
  - Returns tasks due today and in the next 2 hours

### Study Planner

- POST /api/v1/study-plan
- GET /api/v1/study-plan
- DELETE /api/v1/study-plan/{id}

### Progress Tracker

- GET /api/v1/progress
  - completed_tasks
  - total_tasks
  - completion_percentage
  - study_hours

## Security Notes

- Passwords are hashed with bcrypt.
- The backend loads environment variables from `.env` automatically.
- JWT token expiry is enabled.
- Protected routes use dependency injection with token validation.
- CORS is enabled for local browser-based Flutter development, so login/register preflight requests succeed.

## CORS Notes

If you run the Flutter frontend in a browser or web preview, the browser sends an `OPTIONS` preflight request before `POST /auth/login` and `POST /auth/register`.
That request must be accepted by FastAPI with CORS middleware, otherwise you will see `405 Method Not Allowed` for `OPTIONS`.

## Integration Notes for Flutter

- Store JWT access token securely on device.
- Attach `Authorization: Bearer <token>` to protected requests.
- Use `/api/v1/tasks` pagination and filtering to keep list views responsive.
