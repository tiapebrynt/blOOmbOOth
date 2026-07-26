import 'package:flutter/material.dart';

// ============================================================
// FILTER COLOR MATRICES — 30+ preset filter untuk live camera & result
// Semua matrix adalah ColorFilter 5x4 (20 elemen) untuk flutter ColorFilter.matrix()
// ============================================================

final Map<String, List<double>> filterMatrices = {
  // === CLASSIC ===
  'Normal': [
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  ],
  'Retro': [
    0.393, 0.769, 0.189, 0, 0,
    0.349, 0.686, 0.168, 0, 0,
    0.272, 0.534, 0.131, 0, 0,
    0, 0, 0, 1, 0,
  ],
  'Mono (B&W)': [
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ],
  'Sepia': [
    0.393, 0.769, 0.189, 0, 0,
    0.349, 0.686, 0.168, 0, 0,
    0.272, 0.534, 0.131, 0, 0,
    0, 0, 0, 1, 0,
  ],

  // === VIBRANT ===
  'Vivid': [
    1.3, 0, 0, 0, 0,
    0, 1.3, 0, 0, 0,
    0, 1.3, 0, 0, 0,
    0, 0, 0, 1, 0,
  ],
  'HDR': [
    1.4, 0, 0, 0, 0,
    0, 1.4, 0, 0, 0,
    0, 0, 1.4, 0, 0,
    0, 0, 0, 1.2, 0,
  ],
  'Pop!': [
    1.5, -0.2, -0.1, 0, 0,
    -0.1, 1.5, -0.1, 0, 0,
    -0.1, -0.2, 1.5, 0, 0,
    0, 0, 0, 1, 0,
  ],
  'Bold': [
    1.6, 0, 0, 0, 0,
    0, 1.4, 0, 0, 0,
    0, 0, 1.2, 0, 0,
    0, 0, 0, 1, 0,
  ],

  // === TEMPERATURE ===
  'Cool': [
    0.9, 0, 0, 0, 0,
    0, 0.9, 0, 0, 0,
    0, 0, 1.3, 0, 0,
    0, 0, 0, 1, 0,
  ],
  'Warm': [
    1.2, 0, 0, 0, 0,
    0, 1.1, 0, 0, 0,
    0, 0, 0.8, 0, 0,
    0, 0, 0, 1, 0,
  ],
  'Golden': [
    1.2, 0.1, 0, 0, 0,
    0, 1.0, 0, 0, 0,
    0, 0, 0.7, 0, 0,
    0, 0, 0, 1, 0,
  ],
  'Icy Blue': [
    0.8, 0, 0, 0, 0,
    0, 0.9, 0.1, 0, 0,
    0, 0, 1.2, 0, 0,
    0, 0, 0, 1, 0,
  ],
  'Sunset': [
    1.3, 0.2, 0, 0, 0,
    0, 0.8, 0, 0, 0,
    0, 0, 0.6, 0, 0,
    0, 0, 0, 1, 0,
  ],

  // === FILM STOCK ===
  'Kodak Gold': [
    1.1, 0.05, 0, 0, 0,
    0, 1.0, 0.05, 0, 0,
    0, 0, 0.85, 0, 0,
    0, 0, 0, 1, 0,
  ],
  'Fuji Pro': [
    0.95, 0, 0, 0, 0,
    0, 1.05, 0, 0, 0,
    0, 0, 1.1, 0, 0,
    0, 0, 0, 1, 0,
  ],
  'Cinematic': [
    1.1, -0.05, -0.1, 0, 0,
    -0.05, 1.0, -0.05, 0, 0,
    0.05, -0.1, 0.9, 0, 0,
    0, 0, 0, 1, 0,
  ],
  'Film Burn': [
    1.0, 0.1, 0.05, 0, 0,
    0.05, 0.9, 0.05, 0, 0,
    0.05, 0.05, 0.8, 0, 0,
    0, 0, 0, 1, 0,
  ],
  'Bleach Bypass': [
    1.2, 0, 0, 0, 0,
    0, 1.2, 0, 0, 0,
    0, 0, 1.2, 0, 0,
    0, 0, 0, 0.8, 0,
  ],
  'Cross Process': [
    0.8, 0.2, 0, 0, 0,
    0, 1.2, 0, 0, 0,
    0, 0.1, 0.9, 0, 0,
    0, 0, 0, 1, 0,
  ],

  // === DARK / MOODY ===
  'Dramatic': [
    1.4, 0, 0, 0, 0,
    0, 1.3, 0, 0, 0,
    0, 0, 1.2, 0, 0,
    0, 0, 0, 0.9, 0,
  ],
  'Moody': [
    0.8, 0, 0, 0, 0,
    0, 0.8, 0, 0, 0,
    0, 0, 0.9, 0, 0,
    0, 0, 0, 1, 0,
  ],
  'Nocturnal': [
    0.6, 0, 0, 0, 0,
    0, 0.6, 0.1, 0, 0,
    0, 0, 0.9, 0, 0,
    0, 0, 0, 1, 0,
  ],
  'Dark Vintage': [
    0.6, 0.3, 0.1, 0, 0,
    0.1, 0.6, 0.1, 0, 0,
    0.1, 0.1, 0.5, 0, 0,
    0, 0, 0, 1, 0,
  ],

  // === COLOR TINT ===
  'Lavender': [
    1.0, 0, 0, 0, 0,
    0, 0.8, 0, 0, 0,
    0, 0, 1.3, 0, 0,
    0, 0, 0, 1, 0,
  ],
  'Mint': [
    0.8, 0, 0, 0, 0,
    0, 1.2, 0, 0, 0,
    0, 0, 1.0, 0, 0,
    0, 0, 0, 1, 0,
  ],
  'Rose': [
    1.3, 0, 0, 0, 0,
    0, 0.9, 0, 0, 0,
    0, 0, 0.9, 0, 0,
    0, 0, 0, 1, 0,
  ],
  'Ocean': [
    0.8, 0, 0, 0, 0,
    0, 1.0, 0, 0, 0,
    0, 0, 1.3, 0, 0,
    0, 0, 0, 1, 0,
  ],
  'Forest': [
    0.8, 0, 0, 0, 0,
    0, 1.2, 0, 0, 0,
    0, 0, 0.9, 0, 0,
    0, 0, 0, 1, 0,
  ],
  'Cotton Candy': [
    1.2, 0, 0, 0, 0,
    0, 0.9, 0.1, 0, 0,
    0, 0, 1.2, 0, 0,
    0, 0, 0, 1, 0,
  ],

  // === SPECIAL ===
  'Polaroid': [
    1.1, 0.05, 0, 0, 0,
    0, 1.0, 0.05, 0, 0,
    0, 0, 0.9, 0, 0,
    0, 0, 0, 0.95, 0,
  ],
  'Lomo': [
    1.3, 0, 0, 0, 0,
    0, 1.1, 0, 0, 0,
    0, 0, 0.9, 0, 0,
    0, 0, 0, 0.9, 0,
  ],
  'Soft': [
    0.9, 0, 0, 0, 0,
    0, 0.9, 0, 0, 0,
    0, 0, 0.9, 0, 0,
    0, 0, 0, 0.85, 0,
  ],
  'Infrared': [
    0, 0.8, 0.2, 0, 0,
    0, 0, 0.6, 0, 0,
    0.3, 0, 0.5, 0, 0,
    0, 0, 0, 1, 0,
  ],
  'Solarize': [
    0.8, 0.2, 0, 0, 0,
    0, 1.2, 0, 0, 0,
    0, 0.2, 0.8, 0, 0,
    0, 0, 0, 1, 0,
  ],
  'X-Ray': [
    1, 1, 1, 0, 0,
    1, 1, 1, 0, 0,
    1, 1, 1, 0, 0,
    0, 0, 0, 1, 0,
  ],
};

