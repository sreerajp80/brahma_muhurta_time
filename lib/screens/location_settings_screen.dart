// File Path: lib/screens/location_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/brahma_muhurta_provider.dart';
import '../models/saved_location.dart';
import '../utils/date_formatter.dart';

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
                                        .withOpacity(0.3),
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
                                              .withOpacity(0.5),
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
                              ? Icon(Icons.check_circle, color: Colors.green)
                              : Icon(Icons.error, color: Colors.orange),
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
                            final loadingDialog = showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (ctx) => const Center(
                                  child: CircularProgressIndicator()),
                            );
                            await provider.refreshLocation();
                            if (context.mounted) {
                              Navigator.pop(context); // Dismiss loading dialog
                            }
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
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          RadioListTile<bool>(
            title: const Text('Use Live GPS'),
            subtitle: const Text('Get current location from device GPS'),
            value: true,
            groupValue: provider.usingLiveLocation,
            onChanged: (value) async {
              if (value == true) {
                await provider.useLiveLocation();
              }
            },
            secondary: const Icon(Icons.gps_fixed),
          ),
          if (provider.savedLocations.isNotEmpty) ...[
            const Divider(height: 1),
            RadioListTile<bool>(
              title: const Text('Use Saved Location'),
              subtitle: Text(
                  'Choose from ${provider.savedLocations.length} saved location(s)'),
              value: false,
              groupValue: provider.usingLiveLocation,
              onChanged: (value) async {
                if (value == false && provider.savedLocations.isNotEmpty) {
                  if (provider.selectedSavedLocation != null) {
                    await provider
                        .selectSavedLocation(provider.selectedSavedLocation!);
                  } else {
                    await provider
                        .selectSavedLocation(provider.savedLocations.first);
                  }
                }
              },
              secondary: const Icon(Icons.bookmark),
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
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
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
                        .withOpacity(0.7),
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
                      .surfaceVariant
                      .withOpacity(0.5),
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
                  await provider
                      .saveCurrentLocation(_nameController.text.trim());
                  if (context.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Location saved successfully')),
                    );
                  }
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
                  try {
                    final lat = double.parse(latStr);
                    final lng = double.parse(lngStr);

                    if (lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
                      await provider.saveManualLocation(name, lat, lng);
                      if (context.mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Location added successfully')),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid coordinates')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
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
              await provider.deleteSavedLocation(location.id);
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Location deleted')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
