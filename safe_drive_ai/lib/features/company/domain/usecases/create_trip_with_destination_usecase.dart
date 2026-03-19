import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../trips/domain/entities/trip_entity.dart';
import '../repositories/company_repository.dart';

class CreateTripWithDestinationUseCase
    implements UseCase<TripEntity, CreateTripWithDestinationParams> {
  final CompanyRepository repository;

  CreateTripWithDestinationUseCase(this.repository);

  @override
  Future<Either<Failure, TripEntity>> call(
      CreateTripWithDestinationParams params) {
    return repository.createTripWithDestination(
      companyId: params.companyId,
      driverId: params.driverId,
      destinationLat: params.destinationLat,
      destinationLng: params.destinationLng,
      destinationAddress: params.destinationAddress,
      scheduledStartTime: params.scheduledStartTime,
    );
  }
}

class CreateTripWithDestinationParams {
  const CreateTripWithDestinationParams({
    required this.companyId,
    required this.driverId,
    required this.destinationLat,
    required this.destinationLng,
    required this.destinationAddress,
    this.scheduledStartTime,
  });

  final String companyId;
  final String driverId;
  final double destinationLat;
  final double destinationLng;
  final String destinationAddress;
  final DateTime? scheduledStartTime;
}
