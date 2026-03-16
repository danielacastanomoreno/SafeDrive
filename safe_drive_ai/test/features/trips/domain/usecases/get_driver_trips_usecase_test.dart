import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_drive_ai/core/errors/failures.dart';
import 'package:safe_drive_ai/features/trips/domain/entities/trip_entity.dart';
import 'package:safe_drive_ai/features/trips/domain/repositories/trip_repository.dart';
import 'package:safe_drive_ai/features/trips/domain/usecases/get_driver_trips_usecase.dart';

class MockTripRepository extends Mock implements TripRepository {}

void main() {
  late GetDriverTripsUseCase usecase;
  late MockTripRepository mockRepository;

  setUp(() {
    mockRepository = MockTripRepository();
    usecase = GetDriverTripsUseCase(mockRepository);
  });

  const tDriverId = 'test-driver-id';
  final tTrips = [
    TripEntity(
      id: 'trip1',
      driverId: tDriverId,
      startTime: DateTime.now(),
      hasCameraPermission: true,
      status: TripStatus.completed,
    ),
    TripEntity(
      id: 'trip2',
      driverId: tDriverId,
      startTime: DateTime.now(),
      hasCameraPermission: false,
      status: TripStatus.active,
    ),
  ];

  test(
      'should get list of trips for the driver from the repository',
      () async {
    // arrange
    when(() => mockRepository.getDriverTrips(any()))
        .thenAnswer((_) async => Right(tTrips));
    // act
    final result = await usecase(const GetDriverTripsParams(driverId: tDriverId));
    // assert
    expect(result, Right(tTrips));
    verify(() => mockRepository.getDriverTrips(tDriverId));
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return a failure when repository fails', () async {
    // arrange
    const tFailure = ServerFailure(message: 'Server error');
    when(() => mockRepository.getDriverTrips(any()))
        .thenAnswer((_) async => const Left(tFailure));
    // act
    final result = await usecase(const GetDriverTripsParams(driverId: tDriverId));
    // assert
    expect(result, const Left(tFailure));
    verify(() => mockRepository.getDriverTrips(tDriverId));
    verifyNoMoreInteractions(mockRepository);
  });
}
