import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Circular profile photo with letter fallback.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.radius = 28,
    this.bytes,
  });

  final String name;
  final String? avatarUrl;
  final double radius;
  final Uint8List? bytes;

  String get _initial {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'P';
    return trimmed.substring(0, 1).toUpperCase();
  }

  ImageProvider? get _provider {
    if (bytes != null && bytes!.isNotEmpty) {
      return MemoryImage(bytes!);
    }
    final url = avatarUrl?.trim();
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('data:image')) {
      final comma = url.indexOf(',');
      if (comma == -1) return null;
      try {
        return MemoryImage(base64Decode(url.substring(comma + 1)));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(url);
  }

  @override
  Widget build(BuildContext context) {
    final provider = _provider;
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFF39A42),
      backgroundImage: provider,
      onBackgroundImageError: provider == null ? null : (_, _) {},
      child: provider == null
          ? Text(
              _initial,
              style: TextStyle(
                color: Colors.white,
                fontSize: radius * 0.9,
                fontWeight: FontWeight.w900,
              ),
            )
          : null,
    );
  }
}
