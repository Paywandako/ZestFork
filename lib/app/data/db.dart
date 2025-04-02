import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
part 'db.g.dart';

@collection
class Settings {
  Id id = Isar.autoIncrement;
  bool onboard = false;
  String? theme = 'system';
  String timeformat = '24';
  bool materialColor = true;
  bool amoledTheme = false;
  bool? isImage = true;
  String? language;
  String firstDay = 'monday';
  String calendarFormat = 'week';
}

@collection
class Tasks {
  Id id;
  String title;
  String description;
  int taskColor;
  bool archive;
  int? index;

  @Backlink(to: 'task')
  final todos = IsarLinks<Todos>();

  Tasks({
    this.id = Isar.autoIncrement,
    required this.title,
    this.description = '',
    this.archive = false,
    required this.taskColor,
    this.index,
  });
}

// New enum for recurrence types
enum RecurrenceType {
  none(name: 'None'),
  daily(name: 'Daily'),
  weekly(name: 'Weekly'),
  monthly(name: 'Monthly'),
  yearly(name: 'Yearly');
  
  const RecurrenceType({required this.name});
  final String name;
}

@collection
class Todos {
  Id id;
  String name;
  String description;
  DateTime? todoCompletedTime;
  DateTime createdTime;
  DateTime? todoCompletionTime;
  bool done;
  bool fix;
  @enumerated
  Priority priority;
  List<String> tags = [];
  int? index;
  
  // New fields for recurrence
  bool isRecurring = false;
  @enumerated
  RecurrenceType recurrenceType = RecurrenceType.none;
  int recurrenceInterval = 1; // e.g., every 1 day, every 2 weeks
  List<int>? recurrenceDaysOfWeek; // For weekly recurrence (1-7 for Monday-Sunday)
  int? recurrenceDayOfMonth; // For monthly recurrence
  DateTime? recurrenceEndDate; // Optional end date for recurrence
  int? recurrenceCount; // Optional number of occurrences
  DateTime? originalDueDate; // To keep track of the original pattern

  final task = IsarLink<Tasks>();

  Todos({
    this.id = Isar.autoIncrement,
    required this.name,
    this.description = '',
    this.todoCompletedTime,
    this.todoCompletionTime,
    required this.createdTime,
    this.done = false,
    this.fix = false,
    this.priority = Priority.none,
    this.tags = const [],
    this.index,
    this.isRecurring = false,
    this.recurrenceType = RecurrenceType.none,
    this.recurrenceInterval = 1,
    this.recurrenceDaysOfWeek,
    this.recurrenceDayOfMonth,
    this.recurrenceEndDate,
    this.recurrenceCount,
    this.originalDueDate,
  });
}

enum Priority {
  high(name: 'highPriority', color: Colors.red),
  medium(name: 'mediumPriority', color: Colors.orange),
  low(name: 'lowPriority', color: Colors.green),
  none(name: 'noPriority');

  const Priority({required this.name, this.color});
  final String name;
  final Color? color;
}
