// lib/core/constants/app_strings.dart

/// Todos los textos visibles de Safe Drive AI en español.
/// Usar siempre estas constantes — nunca strings literales en widgets.
abstract class AppStrings {
  AppStrings._();

  // ── App ───────────────────────────────────────────────────────────────────
  static const String appName = 'Safe Drive AI';
  static const String appTagline = 'Seguridad vial inteligente';

  // ── Auth — Login ──────────────────────────────────────────────────────────
  static const String loginTitle = 'Iniciar sesión';
  static const String loginSubtitle = 'Bienvenido a Safe Drive AI';
  static const String loginEmailLabel = 'Correo electrónico';
  static const String loginEmailHint = 'ejemplo@correo.com';
  static const String loginPasswordLabel = 'Contraseña';
  static const String loginPasswordHint = 'Tu contraseña';
  static const String loginButton = 'Ingresar';
  static const String loginForgotPassword = '¿Olvidaste tu contraseña?';
  static const String loginNoAccount = '¿No tienes cuenta?';

  // ── Auth — Recuperar contraseña ───────────────────────────────────────────
  static const String recoverPasswordTitle = 'Recuperar contraseña';
  static const String recoverPasswordSubtitle =
      'Te enviaremos un correo para restablecer tu contraseña.';
  static const String recoverPasswordButton = 'Enviar correo';
  static const String recoverPasswordSuccess =
      'Correo enviado. Revisa tu bandeja de entrada.';

  // ── Auth — Registro conductor ─────────────────────────────────────────────
  static const String registerDriverTitle = 'Registro de conductor';
  static const String registerNameLabel = 'Nombre completo';
  static const String registerNameHint = 'Ej: Juan Pérez García';
  static const String registerCedulaLabel = 'Cédula de ciudadanía';
  static const String registerCedulaHint = 'Ej: 1234567890';
  static const String registerEmailLabel = 'Correo electrónico';
  static const String registerPasswordLabel = 'Contraseña';
  static const String registerPasswordHint = 'Mínimo 8 caracteres';
  static const String registerConfirmPasswordLabel = 'Confirmar contraseña';
  static const String registerButton = 'Registrarme';
  static const String registerAlreadyHaveAccount = '¿Ya tienes cuenta?';

  // ── Auth — Registro empresa ───────────────────────────────────────────────
  static const String registerCompanyTitle = 'Registro de empresa';
  static const String registerCompanyNameLabel = 'Nombre de la empresa';
  static const String registerNitLabel = 'NIT';
  static const String registerNitHint = 'Ej: 900123456-7';
  static const String registerRepresentativeLabel = 'Nombre del representante';

  // ── Roles ─────────────────────────────────────────────────────────────────
  static const String roleDriver = 'Conductor';
  static const String roleCompany = 'Empresa';
  static const String roleSelectionTitle = '¿Cómo deseas registrarte?';
  static const String roleSelectionSubtitle =
      'Selecciona el tipo de cuenta que deseas crear.';

  // ── Conductor — Home ──────────────────────────────────────────────────────
  static const String driverHomeTitle = 'Inicio';
  static const String driverWelcome = '¡Bienvenido, conductor!';
  static const String driverStartTrip = 'Iniciar viaje';
  static const String driverTripHistory = 'Mis viajes';
  static const String driverProfile = 'Mi perfil';
  static const String driverInvitations = 'Invitaciones';

  // ── Conductor — Viaje activo ──────────────────────────────────────────────
  static const String tripActive = 'Viaje en curso';
  static const String tripStartTime = 'Inicio';
  static const String tripDuration = 'Duración';
  static const String tripEndTrip = 'Finalizar viaje';
  static const String tripEndConfirmTitle = '¿Finalizar viaje?';
  static const String tripEndConfirmBody =
      'Esta acción terminará el registro del viaje actual.';
  static const String tripEndConfirmYes = 'Sí, finalizar';
  static const String tripEndConfirmNo = 'Cancelar';

  // ── Conductor — Alertas ───────────────────────────────────────────────────
  static const String alertDrowsinessL1 = '¡Atención! Señales de somnolencia detectadas.';
  static const String alertDrowsinessL2 = '¡Peligro! Somnolencia crítica. Detén el vehículo.';
  static const String alertSeatbelt = 'No se detecta el cinturón de seguridad.';
  static const String alertPeriodicQuestion = '¿Te encuentras bien?';
  static const String alertAnswerYes = 'Sí, estoy bien';
  static const String alertAnswerNo = 'Necesito descansar';

