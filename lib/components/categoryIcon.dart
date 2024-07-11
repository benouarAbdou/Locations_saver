import 'package:flutter/material.dart';

class CategoryIcon extends StatelessWidget {
  final String category;
  const CategoryIcon({super.key, required this.category});
  Widget _buildCategoryIcon(String category) {
    IconData iconData;
    Color color;

    switch (category) {
      case 'work':
        iconData = Icons.work;
        color = Colors.blue;
        break;
      case 'food':
        iconData = Icons.restaurant;
        color = Colors.amber;
        break;
      case 'travel':
        iconData = Icons.flight;
        color = Colors.green;
        break;
      case 'family':
        iconData = Icons.family_restroom;
        color = Colors.purple;
        break;
      case 'friends':
        iconData = Icons.group;
        color = Colors.red;
        break;
      case 'other':
      default:
        iconData = Icons.place;
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: color, size: 24),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildCategoryIcon(category);
  }
}
