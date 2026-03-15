import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../bloc/driver_bloc.dart';
import '../bloc/driver_event.dart';
import '../bloc/driver_state.dart';
import '../widgets/company_link_card_widget.dart';

/// Pestaña que lista las empresas activas vinculadas al conductor.
class DriverCompaniesPage extends StatefulWidget {
  const DriverCompaniesPage({super.key, required this.driver});

  final UserEntity driver;

  @override
  State<DriverCompaniesPage> createState() => _DriverCompaniesPageState();
}

class _DriverCompaniesPageState extends State<DriverCompaniesPage> {
  @override
  void initState() {
    super.initState();
    context.read<DriverBloc>().add(
          DriverCompaniesRequested(driverId: widget.driver.id),
        );
  }

  Future<void> _refresh() async {
    context.read<DriverBloc>().add(
          DriverCompaniesRequested(driverId: widget.driver.id),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DriverBloc, DriverState>(
      buildWhen: (previous, current) =>
          current is DriverLoading ||
          current is DriverCompaniesLoaded ||
          current is DriverError,
      builder: (context, state) {
        if (state is DriverLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (state is DriverError) {
          return RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.primary,
            child: ListView(
              children: [
                const SizedBox(height: 80),
                Center(
                  child: Text(
                    state.message,
                    style: const TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }

        if (state is DriverCompaniesLoaded) {
          if (state.companies.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.primary,
              child: ListView(
                children: const [
                  SizedBox(height: 80),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.business_outlined,
                          size: 64,
                          color: AppColors.divider,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No estás vinculado a ninguna empresa',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.companies.length,
              itemBuilder: (context, index) => CompanyLinkCardWidget(
                link: state.companies[index],
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
