import 'package:flutter/material.dart';
import 'package:my_reflection_app/screens/editor/ritual_editor_screen.dart';
import 'package:my_reflection_app/screens/editor/question_editor_screen.dart';
import 'package:my_reflection_app/screens/editor/task_editor_screen.dart';
import 'package:my_reflection_app/widgets/animated_background.dart';

class ContentEditorScreen extends StatelessWidget {
  const ContentEditorScreen({super.key});

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
              Card(
                child: ListTile(
                  leading: const Icon(Icons.wb_twilight_outlined),
                  title: const Text('Утренний ритуал'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RitualEditorScreen()));
                  },
                ),
              ),
              // Заглушки для будущих редакторов
              Card(
                child: ListTile(
                  leading: const Icon(Icons.question_answer_outlined),
                  title: const Text('Вопросы'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QuestionEditorScreen()));
                  },
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.checklist_rtl_outlined),
                  title: const Text('Задания'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TaskEditorScreen()));
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}