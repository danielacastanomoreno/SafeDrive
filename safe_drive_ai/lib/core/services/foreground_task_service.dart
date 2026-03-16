import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class ForegroundTaskService {
  /// Detiene el monitoreo del Isolate y finaliza el servicio en foreground
  Future<void> stopTask() async {
    // Envia señal vía SendPort si es necesario antes de detener
    if (await FlutterForegroundTask.isRunningService) {
      FlutterForegroundTask.sendDataToTask('STOP_MONITORING');
      await FlutterForegroundTask.stopService();
    }
  }
}
