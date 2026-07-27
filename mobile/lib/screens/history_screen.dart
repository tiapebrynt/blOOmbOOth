import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/history_model.dart';
import '../services/hive_service.dart';
import '../utils/theme.dart';
import '../widgets/state_views.dart';

/// Screen untuk menampilkan, mengedit, dan menghapus riwayat (history)
/// photobooth yang disimpan di Hive lokal (database offline).
///
/// Fitur:
/// - READ: Daftar history dalam ListView (pull-to-refresh & search)
/// - UPDATE: Edit judul/note via dialog
/// - DELETE: Hapus item dengan konfirmasi (tombol & swipe-to-delete)
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryModel> _historyList = [];
  bool _isLoading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  /// Memuat semua history dari Hive, dengan filter pencarian jika ada.
  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final data = await HiveService.searchHistory(_query);
      if (mounted) setState(() => _historyList = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat history: $e'),
            margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===================== UPDATE (Edit Title) =====================

  /// Menampilkan dialog untuk mengedit judul history.
  Future<void> _editTitle(HistoryModel history) async {
    final controller = TextEditingController(text: history.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Judul'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Masukkan judul baru...',
            prefixIcon: Icon(Icons.edit),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty && newTitle != history.title) {
      try {
        await HiveService.updateHistory(id: history.id, title: newTitle);
        await _loadHistory();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Judul berhasil diperbarui!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(top: 80, left: 16, right: 16),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mengupdate: $e'),
              margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16),
            ),
          );
        }
      }
    }
  }

  // ===================== DELETE =====================

  /// Konfirmasi dan hapus satu item history.
  Future<void> _confirmDelete(HistoryModel history) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus History?'),
        content: Text('Apakah Anda yakin ingin menghapus\n"${history.title}"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await HiveService.deleteHistory(history.id);
        await _loadHistory();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('History berhasil dihapus'),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(top: 80, left: 16, right: 16),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus: $e'),
              margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16),
            ),
          );
        }
      }
    }
  }

  /// Hapus semua history (clear all).
  Future<void> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Semua History?'),
        content: const Text('Semua riwayat photobooth akan dihapus permanen.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await HiveService.clearAllHistory();
        await _loadHistory();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Semua history berhasil dihapus'),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(top: 80, left: 16, right: 16),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus: $e'),
              margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16),
            ),
          );
        }
      }
    }
  }

  // ===================== UI BUILD =====================

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'History',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                if (_historyList.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined),
                    tooltip: 'Hapus semua',
                    onPressed: _confirmClearAll,
                    color: Colors.redAccent,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Search field
            TextField(
              decoration: const InputDecoration(
                hintText: 'Cari history...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) {
                _query = v.toLowerCase();
                _loadHistory();
              },
            ),
            const SizedBox(height: 12),

            // Content
            Expanded(
              child: _isLoading
                  ? const LoadingView()
                  : _historyList.isEmpty
                      ? const EmptyView(
                          message: 'Belum ada history.\nSimpan photostrip untuk memulai!',
                          icon: Icons.history,
                        )
                      : RefreshIndicator(
                          onRefresh: _loadHistory,
                          child: ListView.separated(
                            itemCount: _historyList.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final history = _historyList[index];
                              return _HistoryTile(
                                history: history,
                                onEdit: () => _editTitle(history),
                                onDelete: () => _confirmDelete(history),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget tile untuk setiap item history di ListView.
class _HistoryTile extends StatelessWidget {
  final HistoryModel history;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HistoryTile({
    required this.history,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(history.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // Delete handled in callback
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 48,
              height: 48,
              child: history.imagePath.isNotEmpty
                  ? (history.imagePath.startsWith('http')
                      ? Image.network(history.imagePath, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _iconPlaceholder())
                      : Image.file(File(history.imagePath), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _iconPlaceholder()))
                  : _iconPlaceholder(),
            ),
          ),
          title: Text(
            history.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            _formatDate(history.createdAt),
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: onEdit,
                color: AppColors.primary,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: onDelete,
                color: Colors.redAccent,
              ),
            ],
          ),
          onTap: onEdit, // Tap untuk edit cepat
        ),
      ),
    );
  }

  Widget _iconPlaceholder() => Container(
        color: AppColors.secondary.withOpacity(0.15),
        child: const Icon(Icons.photo, color: AppColors.secondary, size: 24),
      );

  String _formatDate(String raw) {
    try {
      final date = DateTime.parse(raw);
      return DateFormat('d MMM yyyy, HH:mm').format(date);
    } catch (_) {
      return raw;
    }
  }
}

