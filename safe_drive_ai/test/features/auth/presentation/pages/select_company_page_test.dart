import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';

import 'package:safe_drive_ai/features/auth/domain/entities/company_link_entity.dart';
import 'package:safe_drive_ai/features/auth/domain/entities/user_entity.dart';
import 'package:safe_drive_ai/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:safe_drive_ai/features/auth/presentation/bloc/auth_event.dart';
import 'package:safe_drive_ai/features/auth/presentation/bloc/auth_state.dart';
import 'package:safe_drive_ai/features/auth/presentation/pages/select_company_page.dart';

//Mocks

//MockBloc viene de bloc_test, que ya está en tu pubspec.yaml
class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

//Fixtures

final _user = UserEntity(
  id: 'driver-1',
  name: 'Juan Pérez',
  email: 'juan@test.com',
  cedula: '123456789',
  role: UserRole.driver,
  createdAt: DateTime(2024),
);

CompanyLinkEntity _link(String id, String name) => CompanyLinkEntity(
      id: 'link-$id',
      companyId: id,
      companyName: name,
      driverId: 'driver-1',
      cargo: 'Conductor',
      phone: '3001234567',
      status: LinkStatus.active,
      linkedAt: DateTime(2024),
    );

//Helper

Widget _buildTestable(MockAuthBloc bloc) {
  final router = GoRouter(
    initialLocation: '/driver/select-company',
    routes: [
      GoRoute(
        path: '/driver/select-company',
        builder: (_, __) => BlocProvider<AuthBloc>.value(
          value: bloc,
          child: const SelectCompanyPage(),
        ),
      ),
      GoRoute(
        path: '/driver/home',
        builder: (_, __) => const Scaffold(body: Text('Driver Home')),
      ),
      GoRoute(
        path: '/role-selection',
        builder: (_, __) => const Scaffold(body: Text('Role Selection')),
      ),
    ],
  );

  return MaterialApp.router(routerConfig: router);
}

//Tests

void main() {
  late MockAuthBloc mockBloc;

  setUp(() {
    mockBloc = MockAuthBloc();
    registerFallbackValue(
      const AuthCompanySelected(companyId: '', companyName: ''),
    );
  });

  tearDown(() => mockBloc.close());

  //Caso 1: múltiples empresas

  group('Caso 1 — conductor vinculado a múltiples empresas', () {
    late AuthCompanySelectionRequired selectionState;
    late List<CompanyLinkEntity> companies;

    setUp(() {
      companies = [
        _link('company-A', 'Transportes Andinos'),
        _link('company-B', 'Logística del Norte'),
      ];
      selectionState = AuthCompanySelectionRequired(
        user: _user,
        companies: companies,
      );
      whenListen(
        mockBloc,
        Stream.value(selectionState),
        initialState: selectionState,
      );
    });

    testWidgets('muestra lista con el nombre de cada empresa vinculada',
        (tester) async {
      await tester.pumpWidget(_buildTestable(mockBloc));
      await tester.pump();

      expect(find.text('Transportes Andinos'), findsOneWidget);
      expect(find.text('Logística del Norte'), findsOneWidget);
    });

    testWidgets('botón Continuar está deshabilitado sin selección previa',
        (tester) async {
      await tester.pumpWidget(_buildTestable(mockBloc));
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Continuar'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets(
        'seleccionar empresa habilita Continuar y despacha AuthCompanySelected',
        (tester) async {
      await tester.pumpWidget(_buildTestable(mockBloc));
      await tester.pump();

      await tester.tap(find.text('Transportes Andinos'));
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Continuar'),
      );
      expect(button.onPressed, isNotNull);

      await tester.tap(find.text('Continuar'));
      await tester.pump();

      verify(
        () => mockBloc.add(
          const AuthCompanySelected(
            companyId: 'company-A',
            companyName: 'Transportes Andinos',
          ),
        ),
      ).called(1);
    });

    testWidgets(
        'cuando BLoC emite AuthDriverAuthenticated navega a /driver/home',
        (tester) async {
      final authenticatedState = AuthDriverAuthenticated(
        user: _user,
        companies: companies,
        activeCompanyId: 'company-A',
      );

      whenListen(
        mockBloc,
        Stream.fromIterable([selectionState, authenticatedState]),
        initialState: selectionState,
      );

      await tester.pumpWidget(_buildTestable(mockBloc));
      await tester.pumpAndSettle();

      expect(find.text('Driver Home'), findsOneWidget);
    });
  });

  //Caso 2: una sola empresa

  group('Caso 2 — conductor vinculado a una sola empresa', () {
    testWidgets('auto-selecciona la empresa y navega a /driver/home',
        (tester) async {
      final singleCompany = [_link('company-A', 'Transportes Andinos')];

      final singleState = AuthCompanySelectionRequired(
        user: _user,
        companies: singleCompany,
      );

      final authenticatedState = AuthDriverAuthenticated(
        user: _user,
        companies: singleCompany,
        activeCompanyId: 'company-A',
      );

      whenListen(
        mockBloc,
        Stream.fromIterable([singleState, authenticatedState]),
        initialState: singleState,
      );

      await tester.pumpWidget(_buildTestable(mockBloc));
      await tester.pumpAndSettle();

      //Despacha AuthCompanySelected automáticamente sin interacción del usuario.
      verify(
        () => mockBloc.add(
          const AuthCompanySelected(
            companyId: 'company-A',
            companyName: 'Transportes Andinos',
          ),
        ),
      ).called(greaterThanOrEqualTo(1));

      //Navega directo a home sin mostrar la lista.
      expect(find.text('Driver Home'), findsOneWidget);
    });
  });
}