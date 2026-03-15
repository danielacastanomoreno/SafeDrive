import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/trip_repository.dart';

class SaveRoutePointUseCase implements UseCase<void, SaveRoutePointParams> {
  const SaveRoutePointUseCase(this._repository);
  final TripRepository _repository;

  @override
  Future<Either<Failure, void>> call(SaveRoutePointParams params) =>
      _repository.saveRoutePoint(
        tripId: params.tripId,
        lat: params.lat,
        lng: params.lng,
      );
}

class SaveRoutePointParams extends Equatable {
  const SaveRoutePointParams({
    required this.tripId,
    required this.lat,
    required this.lng,
  });

  final String tripId;
  final double lat;
  final double lng;

  @override
  List<Object?> get props => [tripId, lat, lng];
}
