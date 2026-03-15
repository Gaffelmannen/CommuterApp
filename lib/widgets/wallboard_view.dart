import 'package:flutter/material.dart';

import '../config/train_direction_config.dart';
import '../models/departure_result.dart';

class WallboardView extends StatelessWidget {
  const WallboardView({
    super.key,
    required this.stationName,
    required this.departures,
    required this.lastUpdated,
    required this.showLeaveBanner,
    required this.walkMinutes,
  });

  final String stationName;
  final List<DepartureResult> departures;
  final DateTime? lastUpdated;
  final bool showLeaveBanner;
  final int walkMinutes;

  @override
  Widget build(BuildContext context) {
    final sortedDepartures = [...departures]..sort(_compareDepartures);
    final grouped = _buildGroups(sortedDepartures);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final nextConnection = _nextUpcomingDeparture(
      sortedDepartures,
      walkMinutes,
    );

    return Container(
      color: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            if (showLeaveBanner)
              _LeaveBanner(
                departure: nextConnection,
                walkMinutes: walkMinutes,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      stationName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isLandscape ? 38 : 34,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (lastUpdated != null)
                    Text(
                      'Updated ${_formatClock(lastUpdated!)}',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: isLandscape ? 18 : 16,
                      ),
                    ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Divider(color: Colors.white24, height: 1),
            ),
            Expanded(
              child: grouped.isEmpty
                  ? const Center(
                      child: Text(
                        'No departures',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 28,
                        ),
                      ),
                    )
                  : isLandscape
                      ? _LandscapeGroups(groups: grouped)
                      : _PortraitGroups(groups: grouped),
            ),
          ],
        ),
      ),
    );
  }

  DepartureResult? _nextUpcomingDeparture(
    List<DepartureResult> source,
    int walkMinutes,
  ) {
    final now = DateTime.now();
    DepartureResult? fallbackFutureDeparture;

    for (final departure in source) {
      final departureTime = departure.expectedTime ?? departure.scheduledTime;
      if (departureTime == null) continue;
      if (!departureTime.isAfter(now)) continue;

      fallbackFutureDeparture ??= departure;

      final leaveByTime =
          departureTime.subtract(Duration(minutes: walkMinutes));

      if (leaveByTime.isAfter(now) || leaveByTime.isAtSameMomentAs(now)) {
        return departure;
      }
    }

    return fallbackFutureDeparture;
  }

  List<_WallboardGroup> _buildGroups(List<DepartureResult> source) {
    final north = <DepartureResult>[];
    final south = <DepartureResult>[];
    final other = <DepartureResult>[];

    for (final departure in source) {
      final mode = departure.transportMode.trim().toUpperCase();

      if (mode == 'TRAIN') {
        switch (_classifyTrainDirection(
          line: departure.line,
          destination: departure.destination,
        )) {
          case _TrainDirection.northbound:
            north.add(departure);
            break;
          case _TrainDirection.southbound:
            south.add(departure);
            break;
          case _TrainDirection.unknown:
            other.add(departure);
            break;
        }
      } else {
        other.add(departure);
      }
    }

    final groups = <_WallboardGroup>[];

    if (north.isNotEmpty) {
      groups.add(_WallboardGroup(title: 'North / City', departures: north));
    }
    if (south.isNotEmpty) {
      groups.add(_WallboardGroup(title: 'Southbound', departures: south));
    }
    if (other.isNotEmpty) {
      groups.add(_WallboardGroup(title: 'Other', departures: other));
    }

    return groups;
  }

  static int _compareDepartures(DepartureResult a, DepartureResult b) {
    final aTime = a.expectedTime ?? a.scheduledTime;
    final bTime = b.expectedTime ?? b.scheduledTime;

    if (aTime == null && bTime == null) return 0;
    if (aTime == null) return 1;
    if (bTime == null) return -1;
    return aTime.compareTo(bTime);
  }

  _TrainDirection _classifyTrainDirection({
    required String line,
    required String destination,
  }) {
    final normalizedLine = _normalizeForDirection(line);
    final normalizedDestination = _normalizeForDirection(destination);

    final lineRule = TrainDirectionConfig.lineRules[normalizedLine];
    if (lineRule != null) {
      if (lineRule.northboundDestinations.any(normalizedDestination.contains)) {
        return _TrainDirection.northbound;
      }
      if (lineRule.southboundDestinations.any(normalizedDestination.contains)) {
        return _TrainDirection.southbound;
      }
    }

    if (TrainDirectionConfig.northboundDestinations
        .any(normalizedDestination.contains)) {
      return _TrainDirection.northbound;
    }

    if (TrainDirectionConfig.southboundDestinations
        .any(normalizedDestination.contains)) {
      return _TrainDirection.southbound;
    }

    return _TrainDirection.unknown;
  }

  String _normalizeForDirection(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('å', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('ö', 'o');
  }

  static String _formatClock(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _LeaveBanner extends StatelessWidget {
  const _LeaveBanner({
    required this.departure,
    required this.walkMinutes,
  });

  final DepartureResult? departure;
  final int walkMinutes;

  @override
  Widget build(BuildContext context) {
    if (departure == null) {
      return const SizedBox.shrink();
    }

    final departureTime = departure!.expectedTime ?? departure!.scheduledTime;
    if (departureTime == null) {
      return const SizedBox.shrink();
    }

    final leaveByTime =
        departureTime.subtract(Duration(minutes: walkMinutes));
    final now = DateTime.now();
    final timeUntilLeave = leaveByTime.difference(now);
    final secondsUntilLeave = timeUntilLeave.inSeconds;

    late final String headline;
    late final Color accentColor;
    late final Color borderColor;
    late final Color backgroundColor;

    if (secondsUntilLeave <= 30) {
      headline = 'Leave now to make the next connection';
      accentColor = Colors.redAccent;
      borderColor = Colors.redAccent;
      backgroundColor = Colors.redAccent.withOpacity(0.18);
    } else {
      headline =
          'Leave in ${_formatRemainingMinutes(timeUntilLeave)} to make the next connection';
      accentColor = const Color(0xFFFFD54F);
      borderColor = const Color(0x66FFD54F);
      backgroundColor = const Color(0x22FFD54F);
    }

    final linePrefix =
        departure!.line.isEmpty ? '' : 'Line ${departure!.line} • ';

    final details =
        'Leave by ${_formatClock(leaveByTime)} • '
        'Departs ${_formatClock(departureTime)} • '
        '$linePrefix${departure!.destination}';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headline,
            style: TextStyle(
              color: accentColor,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            details,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatClock(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String _formatRemainingMinutes(Duration duration) {
    if (duration.inSeconds <= 30) {
      return 'now';
    }
    final minutes = (duration.inSeconds / 60).ceil();
    return '$minutes min';
  }
}

enum _TrainDirection {
  northbound,
  southbound,
  unknown,
}

class _WallboardGroup {
  const _WallboardGroup({
    required this.title,
    required this.departures,
  });

  final String title;
  final List<DepartureResult> departures;
}

class _PortraitGroups extends StatelessWidget {
  const _PortraitGroups({
    required this.groups,
  });

  final List<_WallboardGroup> groups;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: groups
          .map(
            (group) => Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _WallboardSection(group: group),
            ),
          )
          .toList(),
    );
  }
}

class _LandscapeGroups extends StatelessWidget {
  const _LandscapeGroups({
    required this.groups,
  });

  final List<_WallboardGroup> groups;

  @override
  Widget build(BuildContext context) {
    final left = <_WallboardGroup>[];
    final right = <_WallboardGroup>[];

    for (var i = 0; i < groups.length; i++) {
      if (i.isEven) {
        left.add(groups[i]);
      } else {
        right.add(groups[i]);
      }
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView(
              children: left
                  .map(
                    (group) => Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: _WallboardSection(group: group),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: ListView(
              children: right
                  .map(
                    (group) => Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: _WallboardSection(group: group),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _WallboardSection extends StatelessWidget {
  const _WallboardSection({
    required this.group,
  });

  final _WallboardGroup group;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          group.title,
          style: const TextStyle(
            color: Color(0xFFFFD54F),
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(group.departures.length, (index) {
          final departure = group.departures[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _WallboardRow(
              departure: departure,
              isPrimary: index == 0,
            ),
          );
        }),
      ],
    );
  }
}

class _WallboardRow extends StatelessWidget {
  const _WallboardRow({
    required this.departure,
    required this.isPrimary,
  });

  final DepartureResult departure;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final planned = departure.scheduledTime;
    final estimated = departure.expectedTime;
    final delayed =
        planned != null && estimated != null && estimated.isAfter(planned);
    final comparisonTime = estimated ?? planned;

    final borderColor =
        isPrimary ? const Color(0xFFFFD54F) : Colors.white12;
    final backgroundColor =
        isPrimary ? const Color(0xFF151515) : const Color(0xFF111111);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isPrimary ? 22 : 20,
        vertical: isPrimary ? 20 : 16,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
          width: isPrimary ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _LineBadge(
            line: departure.line,
            isPrimary: isPrimary,
            isLandscape: isLandscape,
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 7,
            child: _DestinationBlock(
              departure: departure,
              isPrimary: isPrimary,
              isLandscape: isLandscape,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            flex: 3,
            child: _TimeBlock(
              planned: planned,
              estimated: estimated,
              comparisonTime: comparisonTime,
              delayed: delayed,
              isPrimary: isPrimary,
              isLandscape: isLandscape,
            ),
          ),
        ],
      ),
    );
  }
}

class _LineBadge extends StatelessWidget {
  const _LineBadge({
    required this.line,
    required this.isPrimary,
    required this.isLandscape,
  });

  final String line;
  final bool isPrimary;
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    final size = isPrimary
        ? (isLandscape ? 72.0 : 92.0)
        : (isLandscape ? 66.0 : 82.0);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0x22FFD54F) : Colors.white10,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        line.isEmpty ? '?' : line,
        style: TextStyle(
          color: Colors.white,
          fontSize: isPrimary
              ? (isLandscape ? 30 : 40)
              : (isLandscape ? 26 : 32),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DestinationBlock extends StatelessWidget {
  const _DestinationBlock({
    required this.departure,
    required this.isPrimary,
    required this.isLandscape,
  });

  final DepartureResult departure;
  final bool isPrimary;
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    final subtitle = departure.stopPoint.isNotEmpty
        ? departure.stopPoint
        : departure.transportMode;

    final destinationFont = _destinationFontSize(
      departure.destination,
      isPrimary: isPrimary,
      isLandscape: isLandscape,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          departure.destination,
          maxLines: 2,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: destinationFont,
            height: 1.06,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white70,
            fontSize: isPrimary
                ? (isLandscape ? 14 : 18)
                : (isLandscape ? 13 : 16),
          ),
        ),
      ],
    );
  }

  double _destinationFontSize(
    String destination, {
    required bool isPrimary,
    required bool isLandscape,
  }) {
    final length = destination.trim().length;

    if (isLandscape) {
      if (length <= 8) return isPrimary ? 30 : 24;
      if (length <= 12) return isPrimary ? 27 : 22;
      if (length <= 18) return isPrimary ? 24 : 20;
      if (length <= 24) return isPrimary ? 22 : 18;
      return isPrimary ? 20 : 17;
    }

    if (length <= 10) return isPrimary ? 32 : 26;
    if (length <= 16) return isPrimary ? 28 : 24;
    return isPrimary ? 24 : 20;
  }
}

class _TimeBlock extends StatelessWidget {
  const _TimeBlock({
    required this.planned,
    required this.estimated,
    required this.comparisonTime,
    required this.delayed,
    required this.isPrimary,
    required this.isLandscape,
  });

  final DateTime? planned;
  final DateTime? estimated;
  final DateTime? comparisonTime;
  final bool delayed;
  final bool isPrimary;
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    final clockSize = isPrimary
        ? (isLandscape ? 25.0 : 38.0)
        : (isLandscape ? 22.0 : 32.0);
    final countdownSize = isPrimary
        ? (isLandscape ? 20.0 : 28.0)
        : (isLandscape ? 17.0 : 22.0);
    final delaySize = isPrimary
        ? (isLandscape ? 14.0 : 21.0)
        : (isLandscape ? 13.0 : 19.0);

    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (planned != null && estimated != null && delayed)
            SizedBox(
              height: isLandscape ? 34 : 48,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  isLandscape
                      ? '${_formatClock(planned!)}→${_formatClock(estimated!)}'
                      : '${_formatClock(planned!)} → ${_formatClock(estimated!)} (+${estimated!.difference(planned!).inMinutes} min)',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: delaySize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else if (planned != null)
            SizedBox(
              height: isLandscape ? 36 : 48,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  _formatClock(planned!),
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: clockSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          if (comparisonTime != null) ...[
            const SizedBox(height: 4),
            SizedBox(
              height: isLandscape ? 28 : 36,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  _countdown(comparisonTime!),
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color:
                        delayed ? Colors.redAccent : const Color(0xFFFFD54F),
                    fontSize: countdownSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatClock(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String _countdown(DateTime departureTime) {
    final diff = departureTime.difference(DateTime.now());

    if (diff.inSeconds <= 30) return 'Now';
    if (diff.inMinutes < 1) return '<1 min';
    return '${diff.inMinutes} min';
  }
}