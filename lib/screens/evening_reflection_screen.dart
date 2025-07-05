import 'package:flutter/material.dart';
import 'package:my_reflection_app/widgets/animated_background.dart';

class EveningReflectionScreen extends StatelessWidget {
  const EveningReflectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        AnimatedBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: Text('Экран вечерней рефлексии')),
        ),
      ],
    );
  }
}