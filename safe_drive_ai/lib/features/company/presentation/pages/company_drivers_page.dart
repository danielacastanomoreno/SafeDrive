import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/company_link_entity.dart';
import '../bloc/company_bloc.dart';
import '../bloc/company_event.dart';
import '../bloc/company_state.dart';
import '../widgets/driver_card_widget.dart';

/// Pestaña que muestra la lista de conductores activos vinculados a la empresa.
///
/// Los perfiles de conductor (nombre, cédula) se obtienen en paralelo
/// a través de [GetDriverProfileUseCase] vía FutureBuilder independiente
/// para no contaminar el estado global del [CompanyBloc].
class CompanyDriversPage extends StatefulWidget {
  const CompanyDriversPage({
    super.key,
    required this.companyId,
    required this.companyName,
  });

  final String companyId;
  final String companyName;

  @override
  State<CompanyDriversPage> createState() => _CompanyDriversPageState();
}

class _CompanyDriversPageState extends State<CompanyDriversPage> {
  @override
  void initState() {
    super.initState();
    context.read<CompanyBloc>().add(
          CompanyDriversRequested(companyId: widget.companyId),
        );
  }

  Future<void> _onRefresh() async {
    context.read<CompanyBloc>().add(
          CompanyDriversRequested(companyId: widget.companyId),
        );
    await Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CompanyBloc, CompanyState>(
      listenWhen: (previous, current) =>
          current is CompanyActionSuccess || current is CompanyError,
      listener: (context, state) {
        if (state is CompanyActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state is CompanyError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      buildWhen: (previous, current) =>
          current is CompanyLoading ||
          current is CompanyDriversLoaded ||
          current is CompanyError,
      builder: (context, state) {
        if (state is CompanyLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (state is CompanyDriversLoaded) {
          return _buildDriversList(context, state.drivers);
        }

        if (state is CompanyError) {
          return _buildError(context, state.message);
        }

        return _buildDriversList(context, const []);
      },
    );
  }

  Widget _buildDriversList(
    BuildContext context,
    List<CompanyLinkEntity> drivers,
  ) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primary,
      child: drivers.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: AppColors.divider,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No tienes conductores vinculados',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Usa el boton + para invitar un conductor',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: drivers.length,
              itemBuilder: (context, index) {
                final link = drivers[index];
                return DriverCardWidget(
                  key: ValueKey(link.id),
                  link: link,
                  companyId: widget.companyId,
                  onTap: (profile) {
                    context.push(
                      '/company/driver-detail',
                      extra: {
                        'link': link,
                        'profile': profile,
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context.read<CompanyBloc>().add(
                      CompanyDriversRequested(companyId: widget.companyId),
                    );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
