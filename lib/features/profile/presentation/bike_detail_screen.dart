import 'dart:io';

import 'package:ebikemanager/core/database/repositories/drift_bike_repository.dart';
import 'package:ebikemanager/core/domain/bike_selection_providers.dart';
import 'package:ebikemanager/core/domain/entities/bike.dart';
import 'package:ebikemanager/core/files/image_picker_service.dart';
import 'package:ebikemanager/core/files/local_image_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

String? _requiredValidator(String? value) =>
    (value == null || value.trim().isEmpty) ? 'This field is required' : null;

String? _integerValidator(String? value) {
  if (value == null || value.isEmpty) return null;
  return int.tryParse(value) == null ? 'Enter a whole number' : null;
}

String? _numericValidator(String? value) {
  if (value == null || value.isEmpty) return null;
  return double.tryParse(value) == null ? 'Enter a number' : null;
}

/// Route sentinel for the "add a bike" path segment (`/profile/bikes/new`).
const newBikeRouteId = 'new';

class BikeDetailScreen extends ConsumerWidget {
  const BikeDetailScreen({required this.bikeId, super.key});

  final String bikeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (bikeId == newBikeRouteId) {
      return const _BikeFormScreen(bike: null);
    }

    final bikeAsync = ref.watch(bikeByIdProvider(bikeId));
    return bikeAsync.when(
      data: (bike) {
        if (bike == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Bike')),
            body: const Center(child: Text('Bike not found.')),
          );
        }
        return _BikeFormScreen(bike: bike);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Bike')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: const Text('Bike')),
        body: Center(child: Text('Failed to load bike: $error')),
      ),
    );
  }
}

class _BikeFormScreen extends ConsumerStatefulWidget {
  const _BikeFormScreen({required this.bike});

  /// `null` means "creating a new bike".
  final Bike? bike;

  @override
  ConsumerState<_BikeFormScreen> createState() => _BikeFormScreenState();
}

class _BikeFormScreenState extends ConsumerState<_BikeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nickname = TextEditingController(text: widget.bike?.nickname);
  late final _manufacturer = TextEditingController(
    text: widget.bike?.manufacturer,
  );
  late final _model = TextEditingController(text: widget.bike?.model);
  late final _colour = TextEditingController(text: widget.bike?.colour);
  late final _purchasePrice = TextEditingController(
    text: widget.bike?.purchasePriceCents == null
        ? null
        : (widget.bike!.purchasePriceCents! / 100).toStringAsFixed(2),
  );
  late final _frameSize = TextEditingController(text: widget.bike?.frameSize);
  late final _wheelSize = TextEditingController(text: widget.bike?.wheelSize);
  late final _motorType = TextEditingController(text: widget.bike?.motorType);
  late final _motorWattage = TextEditingController(
    text: widget.bike?.motorWattage?.toString(),
  );
  late final _batteryCapacityWh = TextEditingController(
    text: widget.bike?.batteryCapacityWh?.toString(),
  );
  late final _adfcCode = TextEditingController(text: widget.bike?.adfcCode);
  late final _notes = TextEditingController(text: widget.bike?.notes);

  late DateTime? _purchaseDate = widget.bike?.purchaseDate;
  late DateTime? _batteryPurchaseDate = widget.bike?.batteryPurchaseDate;
  late String? _photoPath = widget.bike?.photoPath;
  late String? _adfcPhotoPath = widget.bike?.adfcCodePhotoPath;
  var _saving = false;

  bool get _isNew => widget.bike == null;

  @override
  void dispose() {
    for (final controller in [
      _nickname,
      _manufacturer,
      _model,
      _colour,
      _purchasePrice,
      _frameSize,
      _wheelSize,
      _motorType,
      _motorWattage,
      _batteryCapacityWh,
      _adfcCode,
      _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Add bike' : widget.bike!.nickname),
        actions: [
          if (!_isNew) _BikeMenu(bike: widget.bike!),
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            tooltip: 'Save',
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _PhotoField(
              label: 'Bike photo',
              photoPath: _photoPath,
              allowGallery: true,
              onChanged: (path) => setState(() => _photoPath = path),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nickname,
              decoration: const InputDecoration(labelText: 'Nickname *'),
              validator: _requiredValidator,
            ),
            TextFormField(
              controller: _manufacturer,
              decoration: const InputDecoration(labelText: 'Manufacturer'),
            ),
            TextFormField(
              controller: _model,
              decoration: const InputDecoration(labelText: 'Model'),
            ),
            TextFormField(
              controller: _colour,
              decoration: const InputDecoration(labelText: 'Colour'),
            ),
            _DateField(
              label: 'Purchase date',
              value: _purchaseDate,
              onChanged: (value) => setState(() => _purchaseDate = value),
            ),
            TextFormField(
              controller: _purchasePrice,
              decoration: const InputDecoration(
                labelText: 'Purchase price (€)',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: _numericValidator,
            ),
            const Divider(height: 32),
            TextFormField(
              controller: _frameSize,
              decoration: const InputDecoration(labelText: 'Frame size'),
            ),
            TextFormField(
              controller: _wheelSize,
              decoration: const InputDecoration(labelText: 'Wheel size'),
            ),
            TextFormField(
              controller: _motorType,
              decoration: const InputDecoration(labelText: 'Motor type'),
            ),
            TextFormField(
              controller: _motorWattage,
              decoration: const InputDecoration(labelText: 'Motor wattage (W)'),
              keyboardType: TextInputType.number,
              validator: _integerValidator,
            ),
            TextFormField(
              controller: _batteryCapacityWh,
              decoration: const InputDecoration(
                labelText: 'Battery capacity (Wh)',
              ),
              keyboardType: TextInputType.number,
              validator: _integerValidator,
            ),
            _DateField(
              label: 'Battery purchase date',
              value: _batteryPurchaseDate,
              onChanged: (value) =>
                  setState(() => _batteryPurchaseDate = value),
            ),
            const Divider(height: 32),
            TextFormField(
              controller: _adfcCode,
              decoration: const InputDecoration(
                labelText: 'ADFC code',
                helperText: 'Free text — formats vary by region',
              ),
            ),
            const SizedBox(height: 8),
            _PhotoField(
              label: 'Frame engraving photo',
              photoPath: _adfcPhotoPath,
              allowGallery: false,
              onChanged: (path) => setState(() => _adfcPhotoPath = path),
            ),
            const Divider(height: 32),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final now = DateTime.now();
    final purchasePrice = double.tryParse(_purchasePrice.text);

    final bike = Bike(
      id: widget.bike?.id ?? const Uuid().v4(),
      nickname: _nickname.text.trim(),
      createdAt: widget.bike?.createdAt ?? now,
      updatedAt: now,
      manufacturer: _blankToNull(_manufacturer.text),
      model: _blankToNull(_model.text),
      colour: _blankToNull(_colour.text),
      purchaseDate: _purchaseDate,
      adfcCode: _blankToNull(_adfcCode.text),
      adfcCodePhotoPath: _adfcPhotoPath,
      frameSize: _blankToNull(_frameSize.text),
      wheelSize: _blankToNull(_wheelSize.text),
      motorType: _blankToNull(_motorType.text),
      motorWattage: int.tryParse(_motorWattage.text),
      batteryCapacityWh: int.tryParse(_batteryCapacityWh.text),
      batteryPurchaseDate: _batteryPurchaseDate,
      purchasePriceCents: purchasePrice == null
          ? null
          : (purchasePrice * 100).round(),
      photoPath: _photoPath,
      notes: _blankToNull(_notes.text),
      isArchived: widget.bike?.isArchived ?? false,
    );

    await ref.read(bikeRepositoryProvider).saveBike(bike);
    if (!mounted) return;
    if (_isNew) {
      context.go('/profile/bikes/${bike.id}');
    } else {
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bike saved')));
    }
  }

  static String? _blankToNull(String value) =>
      value.trim().isEmpty ? null : value.trim();
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? ''
        : '${value!.year}-${value!.month.toString().padLeft(2, '0')}-'
              '${value!.day.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(1970),
          lastDate: DateTime.now(),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: value == null
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => onChanged(null),
                ),
        ),
        child: Text(text),
      ),
    );
  }
}

