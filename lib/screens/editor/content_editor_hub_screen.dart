import 'package:flutter/material.dart';
import 'package:my_reflection_app/screens/editor/question_editor_screen.dart';
import 'package:my_reflection_app/screens/editor/ritual_editor_screen.dart';
import 'package:my_reflection_app/screens/editor/task_editor_screen.dart';
import 'package:my_reflection_app/widgets/animated_background.dart';

class ContentEditorHubScreen extends StatelessWidget {
  const ContentEditorHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const AnimatedBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Редактор контента'),
            backgroundColor: Colors.transparent,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                title: const Text('Редактировать утренний ритуал'),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RitualEditorScreen())),
              ),
              ListTile(
                title: const Text('Редактировать вопросы'),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QuestionEditorScreen())),
              ),
              ListTile(
                title: const Text('Редактировать задания'),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TaskEditorScreen())),
              ),
            ],
          ),
        ),
      ],
    );
  }
}