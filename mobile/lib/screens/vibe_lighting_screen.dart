import 'package:flutter/material.dart';
import '../models/filter_model.dart';
import '../services/filter_service.dart';
import '../services/api_client.dart';
import '../utils/booth_draft.dart';
import '../utils/theme.dart';
import '../widgets/state_views.dart';
import '../widgets/primary_button.dart';


class VibeLightingScreen extends StatefulWidget {
  final BoothDraft draft;
  const VibeLightingScreen({super.key, required this.draft});

  @override
  State<VibeLightingScreen> createState() => _VibeLightingScreenState();
}

class _VibeLightingScreenState extends State<VibeLightingScreen> {
  late Future<List<FilterModel>> _future;
  FilterModel? _selected;
  double _intensity = 0.5;

  @override
  void initState() {
    super.initState();
    _intensity = widget.draft.vibeIntensity;
    _future = FilterService.getAll(type: 'vibe_lighting');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vibe Lighting')),
      body: FutureBuilder<List<FilterModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const LoadingView();
          if (snapshot.hasError) {
            return ErrorView(
              message: snapshot.error is ApiException
                  ? (snapshot.error as ApiException).message
                  : 'Gagal memuat daftar vibe lighting.',
              onRetry: () =>
                  setState(() => _future = FilterService.getAll(type: 'vibe_lighting')),
            );
          }
          final filters = snapshot.data ?? [];
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: filters.isEmpty
                      ? const EmptyView(message: 'Belum ada vibe lighting tersedia')
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                          itemCount: filters.length,
                          itemBuilder: (context, i) {
                            final filter = filters[i];
                            final isSelected = filter.id == _selected?.id;
                            return GestureDetector(
                              onTap: () => setState(() => _selected = filter),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.wb_sunny_outlined,
                                        color: isSelected ? Colors.white : AppColors.secondary),
                                    const SizedBox(height: 6),
                                    Text(
                                      filter.name,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isSelected ? Colors.white : AppColors.textDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 16),
                const Text('Intensitas Cahaya', style: TextStyle(fontWeight: FontWeight.w600)),
                Slider(
                  value: _intensity,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _intensity = v),
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'Lanjut ke Beauty Enhancement',
                  onPressed: () {
                    widget.draft.vibeFilterId = _selected?.id;
                    widget.draft.vibeFilterName = _selected?.name;
                    widget.draft.vibeIntensity = _intensity;
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
