import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_drive_ai/core/errors/failures.dart';
import 'package:safe_drive_ai/features/auth/domain/entities/user_entity.dart';
import 'package:safe_drive_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:safe_drive_ai/features/auth/domain/usecases/register_driver_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late RegisterDriverUseCase usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = RegisterDriverUseCase(mockAuthRepository);
  });

  const tName = 'Juan Perez';
  const tCedula = '1234567890';
  const tEmail = 'juan@test.com';
  const tPassword = 'Password123!';

  final tUser = UserEntity(
    id: 'user123',
    name: tName,
    cedula: tCedula,
    email: tEmail,
    role: UserRole.driver,
    createdAt: DateTime.now(),
  );

  final tParams = RegisterDriverParams(
    name: tName,
    cedula: tCedula,
    email: tEmail,
    password: tPassword,
  );

  test(
    'debería reenviar la llamada a AuthRepository.registerDriver y retornar UserEntity',
    () async {
      // arrange
      when(
        () => mockAuthRepository.registerDriver(
          tName,
          tCedula,
          tEmail,
          tPassword,
        ),
      ).thenAnswer((_) async => Right(tUser));
      // act
      final result = await usecase(tParams);
      // assert
      expect(result, Right(tUser));
      verify(
        () => mockAuthRepository.registerDriver(
          tName,
          tCedula,
          tEmail,
          tPassword,
        ),
      ).called(1);
      verifyNoMoreInteractions(mockAuthRepository);
    },
  );

  test(
    'debería retornar Failure cuando AutRepository.registerDriver falla con la cédula duplicada',
    () async {
      // arrange
      when(
        () => mockAuthRepository.registerDriver(any(), any(), any(), any()),
      ).thenAnswer((_) async => const Left(CedulaAlreadyRegisteredFailure()));
      // act
      final result = await usecase(tParams);
      // assert
      expect(result, const Left(CedulaAlreadyRegisteredFailure()));
    },
  );
}
