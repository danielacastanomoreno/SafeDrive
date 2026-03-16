---
name: Gradle y pubspec configurados
description: Versiones pinneadas en pubspec.yaml y configuración Gradle Android resuelta para Safe Drive AI (marzo 2026)
type: project
---

El pubspec.yaml del proyecto está configurado con las siguientes dependencias resueltas y verificadas con `flutter pub get` exitoso.

**Dependencias principales pinneadas:**
- firebase_core: ^3.6.0
- firebase_auth: ^5.3.1
- cloud_firestore: ^5.4.4
- firebase_storage: ^12.3.2
- firebase_messaging: ^15.1.3
- flutter_bloc: ^8.1.6 / bloc: ^8.1.4
- equatable: ^2.0.5
- get_it: ^8.0.2
- injectable: ^2.4.4
- go_router: ^14.2.7
- dartz: ^0.10.1
- google_mlkit_face_detection: ^0.11.0
- shared_preferences: ^2.3.2
- camera: ^0.11.0+2
- speech_to_text: ^7.0.0
- audioplayers: ^6.1.0
- vibration: ^2.0.0
- video_player: ^2.9.1
- permission_handler: ^11.3.1
- path_provider: ^2.1.4
- intl: ^0.19.0
- connectivity_plus: ^6.1.0

**Configuración Android:**
- El proyecto usa Kotlin Script (.kts) para build.gradle raíz y settings.gradle.kts
- El app/build.gradle usa Groovy (sin .kts) — es el único archivo Groovy
- compileSdk = 34, targetSdk = 34, minSdk = 21
- multiDexEnabled = true
- Firebase BOM: 33.5.1
- Google Services plugin: com.google.gms.google-services version 4.4.2 declarado en settings.gradle.kts
- El plugin google-services se aplica en app/build.gradle con `id "com.google.gms.google-services"`

**Assets creados:**
- assets/images/
- assets/models/
- assets/audio/

**Why:** El proyecto fue creado con `flutter create` que genera un pubspec.yaml vacío. Fue necesario agregar todas las dependencias y configurar Android para compilar correctamente.

**How to apply:** Si se necesita agregar una dependencia nueva, verificar compatibilidad con las versiones del BOM de Firebase (33.5.1) y con Dart SDK >=3.3.0 <4.0.0.
