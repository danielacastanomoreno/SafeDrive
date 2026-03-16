---
name: auth_pages_routes_di
description: Capa presentation completa del feature auth (páginas, rutas, DI) y archivos raíz main.dart e injection_container.dart entregados en la cuarta parte del feature auth (marzo 2026).
type: project
---

Cuarta y última parte del feature auth implementada el 2026-03-14.

## Archivos creados

### Páginas (lib/features/auth/presentation/pages/)
- splash_page.dart — StatefulWidget, dispara AuthCheckSessionRequested en initState, BlocListener redirige según estado
- role_selection_page.dart — dos RoleButtonWidget, sin back button, sin BLoC
- driver_login_page.dart — BlocConsumer, form con GlobalKey, Validators.email + notEmpty password
- company_login_page.dart — idéntico a driver pero dispara AuthCompanyLoginRequested, link a /company/register
- forgot_password_page.dart — _sent bool local, pantalla de éxito con setState, no navega automáticamente
- company_register_page.dart — 6 controllers, SingleChildScrollView, NitValidator.getError para NIT
- select_company_page.dart — PopScope(canPop: false), Radio<String>, obtiene companies de AuthCompanySelectionRequired
- driver_home_placeholder_page.dart — placeholder, BlocListener AuthLoggedOut → /role-selection
- company_home_placeholder_page.dart — placeholder empresa, mismo patrón logout

### Infraestructura
- lib/core/constants/app_routes.dart — GoRouter con 9 rutas, sin redirect con Firebase, sin guards en el router
- lib/injection_container.dart — SharedPreferences.getInstance() await, _initAuth() con datasource/repo/usecases LazySingleton + AuthBloc factory
- lib/main.dart — Firebase.initializeApp(), di.init(), AppBlocObserver, BlocProvider<AuthBloc> wrapping SafeDriveApp, MaterialApp.router

## Decisiones arquitectónicas clave

- El router NO usa `redirect` ni `refreshListenable` con Firebase. La lógica de redirección vive exclusivamente en SplashPage via BlocListener.
- AuthBloc es `registerFactory` en GetIt: instancia fresca en cada BlocProvider.
- UseCases son `registerLazySingleton`: reutilizados a lo largo del ciclo de vida del app.
- PopScope(canPop: false) en SelectCompanyPage fuerza la selección de empresa sin posibilidad de evadir.
- PasswordFieldWidget acepta `label` opcional (default 'Contraseña') — usado con label distinto en company_register_page.

## Rutas registradas
| Path | Page |
|------|------|
| / | SplashPage |
| /role-selection | RoleSelectionPage |
| /driver/login | DriverLoginPage |
| /company/login | CompanyLoginPage |
| /company/register | CompanyRegisterPage |
| /forgot-password | ForgotPasswordPage |
| /driver/select-company | SelectCompanyPage |
| /driver/home | DriverHomePlaceholderPage |
| /company/home | CompanyHomePlaceholderPage |

## HUs cubiertas
HU001 (login conductor), HU002 (login empresa), HU003 (registro empresa),
HU004 (recuperar contraseña), HU005 (selección empresa), HU006 (logout),
HU-E01, HU-E02, HU-E03, HU-E04 (flujos empresa completos).

**Why:** Completar el feature auth end-to-end para que el app sea ejecutable.
**How to apply:** En features futuros (trips, monitoring, company), las home placeholder pages serán reemplazadas. Las rutas /driver/home y /company/home se expandirán con sub-rutas o se migrarán a ShellRoute.
