import 'package:flutter/material.dart';
import '../models/brahma_muhurta_time.dart';
import '../services/calculation_service.dart';
import 'package:intl/intl.dart';

class BrahmaMuhurtaCard extends StatelessWidget {
  final BrahmaMuhurtaTime brahmaMuhurta;
  final bool isActive;
  final bool isToday;

  const BrahmaMuhurtaCard({
    super.key,
    required this.brahmaMuhurta,
    required this.isActive,
    this.isToday = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      color: isActive && isToday
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isActive && isToday ? Icons.self_improvement : Icons.schedule,
                  size: 32,
                  color: isActive && isToday
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onTertiaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  _getCardTitle(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isActive && isToday
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onTertiaryContainer,
                      ),
                ),
              ],
            ),

            if (isActive && isToday) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ACTIVE NOW',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Time Cards
            Row(
              children: [
                Expanded(
                  child: _TimeCard(
                    label: 'Starts at',
                    time: brahmaMuhurta.startTime,
                    color: Theme.of(context).colorScheme.primary,
                    isPrimary: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _TimeCard(
                    label: 'Ends at',
                    time: brahmaMuhurta.endTime,
                    color: Theme.of(context).colorScheme.secondary,
                    isPrimary: false,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Duration and Sunrise Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '48 minutes',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            'Duration',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.2),
                      ),
                      Column(
                        children: [
                          Icon(
                            Icons.wb_sunny_outlined,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            brahmaMuhurta.sunriseTime,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            'Sunrise',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Status Text
            if (isToday)
              Text(
                _getStatusText(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isActive
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                textAlign: TextAlign.center,
              ),

            // For non-today dates, show the date
            if (!isToday)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceVariant
                      .withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Session for ${DateFormat('MMM dd, yyyy').format(brahmaMuhurta.startDateTime)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getCardTitle() {
    if (isActive && isToday) {
      return 'Brahma Muhurta Active';
    } else if (isToday) {
      return 'Brahma Muhurta';
    } else {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final yesterday = DateTime(now.year, now.month, now.day - 1);

      if (DateUtils.isSameDay(brahmaMuhurta.startDateTime, tomorrow)) {
        return 'Brahma Muhurta';
      } else if (DateUtils.isSameDay(brahmaMuhurta.startDateTime, yesterday)) {
        return 'Brahma Muhurta';
      } else {
        return 'Brahma Muhurta';
      }
    }
  }

  String _getStatusText() {
    if (!isToday) {
      return 'Session time: ${brahmaMuhurta.startTime} - ${brahmaMuhurta.endTime}';
    }

    if (isActive) {
      final remaining = brahmaMuhurta.timeRemaining;
      if (remaining != null) {
        return 'Ends in ${CalculationService.formatDuration(remaining)}';
      }
      return 'Active now';
    } else {
      final timeUntil = brahmaMuhurta.timeUntilStart;
      if (timeUntil != null && timeUntil.inMinutes > 0) {
        return 'Starts in ${CalculationService.formatDuration(timeUntil)}';
      }
      return 'Time has passed for today';
    }
  }
}

class _TimeCard extends StatelessWidget {
  final String label;
  final String time;
  final Color color;
  final bool isPrimary;

  const _TimeCard({
    required this.label,
    required this.time,
    required this.color,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            time,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
          ),
        ],
      ),
    );
  }
}
