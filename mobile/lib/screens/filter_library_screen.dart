import 'package:flutter/material.dart';

// Model data filter
import '../models/filter_model.dart';

// Service untuk mengambil data filter dari API
import '../services/filter_service.dart';

// Menangani exception dari API
import '../services/api_client.dart';

// Menyimpan data sementara (draft) selama proses photobooth
import '../utils/booth_draft.dart';

// Tema dan warna aplikasi
import '../utils/theme.dart';

// Widget untuk menampilkan Loading, Error, dan Empty State
import '../widgets/state_views.dart';

// Widget tombol utama yang digunakan di aplikasi
import '../widgets/primary_button.dart';

// Halaman selanjutnya setelah memilih filter
import 'vibe_lighting_screen.dart';

/// Halaman untuk menampilkan daftar filter yang tersedia
class FilterLibraryScreen extends StatefulWidget {

  /// Data sementara yang akan diteruskan ke halaman berikutnya
  final BoothDraft draft;

  const FilterLibraryScreen({super.key, required this.draft});

  @override
  State<FilterLibraryScreen> createState() => _FilterLibraryScreenState();
}

class _FilterLibraryScreenState extends State<FilterLibraryScreen> {

  /// Future yang digunakan untuk mengambil daftar filter dari API
  late Future<List<FilterModel>> _future;

  /// Filter yang sedang dipilih oleh user
  FilterModel? _selected;

  @override
  void initState() {
    super.initState();

    // Mengambil semua filter dengan tipe "color"
    _future = FilterService.getAll(type: 'color');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      // AppBar halaman
      appBar: AppBar(title: const Text('Filter Library')),

      // FutureBuilder digunakan untuk menunggu proses pengambilan data
      body: FutureBuilder<List<FilterModel>>(

        future: _future,

        builder: (context, snapshot) {

          // Menampilkan loading ketika data masih diproses
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView();
          }

          // Menampilkan halaman error jika gagal mengambil data
          if (snapshot.hasError) {
            return ErrorView(

              // Jika error berasal dari API tampilkan pesannya
              message: snapshot.error is ApiException
                  ? (snapshot.error as ApiException).message
                  : 'Gagal memuat daftar filter.',

              // Tombol retry untuk mencoba mengambil data kembali
              onRetry: () => setState(() =>
                  _future = FilterService.getAll(type: 'color')),
            );
          }

          // Mengambil data filter
          final filters = snapshot.data ?? [];

          return Padding(
            padding: const EdgeInsets.all(16),

            child: Column(
              children: [

                // Daftar filter
                Expanded(
                  child: filters.isEmpty

                      // Jika tidak ada filter
                      ? const EmptyView(
                          message: 'Belum ada filter tersedia')

                      // Jika ada filter
                      : ListView.separated(

                          // Jumlah item
                          itemCount: filters.length,

                          // Jarak antar item
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),

                          // Membuat setiap item filter
                          itemBuilder: (context, i) {

                            final filter = filters[i];

                            // Mengecek apakah filter sedang dipilih
                            final isSelected =
                                filter.id == _selected?.id;

                            return ListTile(

                              // Background item
                              tileColor: Colors.white,

                              // Border ketika dipilih
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(14),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),

                              // Icon filter
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppColors.secondary
                                        .withOpacity(0.15),
                                child: const Icon(
                                  Icons.color_lens,
                                  color: AppColors.secondary,
                                ),
                              ),

                              // Nama filter
                              title: Text(filter.name),

                              // Tanda centang jika filter dipilih
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: AppColors.primary,
                                    )
                                  : null,

                              // Ketika item ditekan
                              onTap: () => setState(() {

                                // Menyimpan filter yang dipilih
                                _selected = filter;

                              }),
                            );
                          },
                        ),
                ),

                const SizedBox(height: 12),

                // Tombol untuk lanjut ke halaman berikut
                PrimaryButton(

                  label: 'Lanjut ke Vibe Lighting',

                  onPressed: () {

                    // Menyimpan ID filter ke draft
                    widget.draft.colorFilterId = _selected?.id;

                    // Menyimpan nama filter ke draft
                    widget.draft.colorFilterName = _selected?.name;

                    // Berpindah ke halaman Vibe Lighting
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => VibeLightingScreen(
                          draft: widget.draft,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}