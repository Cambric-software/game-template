import 'package:flutter/material.dart';

import '../../save/save_data.dart';
import '../../save/save_service.dart';

/// Ready-to-use save slot selection widget.
///
/// Shows all default save slots with name, playtime, and date.
/// The player taps a slot to load it or selects New Game on an empty slot.
///
/// Usage:
/// ```dart
/// SaveSlotWidget(
///   onSlotSelected: (slot, data) async {
///     if (data != null) {
///       // Load the save
///     } else {
///       // Start new game in this slot
///     }
///   },
/// )
/// ```
class SaveSlotWidget extends StatefulWidget {
  const SaveSlotWidget({
    required this.onSlotSelected,
    this.title = 'Save Files',
    this.showDeleteButton = true,
    super.key,
  });

  final void Function(SaveSlot slot, SaveData? data) onSlotSelected;
  final String title;
  final bool showDeleteButton;

  @override
  State<SaveSlotWidget> createState() => _SaveSlotWidgetState();
}

class _SaveSlotWidgetState extends State<SaveSlotWidget> {
  final SaveService _saves = SaveService();
  List<SaveSlotInfo>? _slots;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    try {
      final slots = await _saves.listSlots();
      if (mounted) setState(() { _slots = slots; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _deleteSlot(SaveSlot slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete save?'),
        content: Text('Delete "${slot.displayName}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _saves.deleteSave(slot);
      _loadSlots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            widget.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_error != null)
          Center(child: Text('Error loading saves: $_error'))
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _slots!.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) => _SlotTile(
              info: _slots![i],
              onTap: () => widget.onSlotSelected(_slots![i].slot, _slots![i].data),
              onDelete: widget.showDeleteButton && !_slots![i].isEmpty
                  ? () => _deleteSlot(_slots![i].slot)
                  : null,
            ),
          ),
      ],
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.info,
    required this.onTap,
    this.onDelete,
  });

  final SaveSlotInfo info;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isEmpty = info.isEmpty;
    final data    = info.data;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: isEmpty
            ? Colors.grey.shade800
            : Theme.of(context).colorScheme.primary,
        child: Icon(
          isEmpty ? Icons.add : Icons.sports_esports,
          color: Colors.white,
          size: 20,
        ),
      ),
      title: Text(
        isEmpty ? '${info.slot.displayName} — Empty' : info.slot.displayName,
        style: TextStyle(
          color: isEmpty ? Colors.grey : null,
          fontWeight: isEmpty ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: isEmpty
          ? const Text('Start new game')
          : Text(
              '${data!.playtimeDisplay}  •  '
              '${_formatDate(data.updatedAt)}',
            ),
      trailing: onDelete != null
          ? IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: onDelete,
              tooltip: 'Delete save',
            )
          : const Icon(Icons.chevron_right),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}';
  }
}
