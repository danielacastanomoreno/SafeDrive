import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DrowsinessEvent {
  DrowsinessEvent({
    required this.id,
    required this.tripId,
    required this.type,
    required this.status,
    required this.timestamp,
    required this.timestampLabel,
    this.clipPath,
  });

  final String id;
  final String tripId;
  final String type;
  final String status;
  final DateTime timestamp;
  final String timestampLabel;
  final String? clipPath;

  Map<String, dynamic> toJson() => {
        'id': id,
        'tripId': tripId,
        'type': type,
        'status': status,
        'timestamp': timestamp.toIso8601String(),
        'timestampLabel': timestampLabel,
        if (clipPath != null) 'clipPath': clipPath,
      };

  static DrowsinessEvent fromJson(Map<String, dynamic> json) {
    return DrowsinessEvent(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      timestampLabel: json['timestampLabel'] as String,
      clipPath: json['clipPath'] as String?,
    );
  }
}

class DrowsinessEventLogger {
  DrowsinessEventLogger({
    SharedPreferences? sharedPreferences,
    Uuid? uuid,
  })  : _prefs = sharedPreferences,
        _uuid = uuid ?? const Uuid();

  static const String _key = 'drowsiness_events';
  static const int _maxEvents = 200;

  SharedPreferences? _prefs;
  final Uuid _uuid;

  Future<void> logEvent({
    required String tripId,
    required String type,
    required String status,
    required DateTime timestamp,
    String? clipPath,
  }) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final formatter = DateFormat('dd/MM/yyyy HH:mm:ss');
    final event = DrowsinessEvent(
      id: _uuid.v4(),
      tripId: tripId,
      type: type,
      status: status,
      timestamp: timestamp,
      timestampLabel: formatter.format(timestamp),
      clipPath: clipPath,
    );

    final list = prefs.getStringList(_key) ?? <String>[];
    list.add(jsonEncode(event.toJson()));

    if (list.length > _maxEvents) {
      list.removeRange(0, list.length - _maxEvents);
    }

    await prefs.setStringList(_key, list);
  }
}
