import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// Layar "Live Effects": memilih preset efek yang diterapkan secara live
/// pada preview kamera (mis. overlay warna sementara sebelum jepret).
class LiveEffectsScreen extends StatefulWidget {
  final String current;
  const LiveEffectsScreen({super.key, required this.current});

  @override
  State<LiveEffectsScreen> createState() => _LiveEffectsScreenState();
}

class _LiveEffectsScreenState extends State<LiveEffectsScreen> {
  late String _selected;

  final _effects = const [
    {'name': 'Normal', 'icon': Icons.circle_outlined},
    {'name': 'Sparkle', 'icon': Icons.auto_awesome},
    {'name': 'Neon Glow', 'icon': Icons.wb_iridescent},
    {'name': 'Dreamy Blur', 'icon': Icons.blur_on},
    {'name': 'Retro Grain', 'icon': Icons.movie_filter},
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Live Effects'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: _effects.length,
        itemBuilder: (context, i) {
          final effect = _effects[i];
          final isSelected = effect['name'] == _selected;
          return GestureDetector(
            onTap: () => setState(() => _selected = effect['name'] as String),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white10,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? AppColors.primary : Colors.white24),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(effect['icon'] as IconData, color: Colors.white, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    effect['name'] as String,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(_selected),
            child: const Text('Terapkan'),
          ),
        ),
      ),
    );
  }
}
