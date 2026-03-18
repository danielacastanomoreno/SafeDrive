import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../injection_container.dart' as di;
import '../../../auth/domain/entities/company_link_entity.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../trips/domain/entities/trip_entity.dart';
import '../../../trips/domain/usecases/get_driver_trips_usecase.dart';

class CompanyDriverDetailPage extends StatefulWidget {
  const CompanyDriverDetailPage({
    super.key,
    required this.link,
    required this.profile,
  });

  final CompanyLinkEntity link;
  final UserEntity profile;

  @override
  State<CompanyDriverDetailPage> createState() =>
      _CompanyDriverDetailPageState();
}

class _CompanyDriverDetailPageState extends State<CompanyDriverDetailPage> {
  late Future<List<TripEntity>?> _tripsFuture;

  @override
  void initState() {
    super.initState();
    _tripsFuture = _loadTrips();
  }

  Future<List<TripEntity>?> _loadTrips() async {
    final useCase = di.sl<GetDriverTripsUseCase>();
    final result =
        await useCase(GetDriverTripsParams(driverId: widget.profile.id));
    return result.fold(
      (failure) => null, // O manejar el error visualmente
      (trips) => trips,
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes} min';
    }
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detalle del Conductor'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildProfileHeader(),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 8),
              child: Text(
                'Historial de Viajes',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
            ),
          ),
          FutureBuilder<List<TripEntity>?>(
            future: _tripsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
                );
              }

              if (snapshot.hasError || snapshot.data == null) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        'Error al cargar el historial de viajes.',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ),
                );
              }

              final trips = snapshot.data!;
              if (trips.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        'Este conductor no ha registrado viajes aún.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final trip = trips[index];
                    return _buildTripCard(trip);
                  },
                  childCount: trips.length,
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/company/create-trip', extra: {
            'companyId': widget.link.companyId,
            'driverId': widget.profile.id,
            'driverName': widget.profile.name,
          });
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Crear Viaje'),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primarySurface,
            child: Icon(
              Icons.person,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.profile.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.profile.email,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInfoColumn(
                Icons.work_outline,
                'Cargo',
                widget.link.cargo,
              ),
              _buildInfoColumn(
                Icons.phone_outlined,
                'Teléfono',
                widget.link.phone,
              ),
              _buildInfoColumn(
                Icons.badge_outlined,
                'Estado',
                widget.link.status == LinkStatus.active ? 'Activo' : 'Inactivo',
                color: widget.link.status == LinkStatus.active
                    ? AppColors.success
                    : AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(IconData icon, String label, String value,
      {Color? color}) {
    return Column(
      children: [
        Icon(icon, size: 24, color: AppColors.textSecondary),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTripCard(TripEntity trip) {
    final statusColor = _getTripStatusColor(trip.status);
    final statusText = _getTripStatusText(trip.status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.divider),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(trip.startTime),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.timer_outlined,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  trip.endTime != null
                      ? 'Duración: ${_formatDuration(trip.endTime!.difference(trip.startTime))}'
                      : 'En progreso...',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  trip.hasCameraPermission
                      ? Icons.videocam_outlined
                      : Icons.videocam_off_outlined,
                  size: 16,
                  color: trip.hasCameraPermission
                      ? AppColors.primary
                      : AppColors.warning,
                ),
                const SizedBox(width: 4),
                Text(
                  trip.hasCameraPermission
                      ? 'Monitoreo de cámara activado'
                      : 'Sin monitoreo de cámara',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTripStatusColor(TripStatus status) {
    switch (status) {
      case TripStatus.active:
        return AppColors.primary;
      case TripStatus.pending:
        return AppColors.warning;
      case TripStatus.pendingApproval:
        return AppColors.warning;
      case TripStatus.onBreak:
        return AppColors.warning;
      case TripStatus.completed:
        return AppColors.success;
    }
  }

  String _getTripStatusText(TripStatus status) {
    switch (status) {
      case TripStatus.active:
        return 'En curso';
      case TripStatus.pending:
        return 'Pendiente';
      case TripStatus.pendingApproval:
        return 'Esperando aprobación';
      case TripStatus.onBreak:
        return 'En pausa';
      case TripStatus.completed:
        return 'Finalizado';
    }
  }
}
