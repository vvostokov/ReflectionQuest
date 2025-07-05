// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/daily_log.dart';
import '../services/database_service.dart';
import '../widgets/animated_background.dart';
import '../widgets/history/mood_charts.dart';
import '../widgets/history/weekly_progress_chart.dart';
import 'log_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseService _dbService = DatabaseService();
  // Используем Future<void> для отслеживания состояния загрузки, а данные храним в стейте
  late Future<void> _loadLogsFuture;
  List<DailyLog> _sortedLogs = [];
  Map<DateTime, List<DailyLog>> _logsByDate = {};

  final CalendarFormat _calendarFormat = CalendarFormat.month;
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    _loadLogsFuture = _fetchAndProcessLogs();
  }

  Future<void> _fetchAndProcessLogs() async {
    final logs = await _dbService.getAllLogs();
    logs.sort((a, b) => a.date.compareTo(b.date));
    _sortedLogs = logs;

    for (var log in logs) {
      final date = DateTime.parse(log.date).toLocal();
      final normalizedDate = DateTime(date.year, date.month, date.day);
      _logsByDate.putIfAbsent(normalizedDate, () => []).add(log);
    }
  }

  String _formatDate(String dateKey) {
    try {
      final date = DateTime.parse(dateKey);
      return DateFormat('d MMMM yyyy г.').format(date);
    } catch (e) {
      return dateKey; // Fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const AnimatedBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('История'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: FutureBuilder<void>(
            future: _loadLogsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Ошибка: ${snapshot.error}'));
              }
              if (_sortedLogs.isEmpty) {
                return const Center(
                  child: Text(
                    'Пока нет записей в истории.\nНачните выполнять задания!',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              // Нормализуем _selectedDay и _focusedDay для корректного поиска в карте
              final DateTime normalizedSelectedDay = _selectedDay != null
                  ? DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)
                  : DateTime(_focusedDay.year, _focusedDay.month, _focusedDay.day);

              final selectedLogs = _logsByDate[normalizedSelectedDay] ?? [];

              return SingleChildScrollView(
                child: Column(
                children: [
                  // Добавляем график прогресса за неделю
                  if (_sortedLogs.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: WeeklyProgressChart(logs: _sortedLogs),
                    ),
                  // Добавляем графики настроения
                  if (_sortedLogs.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    MoodCharts(logs: _sortedLogs),
                    const SizedBox(height: 24),
                  ],
                  TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.now(),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    eventLoader: (day) {
                      // Нормализуем день для поиска событий
                      final normalizedDay = DateTime(day.year, day.month, day.day);
                      return _logsByDate[normalizedDay] ?? [];
                    },
                    calendarStyle: CalendarStyle(
                      selectedDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  selectedLogs.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(child: Text('Нет записей за этот день')),
                        )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: selectedLogs.length,
                            itemBuilder: (context, index) {
                              final log = selectedLogs[index];
                              final isFullyCompleted = log.morningQuestionsCompleted &&
                                  log.afternoonQuestionsCompleted &&
                                  log.eveningQuestionsCompleted &&
                                  log.tasksCompleted;

                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                child: ListTile(
                                  title: Text(_formatDate(log.date)),
                                  subtitle: Text(isFullyCompleted ? 'Все задания выполнены' : 'Выполнено частично'),
                                  trailing: Icon(isFullyCompleted ? Icons.star : Icons.star_border, color: isFullyCompleted ? Colors.amber : Colors.grey),
                                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LogDetailScreen(log: log))),
                                ),
                              );
                            },
                          ),
                ],
              ),
            );
            },
          ),
        ),
      ],
    );
  }
}