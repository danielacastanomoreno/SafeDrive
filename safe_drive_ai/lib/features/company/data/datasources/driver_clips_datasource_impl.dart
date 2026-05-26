import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/driver_clip_model.dart';
import 'driver_clips_datasource.dart';

class DriverClipsDataSourceImpl implements DriverClipsDataSource {
  final FirebaseStorage _firebaseStorage;

  const DriverClipsDataSourceImpl({required FirebaseStorage firebaseStorage})
      : _firebaseStorage = firebaseStorage;

  @override
  Future<List<DriverClipModel>> listDriverClips({
    required String driverId,
    required int pageSize,
    String? pageToken,
  }) async {
    try {
      final ref = _firebaseStorage.ref('drivers/$driverId/clips');
      final listResult = await ref.listAll();

      List<DriverClipModel> clips = [];
      for (final item in listResult.items) {
        final metadata = await item.getMetadata();
        clips.add(
          DriverClipModel.fromStorageItem(
            id: item.name,
            uploadedAt: metadata.updated ?? DateTime.now(),
            firebaseStoragePath: item.fullPath,
          ),
        );
      }

      clips.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

      int startIndex = 0;
      if (pageToken != null && pageToken.isNotEmpty) {
        startIndex = int.tryParse(pageToken) ?? 0;
      }
      int endIndex = (startIndex + pageSize).clamp(0, clips.length);
      return clips.sublist(startIndex, endIndex);
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found' || e.code == 'unauthorized') {
        // Storage no disponible → intentar fallback local
        return _listLocalClips(
          driverId: driverId,
          pageSize: pageSize,
          pageToken: pageToken,
        );
      }
      throw DataSourceException(e.message ?? e.code);
    } catch (e) {
      throw DataSourceException(e.toString());
    }
  }

  /// Fallback: lee clips del almacenamiento local del dispositivo.
  /// Busca en drowsiness_clips/{driverId}/ (ruta nueva) y en
  /// drowsiness_clips/ (ruta antigua, compatibilidad con clips previos).
  Future<List<DriverClipModel>> _listLocalClips({
    required String driverId,
    required int pageSize,
    String? pageToken,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final root = '${directory.path}/drowsiness_clips';

      final List<File> files = [];

      // Ruta nueva: drowsiness_clips/{driverId}/
      final newDir = Directory('$root/$driverId');
      if (await newDir.exists()) {
        files.addAll(newDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.mp4')));
      }

      // Ruta antigua: drowsiness_clips/ (clips grabados antes del cambio)
      final oldDir = Directory(root);
      if (await oldDir.exists()) {
        files.addAll(oldDir
            .listSync() // solo primer nivel, sin subcarpetas
            .whereType<File>()
            .where((f) => f.path.endsWith('.mp4')));
      }

      if (files.isEmpty) return [];

      files.sort(
          (a, b) => b.statSync().modified.compareTo(a.statSync().modified));

      final clips = files.map((f) {
        final name = f.path.split(Platform.pathSeparator).last;
        return DriverClipModel.fromStorageItem(
          id: name,
          uploadedAt: f.statSync().modified,
          firebaseStoragePath: f.path,
        );
      }).toList();

      int startIndex = 0;
      if (pageToken != null && pageToken.isNotEmpty) {
        startIndex = int.tryParse(pageToken) ?? 0;
      }
      int endIndex = (startIndex + pageSize).clamp(0, clips.length);
      return clips.sublist(startIndex, endIndex);
    } catch (e) {
      return [];
    }
  }

  @override
  Future<String> getClipDownloadUrl(String firebaseStoragePath) async {
    // Mock debug: URL pública directa
    if (firebaseStoragePath.startsWith('https://')) {
      return firebaseStoragePath;
    }
    // Archivo local (ruta absoluta del dispositivo)
    if (firebaseStoragePath.startsWith('/')) {
      return firebaseStoragePath;
    }
    try {
      final ref = _firebaseStorage.ref(firebaseStoragePath);
      return await ref.getDownloadURL();
    } catch (e) {
      throw DataSourceException(e.toString());
    }
  }
}
