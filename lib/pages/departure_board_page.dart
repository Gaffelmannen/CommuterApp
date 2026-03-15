import 'dart:async';

import 'package:flutter/material.dart';

import '../config/train_direction_config.dart';
import '../models/departure_result.dart';
import '../models/site_result.dart';
import '../services/sl_departure_board_service.dart';
import '../settings/app_settings.dart';
import '../settings/wallboard_settings.dart';
import 'wallboard_page.dart';
import '../models/wallboard_filters.dart';

enum _TrainDirection {
  northbound,
  southbound,
  unknown,
}

class DepartureBoardPage extends StatefulWidget {
  const DepartureBoardPage({super.key});

  @override
  State<DepartureBoardPage> createState() => _DepartureBoardPageState();
}

class _DepartureBoardPageState extends State<DepartureBoardPage> {
  final _stationController = TextEditingController();
  final _stationFocusNode = FocusNode();
  final _destinationFilterController = TextEditingController();
  final _routeFilterController = TextEditingController();

  final _service = const SlDepartureBoardService();

  Timer? _debounce;
  Timer? _autoRefreshTimer;
  Timer? _countdownRefreshTimer;

  String _stationQuery = '';
  List<SiteResult> _sites = const [];
  SiteResult? _selectedSite;
  List<DepartureResult> _departures = const [];

  bool _searchingSites = false;
  bool _loadingDepartures = false;
  String? _error;

  final Set<String> _selectedModes = <String>{};
  TrainDirectionFilter _trainDirectionFilter = TrainDirectionFilter.all;

  bool _launchWallboardOnStart = false;
  int? _defaultWallboardSiteId;

  static const Map<String, String> _modeLabels = {
    'BUS': 'Bus',
    'TRAM': 'Tram',
    'METRO': 'Subway',
    'TRAIN': 'Train',
  };

