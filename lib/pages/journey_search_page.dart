import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/journey_result.dart';
import '../services/sl_journey_service.dart';
import '../widgets/journey_card.dart';

class JourneySearchPage extends StatefulWidget {
  const JourneySearchPage({super.key});

  @override
  State<JourneySearchPage> createState() => _JourneySearchPageState();
}

class _JourneySearchPageState extends State<JourneySearchPage> {
  final _originController = TextEditingController(text: 'Södra Station');
  final _destinationController = TextEditingController(text: 'Stuvsta');
  final _service = const SlJourneyService();

  bool _loading = false;
  String? _error;
  List<JourneyResult> _journeys = const [];

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _searchJourneys() async {
    final l10n = AppLocalizations.of(context)!;

    FocusScope.of(context).unfocus();

    final originName = _originController.text.trim();
    final destinationName = _destinationController.text.trim();

    if (originName.isEmpty || destinationName.isEmpty) {
      setState(() {
        _error = l10n.journeyEnterBothOriginAndDestination;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _journeys = const [];
    });

    try {
      final journeys = await _service.lookupJourneys(
        stationOrigin: originName,
        stationDestination: destinationName,
      );

      setState(() {
        _journeys = journeys;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _swapStations() {
    final from = _originController.text;
    final to = _destinationController.text;
    _originController.text = to;
    _destinationController.text = from;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _originController,
                    decoration: InputDecoration(
                      labelText: l10n.journeyFrom,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.trip_origin),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _destinationController,
                          decoration: InputDecoration(
                            labelText: l10n.journeyTo,
                            border: const OutlineInputBorder(),
                            prefixIcon:
                                const Icon(Icons.location_on_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filledTonal(
                        onPressed: _swapStations,
                        icon: const Icon(Icons.swap_vert),
                        tooltip: l10n.journeySwapStations,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _searchJourneys,
                      icon: const Icon(Icons.search),
                      label: Text(
                        _loading
                            ? l10n.journeySearching
                            : l10n.journeySearchJourneys,
                      ),
                    ),
                  ),
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
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _journeys.isEmpty
                      ? const _EmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _journeys.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final journey = _journeys[index];
                            return JourneyCard(
                              journey: journey,
                              index: index + 1,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_transit,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.journeyEmptyTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.journeyEmptyBody,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}