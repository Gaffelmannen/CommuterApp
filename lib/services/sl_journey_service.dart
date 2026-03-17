import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/journey_result.dart';

class SlJourneyService {
  const SlJourneyService();

  static const String _baseUrlJourneyPlanner =
      'https://journeyplanner.integration.sl.se/v2';

  Future<List<JourneyResult>> lookupJourneys({
    required String stationOrigin,
    required String stationDestination,
    int numberOfTrips = 6,
  }) async {
    final originId = await _findStopId(stationOrigin);
    final destinationId = await _findStopId(stationDestination);

    if (originId == null || destinationId == null) {
      throw Exception('Could not find one or both stations.');
    }

    final now = DateTime.now();
    final journeys = await _getTrips(
      originId: originId,
      destinationId: destinationId,
      journeyTime: now,
      numberOfTrips: numberOfTrips,
    );

    return journeys
        .map((json) => JourneyResult.fromJson(json))
        .where((journey) =>
            journey.origin.isNotEmpty || journey.destination.isNotEmpty)
        .toList();
  }

  Future<String?> _findStopId(String name) async {
    final uri = Uri.parse('$_baseUrlJourneyPlanner/stop-finder').replace(
      queryParameters: {
        'name_sf': name,
        'type_sf': 'any',
        'any_obj_filter_sf': '2',
      },
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception(
        'Stop lookup failed (${response.statusCode}): ${response.body}',
      );
    }

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;
    final locations = (data['locations'] as List?) ?? const [];

    if (locations.isEmpty) {
      return null;
    }

    final first = locations.first as Map<String, dynamic>;
    return first['id']?.toString();
  }

  Future<List<Map<String, dynamic>>> _getTrips({
    required String originId,
    required String destinationId,
    required DateTime journeyTime,
    required int numberOfTrips,
  }) async {
    final uri = Uri.parse('$_baseUrlJourneyPlanner/trips').replace(
      queryParameters: {
        'type_origin': 'any',
        'name_origin': originId,
        'type_destination': 'any',
        'name_destination': destinationId,
        'calc_number_of_trips': numberOfTrips.toString(),
        'itd_date': _formatDate(journeyTime),
        'itd_time': _formatTime(journeyTime),
        'itd_trip_date_time_dep_arr': 'dep',
        'calc_one_direction': 'true',
      },
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception(
        'Trip lookup failed (${response.statusCode}): ${response.body}',
      );
    }

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;

    final journeys = data['journeys'];
    if (journeys is! List) {
      return const [];
    }

    return journeys
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  String _formatDate(DateTime dt) {
    final year = dt.year.toString().padLeft(4, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$year$month$day';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour$minute';
  }
}