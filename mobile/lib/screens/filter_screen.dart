// import 'dart:io';
// import 'package:flutter/material.dart';
// import '../utils/theme.dart';
// import '../utils/booth_draft.dart';
// import 'result_screen.dart';

// class FilterScreen extends StatefulWidget {
//   final BoothDraft draft;
//   const FilterScreen({super.key, required this.draft});

//   @override
//   State<FilterScreen> createState() => _FilterScreenState();
// }

// class _FilterScreenState extends State<FilterScreen> {
//   String _selectedFilter = 'Normal';
//   double _filterIntensity = 0.8;

//   // Filter color matrices untuk simulasi filter estetik
//   final Map<String, List<double>> _filterMatrices = {
//     'Retro': [
//       0.393, 0.769, 0.189, 0, 0,
//       0.349, 0.686, 0.168, 0, 0,
//       0.272, 0.534, 0.131, 0, 0,
//       0, 0, 0, 1, 0,
//     ],
//     'Mono (B&W)': [
//       0.2126, 0.7152, 0.0722, 0, 0,
//       0.2126, 0.7152, 0.0722, 0, 0,
//       0.2126, 0.7152, 0.0722, 0, 0,
//       0, 0, 0, 1, 0,
//     ],
//     'Vivid': [
//       1.2, 0, 0, 0, 0,
//       0, 1.2, 0, 0, 0,
//       0, 0, 1.2, 0, 0,
//       0, 0, 0, 1, 0,
//     ],
//     'Cool': [
//       0.9, 0, 0, 0, 0,
//       0, 0.9, 0, 0, 0,
//       0, 0, 1.2, 0, 0,
//       0, 0, 0, 1, 0,
//     ],
//   };

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text(
//           "Pilih Filter Akhir",
//           style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//       ),
//       body: Column(
//         children: [
//           // Grid preview foto yang sudah diambil dengan filter terpilih
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
//               child: GridView.builder(
//                 gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: 2,
//                   crossAxisSpacing: 12,
//                   mainAxisSpacing: 12,
//                   childAspectRatio: 3 / 4,
//                 ),
//                 itemCount: widget.draft.capturedPhotos.length,
//                 itemBuilder: (context, index) {
//                   return ClipRRect(
//                     borderRadius: BorderRadius.circular(16),
//                     child: _buildFilteredImage(widget.draft.capturedPhotos[index]),
//                   );
//                 },
//               ),
//             ),
//           ),

//           // Kontrol Filter & Intensitas
//           Container(
//             padding: const EdgeInsets.all(24),
//             decoration: BoxDecoration(
//               color: Colors.grey.shade50,
//               borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.05),
//                   blurRadius: 10,
//                   offset: const Offset(0, -5),
//                 )
//               ],
//             ),
//             child: SafeArea(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   // Slider Intensitas
//                   if (_selectedFilter != 'Normal') ...[
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         const Text("Intensitas Filter", style: TextStyle(fontWeight: FontWeight.bold)),
//                         Text("${(_filterIntensity * 100).toInt()}%", style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
//                       ],
//                     ),
//                     Slider(
//                       value: _filterIntensity,
//                       activeColor: AppColors.primary,
//                       inactiveColor: Colors.grey.shade200,
//                       onChanged: (val) => setState(() => _filterIntensity = val),
//                     ),
//                     const SizedBox(height: 16),
//                   ],

//                   // Pilihan Filter Bulat Horizontal
//                   SizedBox(
//                     height: 84,
//                     child: ListView(
//                       scrollDirection: Axis.horizontal,
//                       children: [
//                         _buildFilterOption('Normal'),
//                         _buildFilterOption('Retro'),
//                         _buildFilterOption('Mono (B&W)'),
//                         _buildFilterOption('Vivid'),
//                         _buildFilterOption('Cool'),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 24),

//                   // Tombol Lanjut ke Result
//                   ElevatedButton(
//                     onPressed: () {
//                       Navigator.of(context).push(
//                         MaterialPageRoute(
//                           builder: (_) => ResultScreen(
//                             draft: widget.draft,
//                             selectedFilter: _selectedFilter,
//                             filterIntensity: _filterIntensity,
//                           ),
//                         ),
//                       );
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: AppColors.primary,
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(vertical: 18),
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                       elevation: 2,
//                     ),
//                     child: const Text("Terapkan & Lihat Hasil", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFilteredImage(File file) {
//     final image = Image.file(file, fit: BoxFit.cover);
//     if (_selectedFilter == 'Normal' || !_filterMatrices.containsKey(_selectedFilter)) {
//       return image;
//     }

//     // Menggunakan ColorFiltered dengan matrix manipulasi warna
//     return ColorFiltered(
//       colorFilter: ColorFilter.matrix(_filterMatrices[_selectedFilter]!),
//       child: image,
//     );
//   }

//   Widget _buildFilterOption(String name) {
//     final isSelected = _selectedFilter == name;
//     return GestureDetector(
//       onTap: () => setState(() => _selectedFilter = name),
//       child: Container(
//         margin: const EdgeInsets.only(right: 12),
//         width: 80,
//         decoration: BoxDecoration(
//           color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(
//             color: isSelected ? AppColors.primary : Colors.grey.shade300,
//             width: 2,
//           ),
//         ),
//         alignment: Alignment.center,
//         child: Text(
//           name,
//           textAlign: TextAlign.center,
//           style: TextStyle(
//             fontSize: 12,
//             fontWeight: FontWeight.bold,
//             color: isSelected ? AppColors.primary : Colors.black87,
//           ),
//         ),
//       ),
//     );
//   }
// }