---
name: driver_feature
description: Feature driver/ 100% completo — domain, data, presentation. DI y rutas actualizadas. flutter analyze: 0 issues.
type: project
---

Feature `lib/features/driver/` implementado y verificado con `flutter analyze` (0 issues).

**Why:** Feature core del conductor: gestionar empresas vinculadas, aceptar/rechazar invitaciones y editar perfil propio.

**How to apply:** Al extender funcionalidad del conductor (viajes, monitoreo), respetar la estructura ya establecida aquí y reutilizar el DriverBloc existente.

## Archivos domain (6)
- `domain/repositories/driver_repository.dart` — 5 métodos abstractos
- `domain/usecases/get_driver_invitations_usecase.dart` + `GetDriverInvitationsParams`
- `domain/usecases/accept_invitation_usecase.dart` + `AcceptInvitationParams`
- `domain/usecases/reject_invitation_usecase.dart` + `RejectInvitationParams`
- `domain/usecases/get_driver_linked_companies_usecase.dart` + `GetDriverLinkedCompaniesParams`
- `domain/usecases/update_driver_profile_usecase.dart` + `UpdateDriverProfileParams`

## Archivos data (3)
- `data/datasources/driver_datasource.dart` — interfaz abstracta
- `data/datasources/driver_datasource_impl.dart` — impl Firestore con fallback sin orderBy para índices faltantes
- `data/repositories/driver_repository_impl.dart` — puro traductor Exception → Failure

## Archivos presentation (9)
- `presentation/bloc/driver_event.dart` — 6 eventos
- `presentation/bloc/driver_state.dart` — 6 estados
- `presentation/bloc/driver_bloc.dart` — 6 handlers
- `presentation/widgets/company_link_card_widget.dart`
- `presentation/widgets/driver_invitation_card_widget.dart`
- `presentation/pages/driver_companies_page.dart`
- `presentation/pages/driver_invitations_page.dart`
- `presentation/pages/driver_profile_page.dart`
- `presentation/pages/driver_home_page.dart` — provee DriverBloc, 3 tabs, BlocListener AuthBloc

## Decisiones arquitectónicas
- `DriverBloc` se instancia directamente en `DriverHomePage` con `BlocProvider` (no via DI factory) para tener acceso al `sl<>` de usecases ya registrados como LazySingleton.
- `DriverProfileRequested` emite `DriverInitial` porque no hay usecase de solo lectura de perfil — la página lee el perfil inicial desde `AuthBloc` (parámetro `driver`).
- `acceptInvitation` usa `batch.commit()` para atomicidad: actualiza `invitations` + crea doc en `company_drivers` en una sola escritura.
- `getDriverInvitations` tiene fallback: intenta `orderBy sentAt desc`; si Firestore lanza FAILED_PRECONDITION (índice ausente), hace query sin orderBy y ordena en Dart.

## Archivos modificados
- `lib/injection_container.dart` — agrega `_initDriver()` con LazySingletons de datasource, repository y 5 usecases
- `lib/core/constants/app_routes.dart` — ruta `/driver/home` usa `DriverHomePage` con `extra` como `AuthDriverAuthenticated`
- `lib/features/auth/presentation/pages/splash_page.dart` — pasa `extra: state` al navegar a `/driver/home`
- `lib/features/auth/presentation/pages/driver_login_page.dart` — pasa `extra: state` al navegar a `/driver/home`

## InvitationModel
No se creó de nuevo — se importa desde `features/company/data/models/invitation_model.dart`.
