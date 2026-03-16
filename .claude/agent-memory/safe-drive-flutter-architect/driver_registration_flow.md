---
name: driver_registration_flow
description: Decision to add an independent driver registration flow (DriverRegisterPage) in addition to the company-driven registration flow.
type: project
---

Se implementó el flujo de registro independiente para conductores a través de `RegisterDriverUseCase` y `DriverRegisterPage`. 
**Why:** Anteriormente, solo la empresa podía crear cuentas de conductores ("Flujo 1"). El "Flujo 2" requería que el conductor se registrara por su cuenta y luego la empresa lo invitara mediante la cédula.
**How to apply:** Al hablar sobre la creación de cuentas de conductor, recuerda que existen dos vías: 1) `RegisterDriverByCompanyUseCase` (la empresa lo crea y asocia inmediatamente) y 2) `RegisterDriverUseCase` (el conductor se crea su cuenta, empieza con 0 empresas vinculadas, y espera una invitación). Se agregaron las fallas `CedulaAlreadyRegisteredFailure` y `EmailAlreadyRegisteredFailure` para manejar colisiones entre estos flujos.
