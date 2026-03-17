import 'package:flutter/material.dart';

import '../config/train_direction_config.dart';
import '../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final sortedDepartures = [...departures]..sort(_compareDepartures);
    final grouped = _buildGroups(sortedDepartures, l10n);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final nextConnection = _nextReachableDeparture(
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
                      l10n.wallboardUpdated(_formatClock(lastUpdated!)),
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
                  ? Center(
                      child: Text(
                        l10n.noDepartures,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 28,
                        ),
                      ),
                    )
                  : isLandscape
                      ? _LandscapeGroups(
                          groups: grouped,
                          walkMinutes: walkMinutes,
                          showLeaveState: showLeaveBanner,
                        )
                      : _PortraitGroups(
                          groups: grouped,
                          walkMinutes: walkMinutes,
                          showLeaveState: showLeaveBanner,
                        ),
            ),
          ],
        ),
      ),
    );
  }

  DepartureResult? _nextReachableDeparture(
    List<DepartureResult> source,
    int walkMinutes,
  ) {
    final now = DateTime.now();

    for (final departure in source) {
      final departureTime = departure.expectedTime ?? departure.scheduledTime;
      if (departureTime == null) continue;
      if (!departureTime.isAfter(now)) continue;

      final leaveByTime =
          departureTime.subtract(Duration(minutes: walkMinutes));

      if (!leaveByTime.isBefore(now)) {
        return departure;
      }
    }

    return null;
  }

  List<_WallboardGroup> _buildGroups(
    List<DepartureResult> source,
    AppLocalizations l10n,
  ) {
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
      groups.add(_WallboardGroup(title: l10n.northCityGroup, departures: north));
    }
    if (south.isNotEmpty) {
      groups.add(
        _WallboardGroup(title: l10n.southboundGroup, departures: south),
      );
    }
    if (other.isNotEmpty) {
      groups.add(_WallboardGroup(title: l10n.otherGroup, departures: other));
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
    final l10n = AppLocalizations.of(context)!;

    if (departure == null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.redAccent),
        ),
        child: Text(
          l10n.noReachableDepartures,
          style: const TextStyle(
            color: Colors.redAccent,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
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
      headline = l10n.leaveNowToMakeNextConnection;
      accentColor = Colors.redAccent;
      borderColor = Colors.redAccent;
      backgroundColor = Colors.redAccent.withOpacity(0.18);
    } else {
      headline = l10n.leaveInToMakeNextConnection(
        _formatRemainingMinutes(l10n, timeUntilLeave),
      );
      accentColor = const Color(0xFFFFD54F);
      borderColor = const Color(0x66FFD54F);
      backgroundColor = const Color(0x22FFD54F);
    }

    final linePrefix =
        departure!.line.isEmpty ? '' : l10n.linePrefix(departure!.line);

    final details = l10n.leaveByDepartsLineDestination(
      _formatClock(leaveByTime),
      _formatClock(departureTime),
      linePrefix,
      departure!.destination,
    );

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

  static String _formatRemainingMinutes(
    AppLocalizations l10n,
    Duration duration,
  ) {
    if (duration.inSeconds <= 30) return l10n.now.toLowerCase();
    final minutes = (duration.inSeconds / 60).ceil();
    return l10n.minutesShort(minutes.toString());
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
    required this.walkMinutes,
    required this.showLeaveState,
  });

  final List<_WallboardGroup> groups;
  final int walkMinutes;
  final bool showLeaveState;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: groups
          .map(
            (group) => Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _WallboardSection(
                group: group,
                walkMinutes: walkMinutes,
                showLeaveState: showLeaveState,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _LandscapeGroups extends StatelessWidget {
  const _LandscapeGroups({
    required this.groups,
    required this.walkMinutes,
    required this.showLeaveState,
  });

  final List<_WallboardGroup> groups;
  final int walkMinutes;
  final bool showLeaveState;

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
                      child: _WallboardSection(
                        group: group,
                        walkMinutes: walkMinutes,
                        showLeaveState: showLeaveState,
                      ),
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
                      child: _WallboardSection(
                        group: group,
                        walkMinutes: walkMinutes,
                        showLeaveState: showLeaveState,
                      ),
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
    required this.walkMinutes,
    required this.showLeaveState,
  });

  final _WallboardGroup group;
  final int walkMinutes;
  final bool showLeaveState;

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
              walkMinutes: walkMinutes,
              showLeaveState: showLeaveState,
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
    required this.walkMinutes,
    required this.showLeaveState,
  });

  final DepartureResult departure;
  final bool isPrimary;
  final int walkMinutes;
  final bool showLeaveState;

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final planned = departure.scheduledTime;
    final estimated = departure.expectedTime;
    final delayed =
        planned != null && estimated != null && estimated.isAfter(planned);
    final comparisonTime = estimated ?? planned;

    final reachable = _isReachable(departure, walkMinutes);
    final dimmed = showLeaveState && !reachable;

    final borderColor = isPrimary
        ? const Color(0xFFFFD54F)
        : Colors.white12;
    final backgroundColor =
        isPrimary ? const Color(0xFF151515) : const Color(0xFF111111);

    return Opacity(
      opacity: dimmed ? 0.38 : 1,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isPrimary ? 22 : 20,
          vertical: isPrimary ? 20 : 16,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: dimmed ? Colors.white24 : borderColor,
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
                showTooLate: dimmed,
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
      ),
    );
  }

  static bool _isReachable(DepartureResult departure, int walkMinutes) {
    final departureTime = departure.expectedTime ?? departure.scheduledTime;
    if (departureTime == null) return false;

    final leaveByTime =
        departureTime.subtract(Duration(minutes: walkMinutes));
    final now = DateTime.now();
    return !leaveByTime.isBefore(now);
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
    required this.showTooLate,
  });

  final DepartureResult departure;
  final bool isPrimary;
  final bool isLandscape;
  final bool showTooLate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final subtitle = departure.stopPoint.isNotEmpty
        ? departure.stopPoint
        : _transportLabel(l10n, departure.transportMode);

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
        Row(
          children: [
            Expanded(
              child: Text(
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
            ),
            if (showTooLate) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: Text(
                  l10n.tooLate,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  static String _transportLabel(AppLocalizations l10n, String value) {
    switch (value.trim().toUpperCase()) {
      case 'BUS':
        return l10n.bus;
      case 'TRAM':
        return l10n.tram;
      case 'METRO':
        return l10n.subway;
      case 'TRAIN':
        return l10n.train;
      default:
        return value;
    }
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
    final l10n = AppLocalizations.of(context)!;
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
                  _countdown(l10n, comparisonTime!),
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

  static String _countdown(AppLocalizations l10n, DateTime departureTime) {
    final diff = departureTime.difference(DateTime.now());
    if (diff.inSeconds <= 30) return l10n.now;
    if (diff.inMinutes < 1) return l10n.lessThanOneMinute;
    return l10n.minutesShort(diff.inMinutes.toString());
  }
}