import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Icon icon;
  final bool obscure;
  final TextInputType type;
  final String errorText;

  const MyTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    required this.icon,
    required this.type,
    required this.errorText,
    this.obscure = false, // Default value for obscure
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      obscureText: obscure,
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey), // Hint text color
        filled: true, // To make the background filled
        fillColor: const Color(0xFFf0f5fe), // Background color
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0), // Rounded corners
          borderSide: BorderSide.none, // No border
        ),
        contentPadding: const EdgeInsets.symmetric(
            vertical: 20.0, horizontal: 20.0), // Padding inside the field
        prefixIcon: icon, // Icon inside the field
      ),
      keyboardType: type,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return errorText;
        }
        return null;
      },
    );
  }
}
