// File Path: lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/brahma_muhurta_provider.dart';
import '../services/notification_service.dart';
import '../widgets/location_card.dart';
import '../widgets/brahma_muhurta_card.dart';
import '../widgets/date_selector.dart';
import '../constants/app_info.dart';
import 'location_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BrahmaMuhurtaProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Brahma Muhurta Calculator',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        actions: [
          Consumer<BrahmaMuhurtaProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: Icon(
                  provider.notificationsEnabled
                      ? Icons.notifications_active
                      : Icons.notifications_off,
                ),
                onPressed: () async {
                  await provider.toggleNotifications();
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.notificationsEnabled
                            ? 'Notifications enabled for 7 days in advance'
                            : 'Notifications disabled',
                      ),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
                tooltip: provider.notificationsEnabled
                    ? 'Disable notifications'
                    : 'Enable notifications',
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (String value) {
              // Handle menu selection
              switch (value) {
                case 'about_brahma':
                  _showAboutBrahmaMuhurta(context);
                  break;
                case 'about_app':
                  _showAboutApp(context);
                  break;
                case 'settings':
                  _showSettings(context);
                  break;
                case 'location_settings':
                  _showLocationSettings(context);
                  break;
                case 'notification_debug':
                  _showNotificationDebug(context);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'about_brahma',
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('About Brahma Muhurta'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'about_app',
                child: ListTile(
                  leading: Icon(Icons.apps),
                  title: Text('About App'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'location_settings',
                child: ListTile(
                  leading: Icon(Icons.location_on),
                  title: Text('Location Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'notification_debug',
                child: ListTile(
                  leading: Icon(Icons.bug_report),
                  title: Text('Notification Debug'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<BrahmaMuhurtaProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Getting your location...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => provider.refreshLocation(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () async {
                        final hasPermission =
                            await provider.hasLocationPermission();
                        if (!hasPermission && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please enable location permissions in settings',
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('Check Permissions'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.brahmaMuhurta == null) {
            return const Center(
              child: Text(
                'No data available',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.refreshLocation();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Date Selector
                    const DateSelector(),

                    const SizedBox(height: 16),

                    // Brahma Muhurta Card
                    BrahmaMuhurtaCard(
                      brahmaMuhurta: provider.brahmaMuhurta!,
                      isActive: provider.isCurrentlyActive,
                      isToday: provider.isToday,
                    ),

                    const SizedBox(height: 16),

                    // Location Card
                    LocationCard(
                      location: provider.location,
                      isLoading: provider.isLoading,
                      onRefresh: () => provider.refreshLocation(),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAboutBrahmaMuhurta(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text('About Brahma Muhurta'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Brahma Muhurta is considered the most auspicious time for spiritual practices, meditation, and study. It occurs during the last 48 minutes before sunrise when the atmosphere is serene and conducive to inner growth.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Benefits:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                const Text('• Enhanced focus and concentration'),
                const Text('• Increased spiritual awareness'),
                const Text('• Peaceful and calm mind'),
                const Text('• Optimal mental clarity'),
                const Text('• Better retention and learning'),
                const SizedBox(height: 16),
                Text(
                  'Best Practices:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                const Text('• Wake up naturally without alarm if possible'),
                const Text('• Practice meditation or yoga'),
                const Text('• Read spiritual or educational texts'),
                const Text('• Engage in quiet reflection'),
                const Text('• Avoid heavy physical activities'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'The timing is calculated based on your exact location and changes daily with the sunrise.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showAboutApp(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.apps,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text('About App'),
            ],
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAboutItem(
                context,
                icon: Icons.person_outline,
                label: 'Concept and Design',
                value: AppInfo.conceptAndDesign,
              ),
              const SizedBox(height: 12),
              _buildAboutItem(
                context,
                icon: Icons.smart_toy_outlined,
                label: 'AI Used',
                value: AppInfo.aiUsed,
              ),
              const SizedBox(height: 12),
              _buildAboutItem(
                context,
                icon: Icons.code,
                label: 'IDE',
                value: AppInfo.ide,
              ),
              const SizedBox(height: 12),
              _buildAboutItem(
                context,
                icon: Icons.calendar_today,
                label: 'Build Date',
                value: AppInfo.buildDate,
              ),
              const SizedBox(height: 16),
              Divider(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Version ${AppInfo.appVersion}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.settings,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text('Settings'),
            ],
          ),
          content: Consumer<BrahmaMuhurtaProvider>(
            builder: (context, provider, child) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      title: const Text('Advanced Notifications'),
                      subtitle: const Text(
                        'Get notified for 7 days in advance',
                      ),
                      value: provider.notificationsEnabled,
                      onChanged: (value) async {
                        await provider.toggleNotifications();
                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              provider.notificationsEnabled
                                  ? 'Notifications enabled for 7 days'
                                  : 'Notifications disabled',
                            ),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      },
                      secondary: Icon(
                        provider.notificationsEnabled
                            ? Icons.notifications_active
                            : Icons.notifications_off,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 16),

                    // Test Notification Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: provider.notificationsEnabled
                            ? Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withOpacity(0.3)
                            : Theme.of(context)
                                .colorScheme
                                .surfaceVariant
                                .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: provider.notificationsEnabled
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.3)
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Test Notifications',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: provider.notificationsEnabled
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.5),
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Check if notifications are working properly',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: provider.notificationsEnabled
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.4),
                                    ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: provider.notificationsEnabled
                                ? () async {
                                    final notificationService =
                                        NotificationService();
                                    await notificationService
                                        .testNotification();

                                    if (!context.mounted) return;

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Test notification sent! Check your notification panel.',
                                        ),
                                        duration: Duration(seconds: 3),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                : null,
                            icon: Icon(
                              Icons.notifications_active,
                              size: 20,
                            ),
                            label: const Text('Send Test Notification'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: provider.notificationsEnabled
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                              foregroundColor: provider.notificationsEnabled
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : null,
                            ),
                          ),
                          if (!provider.notificationsEnabled)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Enable notifications to test',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.error,
                                      fontStyle: FontStyle.italic,
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Force Reschedule Button (for debugging)
                    if (provider.notificationsEnabled)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await provider.forceRescheduleNotifications();
                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Notifications rescheduled for next 7 days'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Reschedule All Notifications'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.secondary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onSecondary,
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Info text
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceVariant
                            .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Advanced notifications schedule alerts for the next 7 days automatically, even when the app is closed.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showLocationSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LocationSettingsScreen(),
      ),
    );
  }

  void _showNotificationDebug(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.bug_report,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text('Notification Debug'),
            ],
          ),
          content: Consumer<BrahmaMuhurtaProvider>(
            builder: (context, provider, child) {
              return SizedBox(
                width: double.maxFinite,
                child: FutureBuilder<Map<String, dynamic>>(
                  future: provider.getNotificationStatus(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final status = snapshot.data ?? {};

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildDebugItem('Notifications Enabled',
                              provider.notificationsEnabled ? 'Yes' : 'No'),
                          _buildDebugItem(
                              'Total Pending', '${status['total'] ?? 0}'),
                          _buildDebugItem('Reminder Notifications',
                              '${status['reminders'] ?? 0}'),
                          _buildDebugItem('Start Notifications',
                              '${status['starts'] ?? 0}'),
                          _buildDebugItem('Next Notification ID',
                              '${status['nextNotification'] ?? 'None'}'),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await provider.forceRescheduleNotifications();
                              if (!context.mounted) return;
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Debug: Notifications rescheduled'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Force Reschedule'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDebugItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
