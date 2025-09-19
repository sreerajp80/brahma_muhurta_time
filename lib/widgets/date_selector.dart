// File Path: lib/widgets/date_selector.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/brahma_muhurta_provider.dart';
import 'package:intl/intl.dart';

class DateSelector extends StatelessWidget {
  const DateSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BrahmaMuhurtaProvider>(
      builder: (context, provider, child) {
        final selectedDate = provider.selectedDate;
        final isToday = provider.isToday;

        return Card(
          elevation: 2,
          color:
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getDateLabel(selectedDate, isToday),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                      ),
                      Text(
                        DateFormat('MMMM dd, yyyy').format(selectedDate),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer
                                  .withOpacity(0.8),
                            ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.chevron_left,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () {
                        provider.changeSelectedDate(
                          selectedDate.subtract(const Duration(days: 1)),
                        );
                      },
                      tooltip: 'Previous day',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                    Container(
                      height: 24,
                      width: 1,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.3),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.today,
                        color: isToday
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.5)
                            : Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: isToday
                          ? null
                          : () {
                              provider.changeSelectedDate(DateTime.now());
                            },
                      tooltip: 'Today',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                    Container(
                      height: 24,
                      width: 1,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.3),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () {
                        provider.changeSelectedDate(
                          selectedDate.add(const Duration(days: 1)),
                        );
                      },
                      tooltip: 'Next day',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.date_range,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 365)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: Theme.of(context)
                                    .colorScheme
                                    .copyWith(
                                      primary:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                              child: child!,
                            );
                          },
                        );

                        if (picked != null &&
                            !DateUtils.isSameDay(picked, selectedDate)) {
                          provider.changeSelectedDate(picked);
                        }
                      },
                      tooltip: 'Pick a date',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getDateLabel(DateTime date, bool isToday) {
    if (isToday) {
      return 'Today';
    }

    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    if (DateUtils.isSameDay(date, tomorrow)) {
      return 'Tomorrow';
    } else if (DateUtils.isSameDay(date, yesterday)) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE').format(date);
    }
  }
}
