import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/video_clip_entity.dart';
import '../repositories/driver_clips_repository.dart';

class FetchDriverClipsUseCase
    extends UseCase<List<VideoClipEntity>, FetchDriverClipsParams> {
  final DriverClipsRepository repository;

  FetchDriverClipsUseCase(this.repository);

  @override
  Future<Either<Failure, List<VideoClipEntity>>> call(
    FetchDriverClipsParams params,
  ) async {
    return repository.fetchDriverClips(
      driverId: params.driverId,
      pageSize: params.pageSize,
      pageToken: params.pageToken,
    );
  }
}

class FetchDriverClipsParams {
  final String driverId;
  final int pageSize;
  final String? pageToken;

  FetchDriverClipsParams({
    required this.driverId,
    required this.pageSize,
    this.pageToken,
  });
}