class _BikeMenu extends ConsumerWidget {
  const _BikeMenu({required this.bike});

  final Bike bike;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      onSelected: (action) async {
        switch (action) {
          case 'archive':
            await ref
                .read(bikeRepositoryProvider)
                .saveBike(bike.copyWith(isArchived: !bike.isArchived));
          case 'delete':
            await _confirmDelete(context, ref);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'archive',
          child: Text(bike.isArchived ? 'Unarchive' : 'Archive'),
        ),
        const PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${bike.nickname}?'),
        content: const Text(
          'This also permanently deletes all of its trips, battery '
          "history, and parking pins. This can't be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(bikeRepositoryProvider).deleteBike(bike.id);
    if (context.mounted) context.go('/profile/bikes');
  }
}

class _PhotoField extends ConsumerWidget {
  const _PhotoField({
    required this.label,
    required this.photoPath,
    required this.allowGallery,
    required this.onChanged,
  });

  final String label;
  final String? photoPath;
  final bool allowGallery;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        _Thumbnail(photoPath: photoPath),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () => _pick(context, ref),
                    child: Text(photoPath == null ? 'Add photo' : 'Change'),
                  ),
                  if (photoPath != null)
                    TextButton(
                      onPressed: () => onChanged(null),
                      child: const Text('Remove'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final picker = ref.read(imagePickerServiceProvider);
    final source = allowGallery
        ? await showModalBottomSheet<String>(
            context: context,
            builder: (context) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.photo_camera),
                    title: const Text('Take photo'),
                    onTap: () => Navigator.of(context).pop('camera'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('Choose from gallery'),
                    onTap: () => Navigator.of(context).pop('gallery'),
                  ),
                ],
              ),
            ),
          )
        : 'camera';
    if (source == null) return;

    final picked = source == 'camera'
        ? await picker.pickFromCamera()
        : await picker.pickFromGallery();
    if (picked == null) return;

    final savedPath = await ref
        .read(localImageStoreProvider)
        .save(
          picked,
          category: allowGallery ? 'bike_photos' : 'adfc_photos',
          previousPath: photoPath,
        );
    onChanged(savedPath);
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.photoPath});

  final String? photoPath;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 64,
        height: 64,
        child: photoPath == null
            ? ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.image_outlined),
              )
            : Image.file(File(photoPath!), fit: BoxFit.cover),
      ),
    );
  }
}
