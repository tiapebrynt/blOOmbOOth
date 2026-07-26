import 'package:flutter/material.dart';

/// Menampilkan animasi hitung mundur (3..2..1) sebelum kamera mengambil foto,
/// sesuai layar "Countdown" pada desain UI/UX.
//ahnaf
class CountdownOverlay extends StatefulWidget {
  final int seconds;
  final VoidCallback onFinished;

  const CountdownOverlay({super.key, required this.seconds, required this.onFinished});

  @override
  State<CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<CountdownOverlay>
    with SingleTickerProviderStateMixin {
  late int _current;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _current = widget.seconds;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: false);
    _tick();
  }

  void _tick() async {
    while (_current > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _current -= 1);
      _controller.forward(from: 0);
    }
    if (mounted) widget.onFinished();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black45,
      alignment: const Alignment(0, -0.5),
      child: ScaleTransition(
        scale: Tween(begin: 0.7, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOut),
        ),
        child: Text(
          _current > 0 ? '$_current' : '📸',
          style: const TextStyle(
            fontSize: 96,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