  // ── Empresa — Home ────────────────────────────────────────────────────────
  static const String companyHomeTitle = 'Panel de control';
  static const String companyDrivers = 'Conductores';
  static const String companyTrips = 'Viajes';
  static const String companyReports = 'Reportes';
  static const String companyActiveDrivers = 'Conductores activos';
  static const String companyNoDrivers = 'No tienes conductores vinculados aún.';

  // ── Empresa — Gestión de conductores ─────────────────────────────────────
  static const String inviteDriver = 'Invitar conductor';
  static const String inviteDriverTitle = 'Invitar conductor';
  static const String inviteDriverCedulaLabel = 'Cédula del conductor';
  static const String inviteCargoLabel = 'Cargo';
  static const String invitePhoneLabel = 'Teléfono de contacto';
  static const String invitePhoneHint = 'Ej: 3001234567';
  static const String inviteButton = 'Enviar invitación';
  static const String inviteSent = 'Invitación enviada exitosamente.';
  static const String invitePending = 'Pendiente';
  static const String inviteAccepted = 'Aceptada';
  static const String inviteRejected = 'Rechazada';

  // ── Conductor — Invitaciones ──────────────────────────────────────────────
  static const String invitationReceived = 'Invitación recibida';
  static const String invitationFrom = 'De';
  static const String invitationCargo = 'Cargo';
  static const String invitationAccept = 'Aceptar';
  static const String invitationReject = 'Rechazar';
  static const String invitationAccepted = 'Invitación aceptada.';
  static const String invitationRejected = 'Invitación rechazada.';

  // ── Historial de viajes ───────────────────────────────────────────────────
  static const String tripHistoryTitle = 'Historial de viajes';
  static const String tripHistoryEmpty = 'No hay viajes registrados aún.';
  static const String tripDetailTitle = 'Detalle del viaje';
  static const String tripDrowsinessL1Events = 'Alertas de somnolencia leve';
  static const String tripDrowsinessL2Events = 'Alertas de somnolencia crítica';
  static const String tripSeatbeltEvents = 'Alertas de cinturón';
  static const String tripVoiceAlerts = 'Alertas de voz';
  static const String tripVoiceAnswered = 'Respondidas';

  // ── General ───────────────────────────────────────────────────────────────
  static const String loading = 'Cargando...';
  static const String retry = 'Reintentar';
  static const String save = 'Guardar';
  static const String cancel = 'Cancelar';
  static const String confirm = 'Confirmar';
  static const String back = 'Volver';
  static const String close = 'Cerrar';
  static const String logout = 'Cerrar sesión';
  static const String logoutConfirm = '¿Deseas cerrar sesión?';
  static const String yes = 'Sí';
  static const String no = 'No';

  // ── Errores ───────────────────────────────────────────────────────────────
  static const String errorGeneral = 'Ocurrió un error. Intenta de nuevo.';
  static const String errorNetwork = 'Sin conexión a internet.';
  static const String errorAuth = 'Correo o contraseña incorrectos.';
  static const String errorAuthUserNotFound = 'No existe una cuenta con ese correo.';
  static const String errorAuthWeakPassword = 'La contraseña es demasiado débil.';
  static const String errorAuthEmailInUse = 'Ese correo ya está registrado.';
  static const String errorPermissionDenied = 'Permiso denegado.';
  static const String errorCameraPermission =
      'Se requiere acceso a la cámara para el monitoreo.';
  static const String errorNotFound = 'No se encontró la información solicitada.';
  static const String errorServerFailure = 'Error en el servidor. Intenta más tarde.';

  // ── Validaciones de formulario ────────────────────────────────────────────
  static const String validationRequired = 'Este campo es obligatorio.';
  static const String validationEmail = 'Ingresa un correo electrónico válido.';
  static const String validationPassword =
      'La contraseña debe tener al menos 8 caracteres.';
  static const String validationPasswordMatch = 'Las contraseñas no coinciden.';
  static const String validationCedula =
      'La cédula debe tener entre 6 y 10 dígitos numéricos.';
  static const String validationNit =
      'El NIT debe tener el formato XXXXXXXXX-Y.';
  static const String validationPhone =
      'El teléfono debe tener 10 dígitos y comenzar con 3.';

  // ── Permisos ──────────────────────────────────────────────────────────────
  static const String permissionCameraTitle = 'Permiso de cámara';
  static const String permissionCameraBody =
      'Safe Drive AI necesita acceso a la cámara para monitorear al conductor durante el viaje.';
  static const String permissionNotificationTitle = 'Permiso de notificaciones';
  static const String permissionNotificationBody =
      'Activa las notificaciones para recibir alertas de seguridad.';
  static const String permissionGrant = 'Conceder permiso';
  static const String permissionDeny = 'Ahora no';
}
