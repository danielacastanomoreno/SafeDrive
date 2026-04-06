# safe_drive_ai

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Configuracion Firebase local (equipo)

Este proyecto requiere el archivo local de Firebase para Android:

- android/app/google-services.json

Para evitar conflictos en equipo, no se versiona ese archivo en Git.

Pasos en cada maquina:

1. Coloca el archivo google-services.json en la raiz del workspace.
2. Ejecuta este script desde safe_drive_ai:
	powershell -ExecutionPolicy Bypass -File .\scripts\setup_local_firebase.ps1
3. Ejecuta flutter run o flutter build apk --debug.
