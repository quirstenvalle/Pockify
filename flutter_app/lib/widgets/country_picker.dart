import 'package:flutter/material.dart';

import '../data/countries.dart';

/// Opens a searchable bottom sheet listing every supported country/region.
/// Returns the selected country name, or null if dismissed.
Future<String?> showCountryPicker(
  BuildContext context, {
  String? initial,
}) {
  final countries = kCountryCurrencyCode.keys.toList()..sort();

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return _CountryPickerSheet(countries: countries, initial: initial);
    },
  );
}

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet({required this.countries, this.initial});

  final List<String> countries;
  final String? initial;

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  late List<String> _filtered = widget.countries;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final trimmed = query.trim().toLowerCase();
    setState(() {
      _filtered = trimmed.isEmpty
          ? widget.countries
          : widget.countries
                .where((country) => country.toLowerCase().contains(trimmed))
                .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8D3CB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Select country/region',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  autofocus: false,
                  decoration: InputDecoration(
                    hintText: 'Search country',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Color(0xFFD8D3CB)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _filtered.isEmpty
                    ? const Center(child: Text('No matching country'))
                    : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final country = _filtered[index];
                          final code = kCountryCurrencyCode[country] ?? '';
                          final selected = country == widget.initial;
                          return ListTile(
                            title: Text(country),
                            trailing: Text(
                              code,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6D6962),
                              ),
                            ),
                            selected: selected,
                            selectedTileColor: const Color(0xFFFFF1E6),
                            onTap: () => Navigator.pop(context, country),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
