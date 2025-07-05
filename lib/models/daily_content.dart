// lib/models/daily_content.dart
enum QuestionLevel { easy, medium, hard }

class Question {
  final String id;
  final String text;

  const Question({required this.id, required this.text});

  // Методы для сериализации/десериализации
  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
      };

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      text: json['text'],
    );
  }
}

enum TaskLevel { easy, medium, hard }

class Task {
  final String id;
  final String text;
  final String sphere; // Например: "Здоровье", "Финансы", "Обучение"

  const Task({required this.id, required this.text, required this.sphere});

  // Методы для сериализации/десериализации
  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'sphere': sphere,
      };

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      text: json['text'],
      sphere: json['sphere'],
    );
  }
}
