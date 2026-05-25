import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/video_clip_entity.dart';
import '../../domain/repositories/driver_clips_repository.dart';
import '../datasources/driver_clips_datasource.dart';

class DriverClipsRepositoryImpl implements DriverClipsRepository {
  final DriverClipsDataSource dataSource;

  const DriverClipsRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<VideoClipEntity>>> fetchDriverClips({
    required String driverId,
    required int pageSize,
    String? pageToken,
  }) async {
    try {
      final clips = await dataSource.listDriverClips(
        driverId: driverId,
        pageSize: pageSize,
        pageToken: pageToken,
      );
      return Right(clips);
    } on DataSourceException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> getClipDownloadUrl(
    String firebaseStoragePath,
  ) async {
    try {
      final url = await dataSource.getClipDownloadUrl(firebaseStoragePath);
      return Right(url);
    } on DataSourceException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
