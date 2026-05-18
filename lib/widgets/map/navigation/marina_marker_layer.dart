import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:bahaar/models/map/navigation/marina_model.dart';

class MarinaMarkerLayer extends StatelessWidget {
  final List<Marina> marinas;
  final Function(Marina)? onMarinaTapped;
  final String? highlightedMarinaId;
  final bool showLabels;

  const MarinaMarkerLayer({
    super.key,
    required this.marinas,
    this.onMarinaTapped,
    this.highlightedMarinaId,
    this.showLabels = false,
  });

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: marinas.map((marina) {
        final isHighlighted = marina.id == highlightedMarinaId;

        return Marker(
          point: marina.location,
          width: isHighlighted ? 72 : 52,
          height: isHighlighted ? 72 : 52,
          child: GestureDetector(
            onTap: () => onMarinaTapped?.call(marina),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isHighlighted
                        ? Colors.orange.withValues(alpha: 0.9)
                        : Colors.blue.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: isHighlighted ? 6 : 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.local_shipping,
                    color: Colors.white,
                    size: isHighlighted ? 36 : 28,
                  ),
                ),

                if (showLabels || isHighlighted)
                  Positioned(
                    bottom: -24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: Text(
                        marina.name,
                        style: TextStyle(
                          fontSize: isHighlighted ? 11 : 9,
                          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class MarinaInfoCard extends StatelessWidget {
  final Marina marina;
  final VoidCallback? onClose;
  final VoidCallback? onNavigate;

  const MarinaInfoCard({
    super.key,
    required this.marina,
    this.onClose,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping, color: Colors.blue, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  marina.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (onClose != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 8),

          Chip(
            label: Text(marina.type.displayName),
            backgroundColor: Colors.blue.withValues(alpha: 0.1),
            labelStyle: const TextStyle(fontSize: 11),
            visualDensity: VisualDensity.compact,
          ),

          if (marina.depth != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.water, size: 16, color: Colors.blue),
                const SizedBox(width: 4),
                Text(
                  'Depth: ${marina.depth}m',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ],

          if (marina.facilities.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: marina.facilities.map((facility) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getFacilityIcon(facility),
                        size: 12,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        facility,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          if (onNavigate != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onNavigate,
                icon: const Icon(Icons.navigation, size: 18),
                label: const Text('Navigate Here'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],

          const SizedBox(height: 8),
          Text(
            '${marina.location.latitude.toStringAsFixed(4)}, ${marina.location.longitude.toStringAsFixed(4)}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFacilityIcon(String facility) {
    switch (facility.toLowerCase()) {
      case 'parking':
        return Icons.local_parking;
      case 'fuel':
        return Icons.local_gas_station;
      case 'restroom':
        return Icons.wc;
      case 'restaurant':
        return Icons.restaurant;
      case 'shower':
        return Icons.shower;
      default:
        return Icons.check_circle;
    }
  }
}
