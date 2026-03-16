import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/trip_entity.dart';
import '../../domain/usecases/get_trip_route_usecase.dart';

/// Pantalla de resumen del viaje mostrada automáticamente al finalizar.
/// Incluye mapa con la ruta completa.
class TripSummaryPage extends StatefulWidget {
  const TripSummaryPage({super.key, this.trip});

  /// Trip entity - puede ser null si se cerró por PIN/aprobación remota
  final TripEntity? trip;

  @override
  State<TripSummaryPage> createState() => _TripSummaryPageState();
}

class _TripSummaryPageState extends State<TripSummaryPage> {
  List<LatLng> _route = [];
  bool _loadingRoute = true;
  TripEntity? _trip;
  bool _loadingTrip = true;

  @override
  void initState() {
    super.initState();
    _initializeTrip();
  }

  Future<void> _initializeTrip() async {
    if (widget.trip != null) {
      _trip = widget.trip;
      _loadingTrip = false;
      _loadRoute();
    } else {
      // Trip was closed via PIN/remote - try to get the last trip from driver
      // For now, show a simplified summary
      setState(() {
        _loadingTrip = false;
        _loadingRoute = false;
      });
    }
  }

  Future<void> _loadRoute() async {
    if (_trip == null) {
      setState(() => _loadingRoute = false);
      return;
    }

    final result = await sl<GetTripRouteUseCase>()(
      GetTripRouteParams(tripId: _trip!.id),
    );
    result.fold(
      (_) => setState(() => _loadingRoute = false),
      (points) {
        setState(() {
          _route = points.map((p) => LatLng(p.lat, p.lng)).toList();
          _loadingRoute = false;
        });
      },
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatDateTime(DateTime dt) =>
      DateFormat('dd/MM/yyyy HH:mm:ss').format(dt);

  LatLng? get _mapCenter {
    if (_route.isEmpty) return null;
    final avgLat =
        _route.map((p) => p.latitude).reduce((a, b) => a + b) / _route.length;
    final avgLng =
        _route.map((p) => p.longitude).reduce((a, b) => a + b) / _route.length;
    return LatLng(avgLat, avgLng);
  }

  @override
  Widget build(BuildContext context) {
    // Handle loading and null cases
    if (_loadingTrip || _trip == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Resumen del viaje'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          automaticallyImplyLeading: false,
          elevation: 0,
        ),
        body: const SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 64),
                SizedBox(height: 16),
                Text(
                  'Viaje finalizado',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                CircularProgressIndicator(color: AppColors.primary),
              ],
            ),
          ),
        ),
      );
    }

    final duration = _trip!.elapsed;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Resumen del viaje'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ────────────────────────────────────────────────────
              const Icon(Icons.check_circle,
                  color: AppColors.success, size: 64),
              const SizedBox(height: 12),
              const Text(
                'Viaje finalizado',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 28),

              // ── Stats ──────────────────────────────────────────────────────
              _SummaryRow(
                icon: Icons.play_circle_outline,
                label: 'Inicio',
                value: _formatDateTime(_trip!.startTime),
              ),
              const Divider(height: 24),
              _SummaryRow(
                icon: Icons.stop_circle_outlined,
                label: 'Fin',
                value: _formatDateTime(_trip!.endTime!),
              ),
              const Divider(height: 24),
              _SummaryRow(
                icon: Icons.timer_outlined,
                label: 'Duración',
                value: _formatDuration(duration),
              ),
              const Divider(height: 24),
              _SummaryRow(
                icon: _trip!.hasCameraPermission
                    ? Icons.videocam_outlined
                    : Icons.videocam_off_outlined,
                label: 'Monitoreo de cámara',
                value: _trip!.hasCameraPermission ? 'Activo' : 'Sin cámara',
                valueColor: _trip!.hasCameraPermission
                    ? AppColors.success
                    : AppColors.warning,
              ),

              const SizedBox(height: 28),

              // ── Route map ─────────────────────────────────────────────────
              const Text(
                'Ruta recorrida',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 260,
                  child: _buildMap(),
                ),
              ),

              const SizedBox(height: 32),

              // ── Button ────────────────────────────────────────────────────
              ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Volver al inicio',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMap() {
    if (_loadingRoute) {
      return const ColoredBox(
        color: Color(0xFFE8EAF6),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final center = _mapCenter;

    if (_route.isEmpty || center == null) {
      return const ColoredBox(
        color: Color(0xFFE8EAF6),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined,
                  color: AppColors.textSecondary, size: 40),
              SizedBox(height: 8),
              Text(
                'Ruta no disponible\n(GPS sin permisos o sin puntos)',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.bombastik.safedrive',
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: _route,
              color: const Color(0xFF1565C0),
              strokeWidth: 5,
              strokeCap: StrokeCap.round,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            // Start marker (green dot)
            Marker(
              point: _route.first,
              width: 16,
              height: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
            // End marker (red dot)
            Marker(
              point: _route.last,
              width: 20,
              height: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
