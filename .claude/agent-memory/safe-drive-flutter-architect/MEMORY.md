# Agent Memory Index — Safe Drive AI

| File | Type | Description |
|------|------|-------------|
| [project_setup.md](./project_setup.md) | project | Estado inicial: comando de creación, dependencias pinneadas, estructura de carpetas y archivos base entregados en la inicialización del proyecto (marzo 2026). |
| [auth_domain_layer.md](./auth_domain_layer.md) | project | Capa domain completa del feature auth: 3 entidades, repositorio abstracto (13 métodos), 9 UseCases, NitValidator (DIAN) y Validators. Ningún archivo importa Firebase ni Flutter. |
| [auth_data_layer.md](./auth_data_layer.md) | project | Capa data completa del feature auth: exceptions.dart, 3 models, datasource interface + impl (FirebaseAuth/Firestore/SharedPreferences), repository impl puro traductor Exception→Failure. |
| [auth_presentation_layer.md](./auth_presentation_layer.md) | project | Capa presentation del feature auth: AuthBloc (8 eventos, 9 estados, 8 handlers), 5 widgets reutilizables. Iteración-2 completada: _onCheckSession rehidrata sesión vía GetCurrentDriverUseCase / GetCurrentCompanyUseCase sin importar Firebase en el BLoC. SaveSessionUseCase pendiente. |
| [auth_pages_routes_di.md](./auth_pages_routes_di.md) | project | Páginas (9), app_routes.dart (GoRouter 9 rutas sin redirect Firebase), injection_container.dart y main.dart. Feature auth 100% completo. HUs cubiertas: HU001–HU006, HU-E01–HU-E04. |
| [project_gradle_config.md](./project_gradle_config.md) | project | pubspec.yaml con todas las dependencias pinneadas y verificadas. Android: compileSdk/targetSdk=34, minSdk=21, multidex, Google Services 4.4.2 en settings.gradle.kts. flutter pub get exitoso. |
| [company_feature.md](./company_feature.md) | project | Feature company/ 100% completo: 9 archivos domain, 4 data, 7 presentation. DI y rutas actualizadas. flutter analyze: 0 issues. |
| [driver_feature.md](./driver_feature.md) | project | Feature driver/ 100% completo: 6 domain, 3 data, 9 presentation. DI y rutas actualizadas. flutter analyze: 0 issues. |
| [driver_registration_flow.md](./driver_registration_flow.md) | project | Decisión de implementar registro independiente para conductores a través de DriverRegisterPage, en complemento a la creación de conductores hecha por empresas (Flujo 1 vs Flujo 2). |
