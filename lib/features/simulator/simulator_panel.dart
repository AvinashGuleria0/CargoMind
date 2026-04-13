import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_theme.dart';

class SimulatorPanel extends StatefulWidget {
  const SimulatorPanel({Key? key}) : super(key: key);

  @override
  State<SimulatorPanel> createState() => _SimulatorPanelState();
}

class _SimulatorPanelState extends State<SimulatorPanel> {
  String _selectedTruck = 'Agricultural (MH-12)';
  double _temperature = 6.2;
  bool _isLoading = false;

  final List<String> _truckOptions = [
    'Agricultural (MH-12)',
    'Medical (MD-01)',
  ];

  Future<void> _triggerIncident() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final payload = {
        'vehicle_id': _selectedTruck.contains('MH-12') ? 'MH-12' : 'MD-01',
        'incident_type': 'HIGHWAY_COLLAPSE',
        'severity': 'HIGH',
        'current_lat': 28.6139,
        'current_lng': 77.2090,
        'temperature_celsius': _temperature,
        'estimated_value_inr': _selectedTruck.contains('MH-12') ? 210000 : 5000000,
      };

      // Assuming the Node.js backend is running on localhost:18080
      // In production, this should point to your real backend URL
      final url = Uri.parse('http://127.0.0.1:18080/api/trigger-incident');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final decision = data['result']['decision']['action_type'] ?? 'Unknown Action';
        final justification = data['result']['decision']['justification_log'] ?? '';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade800,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Action: $decision', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(justification, style: const TextStyle(fontSize: 12)),
              ],
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade800,
          content: Text('Failed to trigger incident: $e'),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark 
                ? theme.colorScheme.surface.withOpacity(0.7) 
                : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.dividerColor.withOpacity(0.2), 
              width: 1
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.science, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Environment Simulator',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Text(
                'Target Vehicle',
                style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedTruck,
                    isExpanded: true,
                    dropdownColor: theme.cardColor,
                    items: _truckOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedTruck = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Internal Temperature',
                    style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color),
                  ),
                  Text(
                    '${_temperature.toStringAsFixed(1)}°C',
                    style: TextStyle(
                      fontSize: 12, 
                      fontWeight: FontWeight.bold,
                      color: _temperature > 15 ? Colors.red : theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: _temperature > 15 ? Colors.red : theme.colorScheme.primary,
                  thumbColor: _temperature > 15 ? Colors.red : theme.colorScheme.primary,
                  overlayColor: (_temperature > 15 ? Colors.red : theme.colorScheme.primary).withOpacity(0.2),
                ),
                child: Slider(
                  value: _temperature,
                  min: -20,
                  max: 40,
                  divisions: 120,
                  onChanged: (value) {
                    setState(() {
                      _temperature = value;
                    });
                  },
                ),
              ),
              
              const SizedBox(height: 12),
              
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _triggerIncident,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: _isLoading 
                      ? const SizedBox(
                          width: 16, 
                          height: 16, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : const Icon(Icons.warning_amber_rounded, size: 18),
                  label: Text(
                    _isLoading ? 'Processing via Agent...' : 'Trigger Highway Collapse',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
