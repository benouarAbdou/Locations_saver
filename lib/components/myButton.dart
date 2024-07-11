import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final String hint;
  final Function function;
  const MyButton({
    super.key,
    required this.hint,
    required this.function,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => function(),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2496ff),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(hint),
    );
  }
}
