import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../config/train_direction_config.dart';
import '../models/departure_result.dart';
import '../models/site_result.dart';
import '../models/wallboard_filters.dart';
import '../services/sl_departure_board_service.dart';
import '../settings/app_settings.dart';
import '../widgets/wallboard_view.dart';

class WallboardPage extends StatefulWidget {
  const WallboardPage({
    super.key,
    required this.site,
    required this.initialDepartures,
    required this.filters,
  });

  final SiteResult site;
  final List<DepartureResult> initialDepartures;
  final WallboardFilters filters;

  @override
  State<WallboardPage> createState() => _WallboardPageState();
}

class _WallboardPageState extends State<WallboardPage> {
  final _service = const SlDepartureBoardService();

  Timer? _refreshTimer;
  Timer? _repaintTimer;
  Timer? _controlsTimer;

  late List<DepartureResult> _departures;
  DateTime? _lastUpdated;

  bool _fullscreen = AppSettings.wallboardStartInFullscreen;
  bool _kioskMode = AppSettings.wallboardStartInKioskMode;
  bool _loading = false;
  bool _showControls = true;
  String? _error;

  static const Duration _controlsVisibleDuration = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();

    _departures = _applyFilters(widget.initialDepartures);
    _lastUpdated = DateTime.now();

    _applyDisplayMode();
    _scheduleControlsHide();

    _refreshTimer = Timer.periodic(
      Duration(seconds: AppSettings.departureBoardRefreshSeconds),
      (_) => _refresh(),
    );

    _repaintTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _repaintTimer?.cancel();
    _controlsTimer?.cancel();
    _restoreDisplayMode();
    super.dispose();
  }

  Future<void> _applyDisplayMode() async {
    await WakelockPlus.enable();

    if (_fullscreen || _kioskMode) {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
      );
    } else {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
      );
    }

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _restoreDisplayMode() async {
    await WakelockPlus.disable();
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }

  void _scheduleControlsHide() {
    _controlsTimer?.cancel();

    if (!_fullscreen && !_kioskMode) {
      return;
    }

    _controlsTimer = Timer(_controlsVisibleDuration, () {
      if (!mounted) return;
      setState(() {
        _showControls = false;
      });
    });
  }

  void _showControlsTemporarily() {
    setState(() {
      _showControls = true;
    });
    _scheduleControlsHide();
  }

  Future<void> _refresh() async {
    if (_loading) return;

    _showControlsTemporarily();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await _service.getDepartures(siteId: widget.site.id);
      final filtered = _applyFilters(results);

      if (!mounted) return;

      setState(() {
        _departures = filtered.take(AppSettings.wallboardMaxItems).toList();
        _lastUpdated = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      _scheduleControlsHide();
    }
  }

  Future<void> _toggleFullscreen() async {
    setState(() {
      _fullscreen = !_fullscreen;
      _showControls = true;
    });

    await _applyDisplayMode();

    if (_fullscreen || _kioskMode) {
      _scheduleControlsHide();
    } else {
      _controlsTimer?.cancel();
    }
  }

  Future<void> _toggleKioskMode() async {
    setState(() {
      _kioskMode = !_kioskMode;
      _showControls = true;
    });

    await _applyDisplayMode();

    if (_fullscreen || _kioskMode) {
      _scheduleControlsHide();
    } else {
      _controlsTimer?.cancel();
    }
  }

  String _normalizeForSearch(String input) {
    return input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _normalizeForDirection(String input) {
    return _normalizeForSearch(input)
        .replaceAll('å', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('ö', 'o');
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

  bool _matchesTrainDirectionFilter(DepartureResult departure) {
    if (widget.filters.trainDirectionFilter == TrainDirectionFilter.all) {
      return true;
    }

    final mode = departure.transportMode.trim().toUpperCase();
    if (mode != 'TRAIN') {
      return false;
    }

    final direction = _classifyTrainDirection(
      line: departure.line,
      destination: departure.destination,
    );

    switch (widget.filters.trainDirectionFilter) {
      case TrainDirectionFilter.all:
        return true;
      case TrainDirectionFilter.northbound:
        return direction == _TrainDirection.northbound;
      case TrainDirectionFilter.southbound:
        return direction == _TrainDirection.southbound;
    }
  }

  List<DepartureResult> _applyFilters(List<DepartureResult> source) {
    final destinationFilter =
        _normalizeForSearch(widget.filters.destinationFilter);
    final routeFilter = _normalizeForSearch(widget.filters.routeFilter);
    final selectedModes = widget.filters.selectedModes;

    if (destinationFilter.isEmpty &&
        routeFilter.isEmpty &&
        selectedModes.isEmpty &&
        widget.filters.trainDirectionFilter == TrainDirectionFilter.all) {
      return source;
    }

    return source.where((departure) {
      final departureDestination = _normalizeForSearch(departure.destination);
      final departureLine = _normalizeForSearch(departure.line);
      final departureMode = departure.transportMode.trim().toUpperCase();

      final matchesDestination = destinationFilter.isEmpty
          ? true
          : departureDestination.contains(destinationFilter);

      final matchesRoute =
          routeFilter.isEmpty ? true : departureLine.contains(routeFilter);

      final matchesMode =
          selectedModes.isEmpty ? true : selectedModes.contains(departureMode);

      final matchesTrainDirection = _matchesTrainDirectionFilter(departure);

      return matchesDestination &&
          matchesRoute &&
          matchesMode &&
          matchesTrainDirection;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visibleDepartures =
        _departures.take(AppSettings.wallboardMaxItems).toList();

    return PopScope(
      canPop: !_kioskMode,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _showControlsTemporarily,
          child: Stack(
            children: [
              Positioned.fill(
                child: WallboardView(
                  stationName: widget.site.name,
                  departures: visibleDepartures,
                  lastUpdated: _lastUpdated,
                  showLeaveBanner: _kioskMode,
                  walkMinutes: AppSettings.wallboardWalkMinutes,
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _showControls ? 1 : 0,
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: SafeArea(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 18, right: 18),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_error != null)
                              Container(
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _error!,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            IconButton.filledTonal(
                              tooltip: 'Refresh',
                              onPressed: _refresh,
                              icon: _loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.refresh),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              tooltip: _fullscreen
                                  ? 'Exit fullscreen'
                                  : 'Enter fullscreen',
                              onPressed: _toggleFullscreen,
                              icon: Icon(
                                _fullscreen
                                    ? Icons.fullscreen_exit
                                    : Icons.fullscreen,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              tooltip: _kioskMode
                                  ? 'Disable kiosk mode'
                                  : 'Enable kiosk mode',
                              onPressed: _toggleKioskMode,
                              icon: Icon(
                                _kioskMode ? Icons.lock : Icons.lock_open,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (!_kioskMode)
                              IconButton.filledTonal(
                                tooltip: 'Close',
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_kioskMode && _showControls)
                SafeArea(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Text(
                        'Kiosk mode active',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _TrainDirection {
  northbound,
  southbound,
  unknown,
}