  @override
  void initState() {
    super.initState();

    _stationController.addListener(_handleStationTextChanged);
    _loadSavedWallboardSettings();

    _autoRefreshTimer = Timer.periodic(
      Duration(seconds: AppSettings.departureBoardRefreshSeconds),
      (_) {
        if (!mounted) return;
        final site = _selectedSite;
        if (site != null && !_loadingDepartures) {
          _loadDepartures(site, preserveExisting: true);
        }
      },
    );

    _countdownRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && _selectedSite != null) {
        setState(() {});
      }
    });
  }

  Future<void> _loadSavedWallboardSettings() async {
    final launch = await WallboardSettings.getLaunchWallboardOnStart();
    final saved = await WallboardSettings.getDefaultStation();

    if (!mounted) return;

    setState(() {
      _launchWallboardOnStart = launch;
      _defaultWallboardSiteId = saved.siteId;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _autoRefreshTimer?.cancel();
    _countdownRefreshTimer?.cancel();

    _stationController.removeListener(_handleStationTextChanged);
    _stationController.dispose();
    _stationFocusNode.dispose();
    _destinationFilterController.dispose();
    _routeFilterController.dispose();

    super.dispose();
  }

  void _handleStationTextChanged() {
    final nextQuery = _stationController.text;
    if (nextQuery == _stationQuery) return;

    setState(() {
      _stationQuery = nextQuery;
      _selectedSite = null;
      _departures = const [];
      _error = null;
    });

    _debouncedSearchSites(nextQuery);
  }

  void _debouncedSearchSites(String rawQuery) {
    _debounce?.cancel();

    final query = rawQuery.trim();
    if (query.isEmpty) {
      setState(() {
        _sites = const [];
        _searchingSites = false;
        _error = null;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() {
        _searchingSites = true;
        _error = null;
      });

      try {
        final results = await _service.searchSites(query);

        if (!mounted) return;

        setState(() {
          _sites = results;
        });
      } catch (e) {
        if (!mounted) return;

        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _sites = const [];
        });
      } finally {
        if (!mounted) return;

        setState(() {
          _searchingSites = false;
        });
      }
    });
  }

  Future<void> _selectSite(SiteResult site) async {
    _stationController.value = TextEditingValue(
      text: site.name,
      selection: TextSelection.collapsed(offset: site.name.length),
    );

    _stationFocusNode.unfocus();
    _destinationFilterController.clear();
    _routeFilterController.clear();

    setState(() {
      _selectedSite = site;
      _sites = const [];
      _error = null;
      _selectedModes.clear();
      _trainDirectionFilter = TrainDirectionFilter.all;
    });

    await _loadDepartures(site);
  }

  Future<void> _loadDepartures(
    SiteResult site, {
    bool preserveExisting = false,
  }) async {
    setState(() {
      _loadingDepartures = true;
      _error = null;
      if (!preserveExisting) {
        _departures = const [];
      }
    });

    try {
      final results = await _service.getDepartures(siteId: site.id);

      if (!mounted) return;

      setState(() {
        _departures = results;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _loadingDepartures = false;
      });
    }
  }

  Future<void> _saveCurrentAsDefault() async {
    final site = _selectedSite;
    if (site == null) return;

    await WallboardSettings.saveDefaultStation(
      siteId: site.id,
      siteName: site.name,
    );

    if (!mounted) return;

    setState(() {
      _defaultWallboardSiteId = site.id;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${site.name} saved as wallboard default')),
    );
  }

  Future<void> _clearDefaultWallboard() async {
    await WallboardSettings.clearDefaultStation();

    if (!mounted) return;

    setState(() {
      _defaultWallboardSiteId = null;
      _launchWallboardOnStart = false;
    });

    await WallboardSettings.setLaunchWallboardOnStart(false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Wallboard default cleared')),
    );
  }

  Future<void> _setLaunchWallboardOnStart(bool value) async {
    await WallboardSettings.setLaunchWallboardOnStart(value);

    if (!mounted) return;

    setState(() {
      _launchWallboardOnStart = value;
    });
  }

  void _clearStation() {
    _debounce?.cancel();

    _stationController.clear();
    _destinationFilterController.clear();
    _routeFilterController.clear();

    setState(() {
      _stationQuery = '';
      _sites = const [];
      _selectedSite = null;
      _departures = const [];
      _searchingSites = false;
      _loadingDepartures = false;
      _error = null;
      _selectedModes.clear();
      _trainDirectionFilter = TrainDirectionFilter.all;
    });
  }

  void _toggleMode(String mode) {
    setState(() {
      if (_selectedModes.contains(mode)) {
        _selectedModes.remove(mode);
      } else {
        _selectedModes.add(mode);
      }

      final trainVisible =
          _selectedModes.isEmpty || _selectedModes.contains('TRAIN');
      if (!trainVisible) {
        _trainDirectionFilter = TrainDirectionFilter.all;
      }
    });
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

  List<SiteResult> get _visibleSites {
    final query = _stationQuery.trim();
    if (query.isEmpty) return _sites;

    final normalizedQuery = _normalizeForSearch(query);

    final filtered = _sites.where((site) {
      final normalizedName = _normalizeForSearch(site.name);
      return normalizedName.contains(normalizedQuery) ||
          normalizedName
              .split(' ')
              .any((part) => part.startsWith(normalizedQuery));
    }).toList();

    filtered.sort((a, b) {
      final aName = _normalizeForSearch(a.name);
      final bName = _normalizeForSearch(b.name);

      final aStarts = aName.startsWith(normalizedQuery);
      final bStarts = bName.startsWith(normalizedQuery);

      if (aStarts != bStarts) {
        return aStarts ? -1 : 1;
      }

      final aIndex = aName.indexOf(normalizedQuery);
      final bIndex = bName.indexOf(normalizedQuery);

      if (aIndex != bIndex) {
        return aIndex.compareTo(bIndex);
      }

      return a.name.compareTo(b.name);
    });

    return filtered;
  }

  List<DepartureResult> get _filteredDepartures {
    final destinationFilter =
        _normalizeForSearch(_destinationFilterController.text);
    final routeFilter = _normalizeForSearch(_routeFilterController.text);

    if (destinationFilter.isEmpty &&
        routeFilter.isEmpty &&
        _selectedModes.isEmpty &&
        _trainDirectionFilter == TrainDirectionFilter.all) {
      return _departures;
    }

    return _departures.where((departure) {
      final departureDestination = _normalizeForSearch(departure.destination);
      final departureLine = _normalizeForSearch(departure.line);
      final departureMode = departure.transportMode.trim().toUpperCase();

      final matchesDestination = destinationFilter.isEmpty
          ? true
          : departureDestination.contains(destinationFilter);

      final matchesRoute =
          routeFilter.isEmpty ? true : departureLine.contains(routeFilter);

      final matchesMode = _selectedModes.isEmpty
          ? true
          : _selectedModes.contains(departureMode);

      final matchesTrainDirection = _matchesTrainDirectionFilter(departure);

      return matchesDestination &&
          matchesRoute &&
          matchesMode &&
          matchesTrainDirection;
    }).toList();
  }

  bool _matchesTrainDirectionFilter(DepartureResult departure) {
    if (_trainDirectionFilter == TrainDirectionFilter.all) {
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

    switch (_trainDirectionFilter) {
      case TrainDirectionFilter.all:
        return true;
      case TrainDirectionFilter.northbound:
        return direction == _TrainDirection.northbound;
      case TrainDirectionFilter.southbound:
        return direction == _TrainDirection.southbound;
    }
  }

  bool get _showTrainDirectionFilter {
    return _selectedSite != null &&
        (_selectedModes.isEmpty || _selectedModes.contains('TRAIN'));
  }

  _TrainDirection _classifyTrainDirection({
    required String line,
    required String destination,
  }) {
    final normalizedLine = _normalizeForDirection(line);
    final normalizedDestination = _normalizeForDirection(destination);

    final lineRule = TrainDirectionConfig.lineRules[normalizedLine];
    if (lineRule != null) {
      final northMatch = lineRule.northboundDestinations
          .any(normalizedDestination.contains);
      if (northMatch) return _TrainDirection.northbound;

      final southMatch = lineRule.southboundDestinations
          .any(normalizedDestination.contains);
      if (southMatch) return _TrainDirection.southbound;
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

  String _trainDirectionLabel(TrainDirectionFilter filter) {
    switch (filter) {
      case TrainDirectionFilter.all:
        return 'All trains';
      case TrainDirectionFilter.northbound:
        return 'North / City';
      case TrainDirectionFilter.southbound:
        return 'Southbound';
    }
  }

  Future<void> _openWallboard() async {
  final site = _selectedSite;
  if (site == null) return;

  final filters = WallboardFilters(
    destinationFilter: _destinationFilterController.text,
    routeFilter: _routeFilterController.text,
    selectedModes: Set<String>.from(_selectedModes),
    trainDirectionFilter: _trainDirectionFilter,
  );

  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => WallboardPage(
        site: site,
        initialDepartures:
            _filteredDepartures.take(AppSettings.wallboardMaxItems).toList(),
        filters: filters,
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final filteredDepartures = _filteredDepartures;
    final visibleSites = _visibleSites;
    final showSuggestions =
        _stationQuery.trim().isNotEmpty && _selectedSite == null;
    final selectedIsDefault =
        _selectedSite != null && _selectedSite!.id == _defaultWallboardSiteId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Departure Board'),
        actions: [
          if (_selectedSite != null)
            IconButton(
              tooltip: 'Open wallboard',
              onPressed: _openWallboard,
              icon: const Icon(Icons.fullscreen),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _stationController,
                  focusNode: _stationFocusNode,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.words,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Station',
                    hintText: 'Search station, e.g. Stuvsta',
                    prefixIcon: const Icon(Icons.departure_board),
                    suffixIcon: _searchingSites
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : (_stationController.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: _clearStation,
                                icon: const Icon(Icons.clear),
                              )),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                if (_selectedSite != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Selected: ${_selectedSite!.name}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        ActionChip(
                          label: const Text('Refresh'),
                          onPressed: () => _loadDepartures(_selectedSite!),
                        ),
                        ActionChip(
                          label: Text(
                            selectedIsDefault
                                ? 'Saved as default'
                                : 'Set as wallboard default',
                          ),
                          onPressed: _saveCurrentAsDefault,
                        ),
                        ActionChip(
                          label: const Text('Open wallboard'),
                          onPressed: _openWallboard,
                        ),
                        if (_defaultWallboardSiteId != null)
                          ActionChip(
                            label: const Text('Clear default'),
                            onPressed: _clearDefaultWallboard,
                          ),
                      ],
                    ),
                  ),
                if (_selectedSite != null) ...[
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Launch wallboard on app start'),
                    subtitle: const Text(
                      'Uses the saved default wallboard station',
                    ),
                    value: _launchWallboardOnStart,
                    onChanged: _defaultWallboardSiteId == null
                        ? null
                        : _setLaunchWallboardOnStart,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _destinationFilterController,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Filter by destination',
                            hintText: 'e.g. Stockholm City',
                            prefixIcon: Icon(Icons.place_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _routeFilterController,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Filter by route #',
                            hintText: 'e.g. 40 or 41',
                            prefixIcon:
                                Icon(Icons.confirmation_number_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _modeLabels.entries.map((entry) {
                        final mode = entry.key;
                        final selected = _selectedModes.contains(mode);

                        return FilterChip(
                          label: Text(entry.value),
                          selected: selected,
                          onSelected: (_) => _toggleMode(mode),
                        );
                      }).toList(),
                    ),
                  ),
                  if (_showTrainDirectionFilter) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: TrainDirectionFilter.values.map((filter) {
                          return ChoiceChip(
                            label: Text(_trainDirectionLabel(filter)),
                            selected: _trainDirectionFilter == filter,
                            onSelected: (_) {
                              setState(() {
                                _trainDirectionFilter = filter;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
                if (_selectedSite != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Showing ${filteredDepartures.length} of ${_departures.length} departures',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: showSuggestions
                ? _buildSuggestions(visibleSites)
                : _buildBoard(filteredDepartures),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions(List<SiteResult> sites) {
    if (_searchingSites && sites.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (sites.isEmpty) {
      return Center(
        child: Text('No stations match "${_stationQuery.trim()}"'),
      );
    }

    return Scrollbar(
      thumbVisibility: true,
      child: ListView.separated(
        itemCount: sites.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final site = sites[index];
          return ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: Text(site.name),
            subtitle: Text('Site ID: ${site.id}'),
            onTap: () => _selectSite(site),
          );
        },
      ),
    );
  }

  Widget _buildBoard(List<DepartureResult> departures) {
    if (_selectedSite == null) {
      return const Center(
        child: Text('Search for a station to open its departure board'),
      );
    }

    if (_loadingDepartures && _departures.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_departures.isEmpty) {
      return const Center(
        child: Text('No departures found for this station'),
      );
    }

    if (departures.isEmpty) {
      return const Center(
        child: Text('No departures match the current filters'),
      );
    }

    return Scrollbar(
      thumbVisibility: true,
      child: RefreshIndicator(
        onRefresh: () => _loadDepartures(_selectedSite!),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: departures.length,
          itemBuilder: (context, index) {
            final dep = departures[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CompactDepartureCard(departure: dep),
            );
          },
        ),
      ),
    );
  }
}

class _CompactDepartureCard extends StatelessWidget {
  const _CompactDepartureCard({
    required this.departure,
  });

  final DepartureResult departure;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final planned = departure.scheduledTime;
    final estimated = departure.expectedTime;
    final comparisonTime = estimated ?? planned;
    final delayed =
        planned != null && estimated != null && estimated.isAfter(planned);

    return Card(
      elevation: 2,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 84,
              height: 84,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                departure.line.isEmpty ? '?' : departure.line,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    departure.destination,
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    departure.transportMode,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (departure.stopPoint.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      departure.stopPoint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (planned != null && estimated != null && delayed)
                  Text(
                    '${_formatClock(planned)} → ${_formatClock(estimated)} (+${estimated.difference(planned).inMinutes} min)',
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: scheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                  )
                else if (planned != null)
                  Text(
                    _formatClock(planned),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                if (comparisonTime != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatCountdown(comparisonTime),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: delayed ? scheme.error : null,
                        ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatClock(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String _formatCountdown(DateTime departureTime) {
    final diff = departureTime.difference(DateTime.now());
    if (diff.inSeconds <= 30) return 'Now';
    if (diff.inMinutes < 1) return '<1 min';
    return '${diff.inMinutes} min';
  }
}