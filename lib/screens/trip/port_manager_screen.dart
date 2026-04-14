import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:bahaar/core/constants/app_colors.dart';
import 'package:bahaar/navigation/trip_database.dart';
import 'package:bahaar/navigation/trip_recorder.dart';

class PortManagerScreen extends StatefulWidget {
  const PortManagerScreen({super.key});

  @override
  State<PortManagerScreen> createState() => _PortManagerScreenState();
}

class _PortManagerScreenState extends State<PortManagerScreen> {
  List<Port> _ports = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _ports = await TripDatabase.instance.getAllPorts();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _add() async {
    final result = await showDialog<Port>(
      context: context,
      builder: (_) => const _PortDialog(),
    );
    if (result != null) {
      final id = await TripDatabase.instance.insertPort(result);
      final saved = result.copyWith(id: id);
      setState(() => _ports.add(saved));
      await TripRecorder.instance.refreshPorts();
    }
  }

  Future<void> _edit(Port port) async {
    final result = await showDialog<Port>(
      context: context,
      builder: (_) => _PortDialog(existing: port),
    );
    if (result != null) {
      await TripDatabase.instance.updatePort(result);
      await _load();
      await TripRecorder.instance.refreshPorts();
    }
  }

  Future<void> _delete(Port port) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Port'),
        content: Text('Delete "${port.name}"?\n\nThis cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await TripDatabase.instance.deletePort(port.id!);
        await _load();
        await TripRecorder.instance.refreshPorts();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: AppColors.red,
            content: Text(
              'Cannot delete — port is used by an active trip.',
              style: const TextStyle(color: Colors.white),
            ),
          ));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Saved Ports',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Port',
            onPressed: _add,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _ports.isEmpty
              ? _EmptyState(onAdd: _add)
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _ports.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) => _PortTile(
                    port: _ports[i],
                    onEdit:   () => _edit(_ports[i]),
                    onDelete: () => _delete(_ports[i]),
                  ),
                ),
      floatingActionButton: _ports.isEmpty
          ? null
          : FloatingActionButton(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: _add,
              child: const Icon(Icons.add),
            ),
    );
  }
}

// ─── Port tile ────────────────────────────────────────────────────────────────

class _PortTile extends StatelessWidget {
  final Port port;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PortTile({
    required this.port,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.anchor, color: AppColors.primary, size: 22),
        ),
        title: Text(port.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${port.lat.toStringAsFixed(5)}°, '
          '${port.lng.toStringAsFixed(5)}°'
          '${port.notes.isNotEmpty ? '\n${port.notes}' : ''}',
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
        isThreeLine: port.notes.isNotEmpty,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  size: 20, color: AppColors.accent),
              onPressed: onEdit,
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: Colors.redAccent),
              onPressed: onDelete,
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.anchor, size: 64,
                color: AppColors.accent),
            const SizedBox(height: 16),
            const Text('No ports saved yet.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text(
              'Add your departure port and any alternative ports '
              'you may need to return to. Ports are stored permanently '
              'on this device — only you can delete them.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add First Port'),
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add / Edit dialog ────────────────────────────────────────────────────────

class _PortDialog extends StatefulWidget {
  final Port? existing;
  const _PortDialog({this.existing});

  @override
  State<_PortDialog> createState() => _PortDialogState();
}

class _PortDialogState extends State<_PortDialog> {
  final _formKey   = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;
  late final TextEditingController _notesCtrl;
  bool _fetchingGps = false;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _nameCtrl  = TextEditingController(text: p?.name  ?? '');
    _latCtrl   = TextEditingController(
        text: p != null ? p.lat.toStringAsFixed(6) : '');
    _lngCtrl   = TextEditingController(
        text: p != null ? p.lng.toStringAsFixed(6) : '');
    _notesCtrl = TextEditingController(text: p?.notes ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _useGps() async {
    setState(() => _fetchingGps = true);
    try {
      final loc = Location();
      bool svc = await loc.serviceEnabled();
      if (!svc) svc = await loc.requestService();
      if (!svc) return;
      var perm = await loc.hasPermission();
      if (perm == PermissionStatus.denied) {
        perm = await loc.requestPermission();
      }
      if (perm != PermissionStatus.granted) return;
      final data = await loc.getLocation();
      if (data.latitude != null && data.longitude != null) {
        _latCtrl.text = data.latitude!.toStringAsFixed(6);
        _lngCtrl.text = data.longitude!.toStringAsFixed(6);
      }
    } finally {
      if (mounted) setState(() => _fetchingGps = false);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final lat = double.parse(_latCtrl.text.trim());
    final lng = double.parse(_lngCtrl.text.trim());
    final port = Port(
      id:        widget.existing?.id,
      name:      _nameCtrl.text.trim(),
      lat:       lat,
      lng:       lng,
      notes:     _notesCtrl.text.trim(),
      createdAt: widget.existing?.createdAt ?? DateTime.now().toUtc(),
    );
    Navigator.pop(context, port);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Port' : 'Add Port'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Port Name',
                  hintText: 'e.g. Manama Port',
                  prefixIcon: Icon(Icons.anchor),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        hintText: '26.2172',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[-0-9.]')),
                      ],
                      validator: (v) {
                        final d = double.tryParse(v ?? '');
                        if (d == null) return 'Invalid';
                        if (d < -90 || d > 90) return '−90 to 90';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _lngCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        hintText: '50.5860',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[-0-9.]')),
                      ],
                      validator: (v) {
                        final d = double.tryParse(v ?? '');
                        if (d == null) return 'Invalid';
                        if (d < -180 || d > 180) return '−180 to 180';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _fetchingGps ? null : _useGps,
                  icon: _fetchingGps
                      ? const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.gps_fixed, size: 16),
                  label: const Text('Use Current GPS'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary),
                ),
              ),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'e.g. Main fishing harbour',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: _save,
          child: Text(isEdit ? 'Save' : 'Add Port'),
        ),
      ],
    );
  }
}
