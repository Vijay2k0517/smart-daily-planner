# Smart Study Planner (Flutter + FastAPI)

This repository now contains a connected full-stack app:

- Flutter mobile frontend in `lib/`
- FastAPI backend in `backend/`

## Updated Folder Structure

```text
lib/
	core/
		app_constants.dart
		network/
			api_config.dart
			api_client.dart
	data/
		models/
			progress_summary.dart
			subject_item.dart
	models/
	screens/
	services/
		backend_api_service.dart
		session_service.dart
	state/
		app_state.dart
	theme/
	widgets/
	main.dart

backend/
	app/
		core/
		models/
		routes/
		schemas/
		services/
		utils/
		database.py
		main.py
	requirements.txt
	README.md
```

## How Frontend and Backend Are Connected

- Auth (`/api/v1/auth/*`) is used from Flutter login/signup.
- Subjects, tasks, study plans, reminders, and progress all load from FastAPI.
- JWT token is stored locally and attached as `Authorization: Bearer <token>`.
- Flutter state is synchronized through `app_state.dart`.

## Run Backend

```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload
```

API docs: `http://127.0.0.1:8000/docs`

## Run Frontend

```bash
flutter pub get
flutter run
```

## Base URL Notes

`lib/core/network/api_config.dart` is preconfigured for:

- Android emulator: `http://10.0.2.2:8000/api/v1`
- iOS/Desktop: `http://127.0.0.1:8000/api/v1`
- Web: `http://localhost:8000/api/v1`

If testing on a physical device, replace with your machine LAN IP.
