import 'package:flutter/material.dart';

class Terminal extends StatelessWidget {
  final TextEditingController controller;
  final bool visible;

  Terminal({required this.controller, required this.visible});

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: visible,
      child: Material(
        child: Container(
          padding: const EdgeInsets.all(10),
          color: Colors.black,
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            maxLines: 8,
            readOnly: true,
            decoration: const InputDecoration(
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }
}
