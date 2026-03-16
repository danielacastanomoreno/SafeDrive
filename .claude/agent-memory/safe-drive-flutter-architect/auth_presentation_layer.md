---
name: auth_presentation_layer
description: Capa presentation del feature auth: AppColors, AuthBloc (eventos, estados, handlers), y 5 widgets reutilizables. Decisiones de diseño y TODOs pendientes documentados.
type: project
---

## Archivos creados (marzo 2026)

### Constants (nuevo directorio)
- `lib/core/constants/app_colors.dart` — abstract final class con 18 colores estáticos.

### BLoC
- `lib/features/auth/presentation/bloc/auth_event.dart`
- `lib/features/auth/presentation/bloc/auth_state.dart`
- `lib/features/auth/presentation/bloc/auth_bloc.dart`

### Widgets
- `lib/features/auth/presentation/widgets/role_button_widget.dart`
- `lib/features/auth/presentation/widgets/auth_text_field_widget.dart`
- `lib/features/auth/presentation/widgets/password_field_widget.dart`
- `lib/features/auth/presentation/widgets/primary_button_widget.dart`
- `lib/features/auth/presentation/widgets/auth_error_widget.dart`

## Eventos definidos
- `AuthCheckSessionRequested` — al abrir la app
- `AuthDriverLoginRequested(email, password)`
- `AuthCompanyLoginRequested(email, password)`
- `AuthCompanyRegisterRequested(name, nit, email, password, representativeName)`
- `AuthLogoutRequested`
- `AuthPasswordResetRequested(email)`
- `AuthCompanySelected(companyId, companyName)` — primera selección desde pantalla de selección
- `AuthActiveCompanyChangeRequested(companyId, companyName)` — cambio desde perfil/menú

## Estados definidos
- `AuthInitial` — antes de verificar sesión
- `AuthLoading` — operación en progreso
- `AuthRoleNotSelected` — no hay sesión; mostrar selección de rol
- `AuthDriverAuthenticated(user, companies, activeCompanyId?)` — conductor autenticado
- `AuthCompanyAuthenticated(company)` — empresa autenticada
- `AuthCompanySelectionRequired(user, companies)` — conductor con >1 empresa sin empresa activa guardada
- `AuthPasswordResetSent`
- `AuthError(message)`
- `AuthLoggedOut`

## Decisiones clave

### _onCheckSession con rehidratación completa (iteración-2, marzo 2026)
Implementados GetCurrentDriverUseCase y GetCurrentCompanyUseCase. El handler ahora:
1. Lee el rol con CheckSessionUseCase.
2. Si role == 'driver': llama GetCurrentDriverUseCase → GetDriverCompaniesUseCase → GetActiveCompanyUseCase y emite AuthDriverAuthenticated.
3. Si role == 'company': llama GetCurrentCompanyUseCase y emite AuthCompanyAuthenticated.
4. Cualquier Left en cualquier paso → AuthRoleNotSelected (fuerza re-login limpio).

El BLoC NO importa Firebase directamente. La verificación de currentUser ocurre dentro del datasource impl, y el repositorio/usecase propagan Left(NotAuthenticatedFailure) si no hay sesión activa.

### GetCurrentDriverUseCase / GetCurrentCompanyUseCase
Wrappean el resultado nullable del repositorio: si el repositorio devuelve Right(null), el UseCase lo convierte en Left(NotAuthenticatedFailure). Así el BLoC siempre recibe Either<Failure, Entity> sin nullable.

### SaveSessionUseCase — pendiente
El login exitoso de conductor y empresa todavía NO persiste el rol en SharedPreferences (SaveSessionUseCase no existe). La sesión persistida depende de que Firebase Auth mantenga el token activo entre sesiones. Pendiente de iteración futura.

### AuthTextFieldWidget acepta suffixIcon: Widget?
El campo expone `suffixIcon: Widget?` para que PasswordFieldWidget pueda inyectar el IconButton de toggle sin heredar ni convertir AuthTextFieldWidget en StatefulWidget.

## Widgets — características
- `RoleButtonWidget`: StatelessWidget, Card elevation 2, InkWell, Icon(48) + label centrados, SizedBox full width.
- `AuthTextFieldWidget`: StatelessWidget, OutlineInputBorder en todos los estados, prefixIcon opcional, suffixIcon opcional, obscureText bool.
- `PasswordFieldWidget`: StatefulWidget (único), envuelve AuthTextFieldWidget, toggle _obscure con Icons.visibility_outlined / visibility_off_outlined.
- `PrimaryButtonWidget`: StatelessWidget, SizedBox(width: inf, height: 52), isLoading deshabilita onPressed y muestra CircularProgressIndicator(strokeWidth: 2).
- `AuthErrorWidget`: StatelessWidget, Container errorSurface + border error + borderRadius 8, Row con Icon(error_outline) + Expanded(Text).
