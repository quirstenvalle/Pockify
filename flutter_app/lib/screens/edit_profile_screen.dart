import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../auth/auth_models.dart';
import '../auth/auth_service.dart';
import '../data/countries.dart';
import '../finance_models.dart' show setActiveCurrency;
import '../widgets/country_picker.dart';
import '../widgets/profile_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.user,
    required this.onSaved,
  });

  final AuthUser user;
  final ValueChanged<AuthUser> onSaved;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _incomeController = TextEditingController();
  final _budgetGoalController = TextEditingController();

  String? _country;
  late String _employmentStatus;
  DateTime? _birthDate;
  Uint8List? _avatarBytes;
  String? _avatarContentType;
  bool _saving = false;
  bool _pickingImage = false;

  static const _employmentOptions = [
    'Select status',
    'Employed',
    'Self-employed',
    'Student',
    'Unemployed',
  ];

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _nameController.text = user.name;
    _country = user.country;
    _employmentStatus = _employmentOptions.contains(user.employmentStatus)
        ? user.employmentStatus!
        : 'Select status';
    _birthDate = user.birthDate;
    if (user.monthlyIncome != null) {
      _incomeController.text = _trimMoney(user.monthlyIncome!);
    }
    if (user.monthlyBudgetGoal != null) {
      _budgetGoalController.text = _trimMoney(user.monthlyBudgetGoal!);
    }
  }

  Future<void> _pickCountry() async {
    final selected = await showCountryPicker(context, initial: _country);
    if (selected == null || !mounted) return;
    setState(() => _country = selected);
  }

  String _trimMoney(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _incomeController.dispose();
    _budgetGoalController.dispose();
    super.dispose();
  }

  Future<ImageSource?> _chooseImageSource() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAvatar() async {
    if (_pickingImage || _saving) return;

    final source = await _chooseImageSource();
    if (source == null) return;

    setState(() => _pickingImage = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not read that image. Try another photo.'),
          ),
        );
        return;
      }

      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image is too large. Choose a photo under 5 MB.'),
          ),
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        _avatarBytes = bytes;
        final name = picked.name.toLowerCase();
        final mime = picked.mimeType?.toLowerCase();
        if (mime == 'image/png' || name.endsWith('.png')) {
          _avatarContentType = 'image/png';
        } else if (mime == 'image/webp' || name.endsWith('.webp')) {
          _avatarContentType = 'image/webp';
        } else if (mime == 'image/gif' || name.endsWith('.gif')) {
          _avatarContentType = 'image/gif';
        } else {
          _avatarContentType = 'image/jpeg';
        }
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick image. $error')),
      );
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 18),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked == null || !mounted) return;
    setState(() => _birthDate = picked);
  }

  String get _birthDateLabel {
    if (_birthDate == null) return 'mm/dd/yyyy';
    final d = _birthDate!;
    return '${d.month.toString().padLeft(2, '0')}/'
        '${d.day.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  double? _parseMoney(String raw) {
    final cleaned = raw.trim().replaceAll(',', '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final result = await AuthService.instance.updateProfile(
        name: name,
        currency: _country == null ? null : currencyCodeForCountry(_country!),
        country: _country,
        employmentStatus: _employmentStatus,
        birthDate: _birthDate,
        monthlyIncome: _parseMoney(_incomeController.text),
        monthlyBudgetGoal: _parseMoney(_budgetGoalController.text),
        avatarBytes: _avatarBytes,
        avatarContentType: _avatarContentType ?? 'image/jpeg',
      );
      if (!mounted) return;
      if (!result.ok || result.user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Could not save profile.'),
          ),
        );
        return;
      }
      setActiveCurrency(result.user!.currency);
      widget.onSaved(result.user!);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _input(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF7F5F1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCFA),
      appBar: AppBar(
        title: const Text('Edit profile'),
        backgroundColor: const Color(0xFFFDFCFA),
        foregroundColor: const Color(0xFF1F1F1F),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(
            child: Stack(
              children: [
                ProfileAvatar(
                  name: _nameController.text.isEmpty
                      ? widget.user.name
                      : _nameController.text,
                  avatarUrl: widget.user.avatarUrl,
                  bytes: _avatarBytes,
                  radius: 48,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Material(
                    color: const Color(0xFFFF7F20),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: (_saving || _pickingImage) ? null : _pickAvatar,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: (_saving || _pickingImage) ? null : _pickAvatar,
            child: Text(
              _pickingImage ? 'Opening gallery...' : 'Change profile picture',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Full name',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: _input('Your name'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          const Text(
            'Email',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          InputDecorator(
            decoration: _input(''),
            child: Text(
              widget.user.email,
              style: const TextStyle(color: Color(0xFF77736C)),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Country / Region',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: _saving ? null : _pickCountry,
            borderRadius: BorderRadius.circular(16),
            child: InputDecorator(
              decoration: _input('Select country').copyWith(
                suffixIcon: const Icon(Icons.expand_more, size: 18),
              ),
              child: Text(
                _country ?? 'Select country',
                style: TextStyle(
                  color: _country == null
                      ? const Color(0xFF9A958C)
                      : const Color(0xFF1F1F1F),
                ),
              ),
            ),
          ),
          if (_country != null) ...[
            const SizedBox(height: 6),
            Text(
              'Currency: ${currencySymbolForCurrency(currencyCodeForCountry(_country!))} '
              '${currencyCodeForCountry(_country!)}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF77736C)),
            ),
          ],
          const SizedBox(height: 14),
          const Text(
            'Employment status',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _employmentStatus,
            items: _employmentOptions
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: _saving
                ? null
                : (value) => setState(
                      () => _employmentStatus = value ?? _employmentStatus,
                    ),
            decoration: _input('Select status'),
          ),
          const SizedBox(height: 14),
          const Text(
            'Birth date',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: _saving ? null : _pickBirthDate,
            borderRadius: BorderRadius.circular(16),
            child: InputDecorator(
              decoration: _input('mm/dd/yyyy').copyWith(
                suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
              ),
              child: Text(
                _birthDateLabel,
                style: TextStyle(
                  color: _birthDate == null
                      ? const Color(0xFF9A958C)
                      : const Color(0xFF1F1F1F),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Monthly income',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _incomeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _input('0.00'),
          ),
          const SizedBox(height: 14),
          const Text(
            'Monthly budget goal',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _budgetGoalController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _input('0.00'),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF7F20),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(_saving ? 'Saving...' : 'Save changes'),
            ),
          ),
        ],
      ),
    );
  }
}
