import 'package:flutter/material.dart';

class AppTheme {
  // Приватный конструктор, чтобы нельзя было создать экземпляр класса
  AppTheme._();

  static final ThemeData lightTheme = ThemeData(
    // Используем ColorScheme.fromSeed для автоматического создания
    // гармоничной цветовой палитры на основе одного "основного" цвета.
    // Можете поэкспериментировать с разными цветами!
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4), // Приятный фиолетовый
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.transparent,
    useMaterial3: true,

    // Настроим внешний вид карточек
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // Настроим внешний вид AppBar
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent, // Сделаем его прозрачным для фона
    ),
  );

  static final ThemeData darkTheme = () {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4), // Тот же фиолетовый для темной темы
      brightness: Brightness.dark,
    );
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      useMaterial3: true,

      // Прозрачный фон, чтобы был виден наш анимированный фон
      scaffoldBackgroundColor: Colors.transparent,

      // Карточки с цветом, основанным на теме, для создания эффекта "парения"
      cardTheme: CardThemeData(
        elevation: 2,
        // Используем цвет `surfaceVariant` из сгенерированной палитры.
        // Это нейтральный цвет для карточек, которые не имеют специального градиента.
        color: colorScheme.surfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.1)), // Едва заметная рамка
        ),
      ),

      // AppBar также должен быть прозрачным
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
    );
  }();
}