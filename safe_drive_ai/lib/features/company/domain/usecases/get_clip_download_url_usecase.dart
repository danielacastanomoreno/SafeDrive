import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/driver_clips_repository.dart';

class GetClipDownloadUrlUseCase
    extends UseCase<String, GetClipDownloadUrlParams> {
  final DriverClipsRepository repository;

  GetClipDownloadUrlUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(GetClipDownloadUrlParams params) {
    return repository.getClipDownloadUrl(params.firebaseStoragePath);
  }
}

class GetClipDownloadUrlParams {
  final String firebaseStoragePath;

  GetClipDownloadUrlParams({required this.firebaseStoragePath});
}
