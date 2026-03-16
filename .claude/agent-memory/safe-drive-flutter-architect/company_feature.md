---
name: company_feature
description: Feature company/ completamente implementado incluyendo HU-E05 (registro conductor nuevo). flutter analyze limpio en código propio.
type: project
---

Feature `lib/features/company/` implementado desde 2026-03-14. HU-E05 completada 2026-03-15. flutter analyze: 0 issues propios (4 pre-existentes en nit_validator y forgot_password_page que no pertenecen a este feature).

**Why:** La empresa necesita gestionar conductores vinculados, invitar conductores existentes, registrar conductores nuevos y actualizar su perfil desde la app.

**How to apply:** No reimplementar ninguno de estos archivos. Si se necesita extender, modificar los usecases o el datasource existente.

## Archivos creados

### Domain
- `domain/entities/invitation_entity.dart` — enum InvitationStatus (pending/accepted/rejected/cancelled), InvitationEntity con Equatable
- `domain/repositories/company_repository.dart` — 7 métodos abstractos
- `domain/usecases/get_company_drivers_usecase.dart` — GetCompanyDriversParams(companyId)
- `domain/usecases/get_driver_profile_usecase.dart` — GetDriverProfileParams(driverId)
- `domain/usecases/unlink_driver_usecase.dart` — UnlinkDriverParams(linkId)
- `domain/usecases/send_invitation_usecase.dart` — SendInvitationParams(companyId, companyName, driverCedula, cargo, phone)
- `domain/usecases/get_company_invitations_usecase.dart` — GetCompanyInvitationsParams(companyId)
- `domain/usecases/cancel_invitation_usecase.dart` — CancelInvitationParams(invitationId)
- `domain/usecases/update_company_profile_usecase.dart` — UpdateCompanyProfileParams(companyId, name, representativeName)
- `domain/usecases/register_driver_by_company_usecase.dart` — RegisterDriverByCompanyParams(companyId, name, cedula, email, phone, cargo)

### Data
- `data/models/invitation_model.dart` — extiende InvitationEntity, fromMap/toMap con Timestamp
- `data/datasources/company_datasource.dart` — interfaz abstracta
- `data/datasources/company_datasource_impl.dart` — Ahora recibe FirebaseAuth en constructor. Agrega registerDriverByCompany: (1) query cedula en users → CedulaAlreadyRegisteredException, (2) Firebase.initializeApp con nombre único 'secondary_${timestamp}' → createUserWithEmailAndPassword → captura email-already-in-use → EmailAlreadyRegisteredException, (3) set doc users, (4) add doc company_drivers status=active, (5) _auth.sendPasswordResetEmail con auth primario, (6) secondaryApp.delete() en finally.
- `data/repositories/company_repository_impl.dart` — traduce exceptions a Failures

### Exceptions agregadas a core/errors/exceptions.dart
- DriverNotFoundException
- InvitationAlreadyExistsException
- DriverAlreadyLinkedException
- CedulaAlreadyRegisteredException (HU-E05)
- EmailAlreadyRegisteredException (HU-E05)

### Failures agregados a core/errors/failures.dart
- CedulaAlreadyRegisteredFailure (HU-E05)
- EmailAlreadyRegisteredFailure (HU-E05)

### Presentation
- `presentation/bloc/company_event.dart` — 8 eventos con Equatable (incluye CompanyDriverRegisterRequested: companyId, companyName, name, cedula, email, phone, cargo)
- `presentation/bloc/company_state.dart` — 7 estados (Initial, Loading, DriversLoaded, InvitationsLoaded, ProfileLoaded, ActionSuccess, Error)
- `presentation/bloc/company_bloc.dart` — 8 handlers; en unlink/send/cancel/register recarga la lista automáticamente tras el éxito
- `presentation/widgets/stat_card_widget.dart` — tarjeta de estadística con icon, value, label, color
- `presentation/widgets/driver_card_widget.dart` — muestra nombre, cedula, cargo, teléfono, estado; AlertDialog de confirmación antes de desvincular
- `presentation/widgets/invitation_card_widget.dart` — chip de color según status (pending=warning, accepted=success, rejected/cancelled=error); botón cancelar si pending con confirmación
- `presentation/pages/company_drivers_page.dart` — StatefulWidget, initState dispara CompanyDriversRequested, pull-to-refresh, estado vacío, estado error con botón Reintentar
- `presentation/pages/company_invitations_page.dart` — formulario colapsable (cedula, cargo, teléfono con validaciones), lista de invitaciones, pull-to-refresh
- `presentation/pages/company_profile_page.dart` — header con avatar iniciales, datos editables (name, representativeName), datos read-only (email, nit), botón Cerrar sesion → AuthLogoutRequested al AuthBloc provisto en main
- `presentation/pages/company_home_page.dart` — StatefulWidget con BlocProvider<CompanyBloc>, BottomNavigationBar 3 tabs con IndexedStack. FAB en tab 0 es FloatingActionButton.extended que abre showModalBottomSheet con dos ListTile: "Registrar conductor nuevo" (push /company/register-driver) y "Invitar conductor existente" (setState tab=1). Usa Builder para que context tenga acceso al CompanyBloc provisto por BlocProvider.
- `presentation/pages/register_driver_page.dart` — StatefulWidget con Form, 5 campos (nombre, cédula, email, teléfono, cargo), autovalidateMode.onUserInteraction, validador cargo inline, BlocListener para ActionSuccess→pop + Error→SnackBar, botón deshabilitado mientras CompanyLoading.

## Archivos modificados

- `core/errors/exceptions.dart` — agregadas 3 excepciones nuevas (sin romper las existentes)
- `injection_container.dart` — _initCompany() registra datasource con firebaseAuth:sl() (LazySingleton), repository (LazySingleton), 8 usecases (LazySingleton), CompanyBloc (factory) con registerDriverByCompanyUseCase:sl()
- `core/constants/app_routes.dart` — ruta `/company/home` usa CompanyHomePage; ruta `/company/register-driver` usa RegisterDriverPage con extra Map<String,String> {companyId, companyName}
- `features/auth/presentation/pages/splash_page.dart` — navega con extra: state.company
- `features/auth/presentation/pages/company_login_page.dart` — navega con extra: state.company
- `features/auth/presentation/pages/company_register_page.dart` — navega con extra: state.company

## Decisiones arquitectónicas

- CompanyHomePage provee el BlocProvider<CompanyBloc> — los 3 tabs hijos lo consumen con context.read/BlocConsumer
- AuthBloc (provisto en main.dart) se sigue usando en company_profile_page para el logout; accedido con context.read<AuthBloc>()
- El perfil de conductor en DriverCardWidget usa el driverId como fallback visual ya que CompanyLinkEntity no contiene nombre ni cédula — estos se rellenarán cuando se implemente un join o enriquecimiento adicional en fases futuras
- CompanyBloc no tiene un GetCurrentCompany propio — el perfil se provee como parámetro en la navegación desde el AuthBloc
- sendInvitation en datasource valida: (1) conductor existe por cédula, (2) no hay invitación pending duplicada, (3) no está ya vinculado activo
- registerDriverByCompany usa instancia secundaria de Firebase (Firebase.initializeApp con nombre único) para no cerrar sesión de empresa. sendPasswordResetEmail usa el auth PRIMARIO (_auth). La instancia secundaria se elimina siempre en finally.
- CompanyDatasourceImpl ahora requiere FirebaseAuth en constructor (necesario para sendPasswordResetEmail con auth principal).
- HUs cubiertas por company feature: HU-E05 (registrar conductor nuevo), más las anteriores de gestión de conductores e invitaciones.
