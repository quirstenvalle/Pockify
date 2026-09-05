import 'package:flutter/material.dart';

import '../finance_models.dart';

IconData categoryMaterialIcon(String name) {
  switch (name) {
    case 'Food':
      return Icons.restaurant_rounded;
    case 'Transportation':
      return Icons.directions_bus_rounded;
    case 'Grocery':
      return Icons.local_grocery_store_rounded;
    case 'Shopping':
      return Icons.shopping_bag_rounded;
    case 'Entertainment':
      return Icons.movie_rounded;
    case 'Bills':
      return Icons.receipt_long_rounded;
    case 'Healthcare':
      return Icons.medical_services_rounded;
    case 'Education':
      return Icons.menu_book_rounded;
    case 'Savings':
      return Icons.account_balance_rounded;
    case 'Coffee':
      return Icons.coffee_rounded;
    case 'Pet Expenses':
      return Icons.pets_rounded;
    case 'Income':
      return Icons.payments_rounded;
    case 'Others':
    default:
      return Icons.category_rounded;
  }
}

/// Material icon for a category — keeps text baselines stable on Android.
class CategoryIcon extends StatelessWidget {
  const CategoryIcon(
    this.name, {
    super.key,
    this.size = 18,
    this.color,
  });

  final String name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cat = categoryOf(name);
    return Icon(
      categoryMaterialIcon(cat.name),
      size: size,
      color: color ?? _colorFromHex(cat.color),
    );
  }
}

class CategoryChipLabel extends StatelessWidget {
  const CategoryChipLabel({
    super.key,
    required this.name,
    this.style,
  });

  final String name;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ??
        Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.3,
              letterSpacing: 0,
            );
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CategoryIcon(name, size: (base?.fontSize ?? 13) + 2),
        const SizedBox(width: 6),
        Text(name, style: base),
      ],
    );
  }
}

Color _colorFromHex(String hexString) {
  final cleaned = hexString.replaceFirst('#', '');
  final value = cleaned.length == 6 ? cleaned : 'FF$cleaned';
  return Color(int.parse(value, radix: 16) + 0xFF000000);
}
