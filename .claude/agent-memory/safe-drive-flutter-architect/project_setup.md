---
name: project_setup
description: Estado inicial del proyecto Safe Drive AI — comandos de creación, dependencias pinneadas, estructura de carpetas y archivos base entregados.
type: project
---

Proyecto Safe Drive AI inicializado en marzo 2026.

**Why:** MVP Android para seguridad vial de conductores en Colombia. Firebase project: bombastik-e516e.

**How to apply:** Toda nueva HU asume esta base como punto de partida.

## Comando de creación
```
flutter create --org com.bombastik --project-name safe_drive_ai --platforms android safe_drive_ai
```
applicationId final: com.bombastik.safedrive

## Versiones de dependencias (marzo 2026)
- firebase_core: ^3.6.0
- firebase_auth: ^5.3.1
- cloud_firestore: ^5.4.4
- firebase_storage: ^12.3.2
- firebase_messaging: ^15.1.3
- flutter_bloc: ^8.1.6
- bloc: ^8.1.4
- equatable: ^2.0.5
- get_it: ^8.0.2
- injectable: ^2.4.4
- go_router: ^14.2.7
- dartz: ^0.10.1
- google_mlkit_face_detection: ^0.11.0
- shared_preferences: ^2.3.2
- camera: ^0.11.0+2
- permission_handler: ^11.3.1
- intl: ^0.19.0
- uuid: ^4.5.1
- logger: ^2.4.0
- injectable_generator: ^2.6.2 (dev)
- build_runner: ^2.4.12 (dev)
- bloc_test: ^9.1.7 (dev)
- mocktail: ^1.0.4 (dev)
- fake_cloud_firestore: ^3.0.3 (dev)
- firebase_auth_mocks: ^0.14.1 (dev)

## android/app/build.gradle
- namespace: com.bombastik.safedrive
- applicationId: com.bombastik.safedrive
- minSdk: 21
- multiDexEnabled: true
- firebase-bom: 33.5.1
- plugin: com.google.gms.google-services

## Archivos base entregados
- lib/main.dart — Firebase.initializeApp, AppBlocObserver, MaterialApp.router
- lib/injection_container.dart — GetIt con Firebase instances registradas
- lib/core/constants/app_router.dart — GoRouter con rutas base y guard global por auth
- lib/core/constants/app_colors.dart — Paleta azul institucional
- lib/core/constants/app_strings.dart — Todos los textos en español
- lib/core/errors/failures.dart — Jerarquía Failure con dartz/equatable
- lib/core/errors/exceptions.dart — Excepciones del data layer
- lib/core/usecases/usecase.dart — UseCase<Type,Params>, NoParams, StreamUseCase

## Rutas definidas (AppRoutes)
- / → splash
- /login → login
- /driver/home → driverHome
- /driver/trip → driverTrip (pendiente de implementar)
- /company/home → companyHome
- /company/drivers → companyDrivers (pendiente de implementar)

## Guard de navegación
- Usuario no autenticado → redirige a /login
- Resolución de rol (driver/company) ocurre en SplashPage leyendo Firestore
- SplashPage aún NO implementada (se crea en HU de auth)
