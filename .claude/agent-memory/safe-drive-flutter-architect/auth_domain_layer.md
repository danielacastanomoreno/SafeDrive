---
name: auth_domain_layer
description: Archivos de dominio y utils del feature auth implementados — entidades, repositorio abstracto, 9 UseCases, NitValidator y Validators
type: project
---

Capa domain del feature auth implementada completamente (marzo 2026).

**Why:** Base arquitectural necesaria antes de implementar la capa data, BLoC y páginas de autenticación.

**How to apply:** Al implementar la capa data, modelos, BLoC o páginas de auth, estos contratos son los que se deben respetar. No modificar entidades ni el repositorio abstracto sin actualizar todos sus dependientes.

## Archivos creados

### core (copiados de reference y validados)
- `lib/core/errors/failures.dart` — todas las Failure classes del proyecto
- `lib/core/usecases/usecase.dart` — UseCase, NoParams, StreamUseCase
- `lib/core/utils/nit_validator.dart` — algoritmo DIAN; pesos [71,67,59,53,47,43,41,37,29]; DV = (residuo>=2) ? 11-residuo : residuo
- `lib/core/utils/validators.dart` — email, password, name, cedula, phone, nit (usa NitValidator)

### Entidades (domain — sin imports Firebase/Flutter)
- `lib/features/auth/domain/entities/user_entity.dart`
  - Campos: id, name, cedula, email, role (UserRole), createdAt
  - Enum `UserRole { driver, company }` definido aquí
- `lib/features/auth/domain/entities/company_entity.dart`
  - Campos: id, name, nit, email, representativeName, role (UserRole), createdAt
  - Importa user_entity.dart para reusar UserRole
- `lib/features/auth/domain/entities/company_link_entity.dart`
  - Campos: id, companyId, companyName, driverId, cargo, phone, status (LinkStatus), linkedAt, unlinkedAt (nullable)
  - Enum `LinkStatus { active, inactive }` definido aquí

### Repositorio abstracto
- `lib/features/auth/domain/repositories/auth_repository.dart`
  - 13 métodos: loginDriver, loginCompany, registerCompany, logout, sendPasswordReset, getCurrentDriver, getCurrentCompany, getDriverCompanies, setActiveCompany, getActiveCompanyId, getSavedRole, saveSession, clearSession

### UseCases (heredan de UseCase<T, Params>)
- `login_driver_usecase.dart` — Params: email, password → UserEntity
- `login_company_usecase.dart` — Params: email, password → CompanyEntity
- `register_company_usecase.dart` — Params: name, nit, email, password, representativeName → CompanyEntity
- `logout_usecase.dart` — NoParams → void
- `send_password_reset_usecase.dart` — Params: email → void
- `get_driver_companies_usecase.dart` — Params: driverId → List<CompanyLinkEntity>
- `set_active_company_usecase.dart` — Params: companyId → void
- `get_active_company_usecase.dart` — NoParams → String?
- `check_session_usecase.dart` — NoParams → String? ('driver'|'company'|null)

## Decisiones arquitecturales confirmadas
- `UserRole` vive en `user_entity.dart` y es importado por `company_entity.dart`
- `LinkStatus` vive en `company_link_entity.dart`
- Ningún archivo de domain/utils tiene imports de Firebase o Flutter
- Dependencias externas en domain: solo `dartz` y `equatable`
- El proyecto Flutter en `safe_drive_ai/` fue creado manualmente (flutter SDK no disponible en el shell del agente; debe ejecutarse desde PowerShell del usuario)
