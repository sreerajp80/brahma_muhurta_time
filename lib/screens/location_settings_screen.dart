// File Path: brahma_muhurta_time/lib/screens/location_settings_screen.dart
// Author: Sreeraj P
// Created:
// Last Modified: 2025 October 18
// Description: Screen for managing location settings in the Brahma Muhurta Time app.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/brahma_muhurta_provider.dart';
import '../models/saved_location.dart';
import '../utils/date_formatter.dart';
import 'package:file_picker/file_picker.dart';
import '../services/notification_service.dart';

class LocationSettingsScreen extends StatefulWidget {
  const LocationSettingsScreen({super.key});

  @override
  State<LocationSettingsScreen> createState() => _LocationSettingsScreenState();
}

class _LocationSettingsScreenState extends State<LocationSettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Widget _buildNotificationInfo(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  void _showRingtoneOptions(
      BuildContext context, BrahmaMuhurtaProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.music_note),
                title: const Text('Select Custom Ringtone'),
                subtitle: const Text('Choose audio file from device'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _pickCustomRingtone(context, provider);
                },
              ),
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('Use Default Sound'),
                subtitle: const Text('Reset to system default'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _resetToDefaultRingtone(context, provider);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickCustomRingtone(
      BuildContext context, BrahmaMuhurtaProvider provider) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'ogg', 'wav'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;

        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => const Center(child: CircularProgressIndicator()),
          );
        }

        final success = await NotificationService()
            .setCustomRingtone(filePath, fileName: fileName);

        if (context.mounted) {
          Navigator.of(context).pop();
        }

        if (!success) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Failed to set ringtone. Only MP3, OGG, and WAV are supported.\n\n'
                  'Tip: Convert M4A files online at cloudconvert.com',
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 5),
              ),
            );
          }
          return;
        }

        // Reschedule notifications
        if (provider.brahmaMuhurta != null) {
          if (provider.usingLiveLocation && provider.currentLocation != null) {
            await NotificationService().scheduleNotificationsAdvanced(
              latitude: provider.currentLocation!.latitude,
              longitude: provider.currentLocation!.longitude,
            );
          } else if (provider.selectedSavedLocation != null) {
            await NotificationService().scheduleNotificationsAdvanced(
              latitude: provider.selectedSavedLocation!.latitude,
              longitude: provider.selectedSavedLocation!.longitude,
            );
          }
        }

        if (context.mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Custom ringtone set: $fileName'),
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'TEST',
                onPressed: () {
                  NotificationService().testNotification();
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting ringtone: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resetToDefaultRingtone(
      BuildContext context, BrahmaMuhurtaProvider provider) async {
    try {
      // Remove custom ringtone
      await NotificationService().setCustomRingtone(null);

      // Reschedule notifications with default sound
      if (provider.brahmaMuhurta != null) {
        if (provider.usingLiveLocation && provider.currentLocation != null) {
          await NotificationService().scheduleNotificationsAdvanced(
            latitude: provider.currentLocation!.latitude,
            longitude: provider.currentLocation!.longitude,
          );
        } else if (provider.selectedSavedLocation != null) {
          await NotificationService().scheduleNotificationsAdvanced(
            latitude: provider.selectedSavedLocation!.latitude,
            longitude: provider.selectedSavedLocation!.longitude,
          );
        }
      }

      if (context.mounted) {
        setState(() {}); // Refresh UI
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reset to default notification sound'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resetting ringtone: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Settings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Consumer<BrahmaMuhurtaProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location Mode Selection
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_searching,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Location Mode',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildLocationModeSelector(provider),

                        // Current GPS Location Info
                        if (provider.usingLiveLocation &&
                            provider.currentLocation != null) ...[
                          const SizedBox(height: 16),
                          _buildCurrentLocationInfo(provider),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Saved Locations
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.bookmark,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Saved Locations',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const Spacer(),
                            Text(
                              '(${provider.savedLocations.length})',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (provider.savedLocations.isEmpty)
                          Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 24.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.bookmark_border,
                                    size: 48,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.3),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No saved locations yet',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.5),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          _buildSavedLocationsList(provider),

                        const SizedBox(height: 16),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showAddManualLocationDialog(
                                    context, provider),
                                icon: const Icon(Icons.add_location),
                                label: const Text('Add Manual'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 44),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: provider.currentLocation != null &&
                                        provider.usingLiveLocation
                                    ? () => _showSaveCurrentLocationDialog(
                                        context, provider)
                                    : null,
                                icon: const Icon(Icons.save),
                                label: const Text('Save Current'),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(0, 44),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // GPS Information
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'GPS Information',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.gps_fixed),
                          title: const Text('GPS Status'),
                          subtitle: Text(provider.currentLocation != null
                              ? 'Available'
                              : 'Not Available'),
                          trailing: provider.currentLocation != null
                              ? const Icon(Icons.check_circle,
                                  color: Colors.green)
                              : const Icon(Icons.error, color: Colors.orange),
                          contentPadding: EdgeInsets.zero,
                        ),
                        if (provider.currentLocation != null) ...[
                          ListTile(
                            leading: const Icon(Icons.location_on),
                            title: const Text('Coordinates'),
                            subtitle:
                                Text(provider.currentLocation!.coordinates),
                            contentPadding: EdgeInsets.zero,
                          ),
                          ListTile(
                            leading: const Icon(Icons.update),
                            title: const Text('Last Updated'),
                            subtitle: Text(DateFormatter.formatTimestamp(
                                provider.currentLocation!.timestamp,
                                includeTime: true)),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            // Capture context before async gap
                            final navigator = Navigator.of(context);

                            // Show loading dialog
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (ctx) => const Center(
                                  child: CircularProgressIndicator()),
                            );

                            await provider.refreshLocation();

                            // Use captured references instead of context
                            navigator.pop(); // Dismiss loading dialog
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh GPS'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 44),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

// Notification Settings Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.notifications_active,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Notification Settings',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Custom Ringtone Setting
                        ListTile(
                          leading: const Icon(Icons.music_note),
                          title: const Text('Notification Sound'),
                          subtitle: Text(
                            NotificationService().hasCustomRingtone()
                                ? 'Custom: ${NotificationService().getCustomRingtoneName() ?? 'Unknown'}'
                                : 'Default System Sound',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          contentPadding: EdgeInsets.zero,
                          onTap: () => _showRingtoneOptions(context, provider),
                        ),

                        const SizedBox(height: 8),

                        // Test Notification Button
                        ElevatedButton.icon(
                          onPressed: () async {
                            await NotificationService().testNotification();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Test notification sent!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.notification_add),
                          label: const Text('Test Notification Sound'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 44),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Notification Schedule Info
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'You will receive 3 notifications daily:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildNotificationInfo('15 minutes before start'),
                              _buildNotificationInfo('At Brahma Muhurta start'),
                              _buildNotificationInfo('15 minutes after start'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationModeSelector(BrahmaMuhurtaProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.gps_fixed,
                color: provider.usingLiveLocation
                    ? Theme.of(context).colorScheme.primary
                    : null),
            title: const Text('Use Live GPS'),
            subtitle: const Text('Get current location from device GPS'),
            trailing: provider.usingLiveLocation
                ? Icon(Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary)
                : null,
            onTap: () async => provider.useLiveLocation(),
          ),
          if (provider.savedLocations.isNotEmpty) ...[
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.bookmark,
                  color: !provider.usingLiveLocation
                      ? Theme.of(context).colorScheme.primary
                      : null),
              title: const Text('Use Saved Location'),
              subtitle: Text(
                  'Choose from ${provider.savedLocations.length} saved location(s)'),
              trailing: !provider.usingLiveLocation
                  ? Icon(Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () async {
                final target = provider.selectedSavedLocation ??
                    provider.savedLocations.first;
                await provider.selectSavedLocation(target);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentLocationInfo(BrahmaMuhurtaProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.my_location,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current GPS Location',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  provider.currentLocation!.coordinates,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedLocationsList(BrahmaMuhurtaProvider provider) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: provider.savedLocations.length,
        itemBuilder: (context, index) {
          final location = provider.savedLocations[index];
          final isSelected = !provider.usingLiveLocation &&
              provider.selectedSavedLocation?.id == location.id;

          return Card(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            child: ListTile(
              leading: Icon(
                Icons.location_on,
                color:
                    isSelected ? Theme.of(context).colorScheme.primary : null,
              ),
              title: Text(location.name),
              subtitle: Text(location.coordinates),
              selected: isSelected,
              onTap: () async {
                await provider.selectSavedLocation(location);
              },
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () =>
                        _confirmDeleteLocation(context, provider, location),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSaveCurrentLocationDialog(
      BuildContext context, BrahmaMuhurtaProvider provider) {
    _nameController.clear();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Save Current Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Location Name',
                  hintText: 'e.g., Home, Office, Temple',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on,
                        size: 16, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        provider.currentLocation!.coordinates,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_nameController.text.trim().isNotEmpty) {
                  // Capture references before async gap
                  final navigator = Navigator.of(dialogContext);
                  final scaffoldMessenger = ScaffoldMessenger.of(context);

                  await provider
                      .saveCurrentLocation(_nameController.text.trim());

                  navigator.pop();
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                        content: Text('Location saved successfully')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showAddManualLocationDialog(
      BuildContext context, BrahmaMuhurtaProvider provider) {
    _nameController.clear();
    _latController.clear();
    _lngController.clear();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Location Manually'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Location Name',
                    hintText: 'e.g., Home, Office',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _latController,
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    hintText: 'e.g., 28.6139',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _lngController,
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    hintText: 'e.g., 77.2090',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = _nameController.text.trim();
                final latStr = _latController.text.trim();
                final lngStr = _lngController.text.trim();

                if (name.isNotEmpty && latStr.isNotEmpty && lngStr.isNotEmpty) {
                  // Capture references before async gap
                  final navigator = Navigator.of(dialogContext);
                  final scaffoldMessenger = ScaffoldMessenger.of(context);

                  try {
                    final lat = double.parse(latStr);
                    final lng = double.parse(lngStr);

                    if (lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
                      await provider.saveManualLocation(name, lat, lng);
                      navigator.pop();
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                            content: Text('Location added successfully')),
                      );
                    } else {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(content: Text('Invalid coordinates')),
                      );
                    }
                  } catch (e) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                          content: Text('Please enter valid numbers')),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteLocation(BuildContext context,
      BrahmaMuhurtaProvider provider, SavedLocation location) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Location'),
        content: Text('Delete "${location.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Capture references before async gap
              final navigator = Navigator.of(ctx);
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              await provider.deleteSavedLocation(location.id);
              navigator.pop();
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('Location deleted')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
