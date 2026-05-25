import 'package:equatable/equatable.dart';

import '../../domain/entities/video_clip_entity.dart';

abstract class DriverClipsEvent extends Equatable {
  const DriverClipsEvent();

  @override
  List<Object?> get props => [];
}

class DriverClipsPageOpened extends DriverClipsEvent {
  final String driverId;

  const DriverClipsPageOpened({required this.driverId});

  @override
  List<Object?> get props => [driverId];
}

class DriverClipsLoadMoreRequested extends DriverClipsEvent {
  const DriverClipsLoadMoreRequested();
}

class DriverClipsRetryRequested extends DriverClipsEvent {
  const DriverClipsRetryRequested();
}

class DriverClipTapped extends DriverClipsEvent {
  final VideoClipEntity clip;

  const DriverClipTapped({required this.clip});

  @override
  List<Object?> get props => [clip];
}

/// Solo disponible en kDebugMode — inyecta clips ficticios sin tocar Storage.
class DriverClipsSeedMockRequested extends DriverClipsEvent {
  const DriverClipsSeedMockRequested();
}
