---
name: auth_data_layer
description: Capa data completa del feature auth: exceptions, 3 models, datasource interface + impl, repository impl. Decisiones de diseño y rutas de archivos.
type: project
---

Capa data del feature auth implementada en marzo 2026. Todos los archivos compilables, sin TODOs.

**Why:** Separa la responsabilidad de comunicación con Firebase/SharedPreferences de la lógica de dominio. El repository impl es puro traductor Exception → Failure.

**How to apply:** Al implementar features futuros (trips, monitoring, company) seguir exactamente la misma estructura y convenciones establecidas aquí.

## Archivos creados

- `lib/core/errors/exceptions.dart` — 12 exception classes (AuthException, InvalidCredentialsException, UserNotFoundException, EmailAlreadyInUseException, WeakPasswordException, NotAuthenticatedException, ServerException, NetworkException, FirestoreException, DocumentNotFoundException, PermissionDeniedException, CacheException). Todas con `final String message` donde aplica.

- `lib/features/auth/data/models/user_model.dart` — extiende UserEntity. `fromMap(String id, Map<String, dynamic>)`: Timestamp→DateTime, String→UserRole enum. `toMap()`: usa FieldValue.serverTimestamp() para createdAt.

- `lib/features/auth/data/models/company_model.dart` — extiende CompanyEntity. Misma lógica fromMap/toMap. Importa UserRole desde domain/entities/user_entity.dart.

- `lib/features/auth/data/models/company_link_model.dart` — extiende CompanyLinkEntity. `fromMap(String id, Map<String, dynamic>, String companyName)`: companyName como parámetro separado (Firestore no hace joins). String→LinkStatus enum.

- `lib/features/auth/data/datasources/auth_remote_datasource.dart` — interface abstracta. Retorna Models (no Entities). Lanza Exceptions (no Failures). 13 métodos espejando el AuthRepository.

- `lib/features/auth/data/datasources/auth_remote_datasource_impl.dart` — implementación con FirebaseAuth, FirebaseFirestore, SharedPreferences. Constructor const con named parameters requeridos. SharedPreferences keys: 'user_id', 'user_role', 'active_company_id'. loginDriver/loginCompany verifican role en Firestore y llaman signOut antes de lanzar AuthException si role no coincide. registerCompany hace query NIT antes de createUserWithEmailAndPassword. getDriverCompanies itera docs y hace fetch individual de companies/{companyId} para nombre.

- `lib/features/auth/data/repositories/auth_repository_impl.dart` — implementa AuthRepository de domain. Cero lógica de negocio. Mapeo FirebaseAuthException por código: 'user-not-found'/'wrong-password'/'invalid-credential'→InvalidCredentialsFailure, 'email-already-in-use'→EmailAlreadyInUseFailure, 'weak-password'→WeakPasswordFailure, 'network-request-failed'→NetworkFailure, default→AuthFailure(message). AuthException→AuthFailure(message). Exception→ServerFailure(message). Métodos de cache usan CacheFailure.

## Convenciones establecidas

- `fromMap` siempre recibe `String id` como primer parámetro separado (no viene en el map de Firestore).
- `toMap()` sin parámetros; usa FieldValue.serverTimestamp() para timestamps de creación.
- El datasource impl recibe dependencias via constructor const (listo para GetIt/injectable).
- `getDriverCompanies` hace N+1 queries (una por empresa). Aceptable en MVP; documentar para optimizar con batch reads en versión futura.
