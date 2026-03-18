import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../injection_container.dart' as di;
import '../../../trips/domain/entities/route_point_entity.dart';
import '../../../trips/domain/usecases/get_trip_route_usecase.dart';
import '../../domain/usecases/get_driver_profile_usecase.dart';
import '../../../trips/domain/entities/trip_entity.dart';
import '../bloc/company_bloc.dart';
import '../bloc/company_event.dart';

class TripApprovalDetailPage extends StatefulWidget {
  const TripApprovalDetailPage({
    super.key,
    required this.trip,
    required this.companyId,
  });

  final TripEntity trip;
  final String companyId;

  @override
  State<TripApprovalDetailPage> createState() => _TripApprovalDetailPageState();
}

class _TripApprovalDetailPageState extends State<TripApprovalDetailPage> {
  String _driverName = 'Cargando...';
  List<RoutePointEntity> _routePoints = [];
  bool _loadingRoute = true;

  @override
  void initState() {
    super.initState();
    _loadDriver();
    _loadRoute();
  }

  Future<void> _loadDriver() async {
    final useCase = di.sl<GetDriverProfileUseCase>();
    final result = await useCase(GetDriverProfileParams(driverId: widget.trip.driverId));
    if (mounted) {
      setState(() {
        result.fold(
          (failure) => _driverName = 'Desconocido',
          (profile) => _driverName = profile.name,
        );
      });
    }
  }

  Future<void> _loadRoute() async {
    final useCase = di.sl<GetTripRouteUseCase>();
    final result = await useCase(GetTripRouteParams(tripId: widget.trip.id));
    if (mounted) {
      setState(() {
        result.fold(
          (failure) => _loadingRoute = false,
          (points) {
            _routePoints = points;
            _loadingRoute = false;
          },
        );
      });
    }
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

  void _approveTrip() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Aprobar cierre'),
        content: const Text(
          '¿Estás seguro de aprobar este viaje? Se marcará como completado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<CompanyBloc>().add(
                    CompanyTripClosureApproved(
                      tripId: widget.trip.id,
                      companyId: widget.companyId,
                    ),
                  );
              Navigator.of(context).pop();
            },
            child: const Text(
              'Aprobar',
              style: TextStyle(color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }

  void _rejectTrip() {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<CompanyBloc>(),
        child: Builder(
          builder: (dialogContext) => AlertDialog(
            title: const Text('Rechazar cierre'),
            content: const Text(
              '¿Estás seguro de rechazar este viaje? El conductor será notificado.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.read<CompanyBloc>().add(
                    CompanyTripClosureRejected(
                      tripId: widget.trip.id,
                      companyId: widget.companyId,
                    ),
                  );
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Rechazar',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final duration = widget.trip.endTime != null
        ? widget.trip.endTime!.difference(widget.trip.startTime)
        : Duration.zero;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Viaje'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 250,
              color: AppColors.divider,
              child: _loadingRoute
                  ? const Center(child: CircularProgressIndicator())
                  : _routePoints.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay datos de ruta',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(
                              _routePoints.first.lat,
                              _routePoints.first.lng,
                            ),
                            initialZoom: 14,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.bombastik.safedrive',
                            ),
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: _routePoints
                                      .map((p) => LatLng(p.lat, p.lng))
                                      .toList(),
                                  color: AppColors.primary,
                                  strokeWidth: 4,
                                ),
                              ],
                            ),
                            MarkerLayer(
                              markers: [
                                if (_routePoints.isNotEmpty)
                                  Marker(
                                    point: LatLng(
                                      _routePoints.first.lat,
                                      _routePoints.first.lng,
                                    ),
                                    width: 30,
                                    height: 30,
                                    child: const Icon(
                                      Icons.play_circle_fill,
                                      color: AppColors.success,
                                      size: 30,
                                    ),
                                  ),
                                if (_routePoints.isNotEmpty)
                                  Marker(
                                    point: LatLng(
                                      _routePoints.last.lat,
                                      _routePoints.last.lng,
                                    ),
                                    width: 30,
                                    height: 30,
                                    child: const Icon(
                                      Icons.stop_circle,
                                      color: AppColors.error,
                                      size: 30,
                                    ),
                                  ),
                                if (widget.trip.hasDestination)
                                  Marker(
                                    point: LatLng(
                                      widget.trip.destinationLat!,
                                      widget.trip.destinationLng!,
                                    ),
                                    width: 30,
                                    height: 30,
                                    child: const Icon(
                                      Icons.location_on,
                                      color: AppColors.warning,
                                      size: 30,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primarySurface,
                        child: Icon(Icons.person, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _driverName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'ID: ${widget.trip.driverId.substring(0, 8)}...',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Resumen del Viaje',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    Icons.play_arrow,
                    'Inicio',
                    _formatDate(widget.trip.startTime),
                  ),
                  _buildInfoRow(
                    Icons.stop,
                    'Fin',
                    widget.trip.endTime != null
                        ? _formatDate(widget.trip.endTime!)
                        : 'En curso',
                  ),
                  _buildInfoRow(
                    Icons.timer,
                    'Duración',
                    _formatDuration(duration),
                  ),
                  if (widget.trip.hasDestination) ...[
                    _buildInfoRow(
                      Icons.location_on,
                      'Destino pactado',
                      widget.trip.destinationAddress ?? 'Coordenadas definidas',
                    ),
                    _buildInfoRow(
                      Icons.warning,
                      'Cerrado fuera de zona',
                      widget.trip.isOutOfZone ? 'Sí' : 'No',
                      valueColor: widget.trip.isOutOfZone
                          ? AppColors.error
                          : AppColors.success,
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _rejectTrip,
                          icon: const Icon(Icons.close),
                          label: const Text('Rechazar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _approveTrip,
                          icon: const Icon(Icons.check),
                          label: const Text('Aprobar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
