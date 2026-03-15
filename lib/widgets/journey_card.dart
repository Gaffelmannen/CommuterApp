import 'package:flutter/material.dart';

import '../models/journey_result.dart';

class JourneyCard extends StatelessWidget {
  const JourneyCard({
    super.key,
    required this.journey,
    required this.index,
  });

  final JourneyResult journey;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Journey #$index',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(
                    journey.lineNumber.isEmpty ? 'Unknown line' : journey.lineNumber,
                  ),
                ),
                Chip(label: Text('Stops: ${journey.numberOfStops}')),
                Chip(label: Text('Duration: ${journey.durationLabel}')),
              ],
            ),
            const SizedBox(height: 12),
            _TimeRow(
              station: journey.departureName,
              planned: journey.departurePlanned,
              estimated: journey.departureEstimated,
              icon: Icons.login,
            ),
            const SizedBox(height: 8),
            _TimeRow(
              station: journey.arrivalName,
              planned: journey.arrivalPlanned,
              estimated: journey.arrivalEstimated,
              icon: Icons.logout,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.station,
    required this.planned,
    required this.estimated,
    required this.icon,
  });

  final String station;
  final String planned;
  final String estimated;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final delayed = planned != estimated;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                station,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 2),
              Text(
                delayed
                    ? 'Planned: $planned   Estimated: $estimated'
                    : 'Time: $planned',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
