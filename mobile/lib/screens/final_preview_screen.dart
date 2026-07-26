import 'package:flutter/material.dart';
import '../models/photo_model.dart';
import '../services/session_service.dart';
import '../services/api_client.dart';
import '../utils/booth_draft.dart';
import '../utils/theme.dart';
import '../widgets/primary_button.dart';
import 'home_shell.dart';

class FinalPreviewScreen extends StatefulWidget {
  final BoothDraft draft;
  const FinalPreviewScreen({super.key, required this.draft});

  @override
  State<FinalPreviewScreen> createState() => _FinalPreviewScreenState();
}

class _FinalPreviewScreenState extends State<FinalPreviewScreen> {
  final _titleController = TextEditingController(text: 'Photobooth Session');
  bool _isSaving = false;

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final photos = <PhotoModel>[];

      for (var i = 0; i < widget.draft.capturedPhotos.length; i++) {
        final file = widget.draft.capturedPhotos[i];
        final uploadRes = await ApiClient.uploadImage('/uploads', file.path);
        photos.add(
          PhotoModel(
            id: 0,
            sessionId: 0,
            imagePath: uploadRes['data']['path'],
            orderIndex: i,
            filterId: widget.draft.colorFilterId ?? widget.draft.vibeFilterId,
            beautySmooth: widget.draft.beautySmooth,
            beautyBrighten: widget.draft.beautyBrighten,
          ),
        );
      }

      await SessionService.create(
        frameId: widget.draft.frameId,
        title: _titleController.text.trim().isEmpty
            ? 'Photobooth Session'
            : _titleController.text.trim(),
        layoutType: widget.draft.layoutType,
        photos: photos,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Strip berhasil disimpan ke My Gallery 🎉')));
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeShell()),
        (route) => false,
      );
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal menyimpan strip: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    return Scaffold(
      appBar: AppBar(title: const Text('Final Preview')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
                  ],
                ),
                child: GridView.builder(
                  itemCount: draft.capturedPhotos.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemBuilder: (context, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(draft.capturedPhotos[i], fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Frame: ${draft.frameName ?? "-"}  •  Filter: ${draft.colorFilterName ?? "-"}  •  Vibe: ${draft.vibeFilterName ?? "-"}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Judul Strip',
                prefixIcon: Icon(Icons.edit_outlined),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Simpan ke My Gallery',
              icon: Icons.save_alt,
              isLoading: _isSaving,
              onPressed: draft.capturedPhotos.isEmpty ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