// ============================================================
// EFFECTS
// ============================================================

final List<Map<String, dynamic>> effectsList = [
  {'name': 'Normal', 'icon': Icons.circle_outlined},
  {'name': 'Sparkle', 'icon': Icons.auto_awesome},
  {'name': 'Neon Glow', 'icon': Icons.wb_iridescent},
  {'name': 'Dreamy Blur', 'icon': Icons.blur_on},
  {'name': 'Retro Grain', 'icon': Icons.movie_filter},
  {'name': 'Vignette', 'icon': Icons.vignette},
  {'name': 'Soft Glow', 'icon': Icons.flare},
  {'name': 'Glitch', 'icon': Icons.flash_on},
  {'name': 'Chromatic', 'icon': Icons.colorize},
  {'name': 'Film Dust', 'icon': Icons.grain},
  {'name': 'Light Leak', 'icon': Icons.wb_sunny},
  {'name': 'Bokeh', 'icon': Icons.blur_circular},
];

// ============================================================
// VIBES (color overlay tones)
// ============================================================

final List<VibeData> vibesList = [
  VibeData('Normal', Colors.transparent),
  VibeData('Warm', Color(0x33FFA500)),
  VibeData('Studio', Color(0x22FFFFFF)),
  VibeData('Cinematic', Color(0x331A237E)),
  VibeData('Golden Hour', Color(0x44FFD700)),
  VibeData('Sunset', Color(0x44FF6347)),
  VibeData('Neon', Color(0x33FF00FF)),
  VibeData('Pastel', Color(0x22FFB6C1)),
  VibeData('Moody', Color(0x33222244)),
  VibeData('Vibrant', Color(0x22FF4500)),
  VibeData('Soft Pink', Color(0x22FFC0CB)),
  VibeData('Milky', Color(0x18FFFFFF)),
  VibeData('Forest', Color(0x33228B22)),
  VibeData('Ocean', Color(0x330066CC)),
  VibeData('Cotton Candy', Color(0x22FF69B4)),
  VibeData('Dramatic', Color(0x33000000)),
];

class VibeData {
  final String name;
  final Color color;
  const VibeData(this.name, this.color);
}

// ============================================================
// HELPER: dapatkan nama filter (hilangkan 'Normal' untuk source list)
// ============================================================

List<String> get filterNames => filterMatrices.keys.where((k) => k != 'Normal').toList();
List<String> get effectNames => effectsList.map((e) => e['name'] as String).toList();
List<String> get vibeNames => vibesList.map((v) => v.name).toList();

