import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:zest/app/data/db.dart';
import 'package:zest/app/utils/notification.dart';
import 'package:zest/main.dart';

class TodoController extends GetxController {
  final tasks = <Tasks>[].obs;
  final todos = <Todos>[].obs;

  final selectedTask = <Tasks>[].obs;
  final isMultiSelectionTask = false.obs;

  final selectedTodo = <Todos>[].obs;
  final isMultiSelectionTodo = false.obs;

  RxBool isPop = true.obs;

  final duration = const Duration(milliseconds: 500);
  var now = DateTime.now();

  @override
  void onInit() {
    super.onInit();
    tasks.assignAll(isar.tasks.where().findAllSync());
    todos.assignAll(isar.todos.where().findAllSync());
    
    // Check for recurring tasks that need to be rescheduled
    _checkRecurringTasks();
  }
  
  // Check for recurring tasks that need to be rescheduled
  void _checkRecurringTasks() {
    // Find completed recurring tasks that need to be rescheduled
    final recurringTodos = todos.where((todo) => 
      todo.isRecurring && 
      todo.done && 
      todo.todoCompletionTime != null &&
      _shouldCreateNextOccurrence(todo)
    ).toList();
    
    for (var todo in recurringTodos) {
      _createNextOccurrence(todo);
    }
  }

  // Tasks
  Future<void> addTask(String title, String desc, Color myColor) async {
    List<Tasks> searchTask;
    searchTask = isar.tasks.filter().titleEqualTo(title).findAllSync();

    final taskCreate = Tasks(
      title: title,
      description: desc,
      taskColor: myColor.value,
    );

    if (searchTask.isEmpty) {
      tasks.add(taskCreate);
      isar.writeTxnSync(() => isar.tasks.putSync(taskCreate));
      EasyLoading.showSuccess('createCategory'.tr, duration: duration);
    } else {
      EasyLoading.showError('duplicateCategory'.tr, duration: duration);
    }
  }

  Future<void> updateTask(
    Tasks task,
    String title,
    String desc,
    Color myColor,
  ) async {
    isar.writeTxnSync(() {
      task.title = title;
      task.description = desc;
      task.taskColor = myColor.value;
      isar.tasks.putSync(task);
    });

    var newTask = task;
    int oldIdx = tasks.indexOf(task);
    tasks[oldIdx] = newTask;
    tasks.refresh();
    todos.refresh();

    EasyLoading.showSuccess('editCategory'.tr, duration: duration);
  }

  Future<void> deleteTask(List<Tasks> taskList) async {
    List<Tasks> taskListCopy = List.from(taskList);

    for (var task in taskListCopy) {
      // Delete Notification
      List<Todos> getTodo;
      getTodo =
          isar.todos.filter().task((q) => q.idEqualTo(task.id)).findAllSync();

      for (var todo in getTodo) {
        if (todo.todoCompletedTime != null) {
          if (todo.todoCompletedTime!.isAfter(now)) {
            await flutterLocalNotificationsPlugin.cancel(todo.id);
          }
        }
      }
      // Delete Todos
      todos.removeWhere((todo) => todo.task.value?.id == task.id);
      isar.writeTxnSync(
        () =>
            isar.todos
                .filter()
                .task((q) => q.idEqualTo(task.id))
                .deleteAllSync(),
      );

      // Delete Task
      tasks.remove(task);
      isar.writeTxnSync(() => isar.tasks.deleteSync(task.id));
      EasyLoading.showSuccess('categoryDelete'.tr, duration: duration);
    }
  }

  Future<void> archiveTask(List<Tasks> taskList) async {
    List<Tasks> taskListCopy = List.from(taskList);

    for (var task in taskListCopy) {
      // Delete Notification
      List<Todos> getTodo;
      getTodo =
          isar.todos.filter().task((q) => q.idEqualTo(task.id)).findAllSync();

      for (var todo in getTodo) {
        if (todo.todoCompletedTime != null) {
          if (todo.todoCompletedTime!.isAfter(now)) {
            await flutterLocalNotificationsPlugin.cancel(todo.id);
          }
        }
      }
      // Archive Task
      isar.writeTxnSync(() {
        task.archive = true;
        isar.tasks.putSync(task);
      });
      tasks.refresh();
      todos.refresh();
      EasyLoading.showSuccess('categoryArchive'.tr, duration: duration);
    }
  }

  Future<void> noArchiveTask(List<Tasks> taskList) async {
    List<Tasks> taskListCopy = List.from(taskList);

    for (var task in taskListCopy) {
      // Create Notification
      List<Todos> getTodo;
      getTodo =
          isar.todos.filter().task((q) => q.idEqualTo(task.id)).findAllSync();

      for (var todo in getTodo) {
        if (todo.todoCompletedTime != null) {
          if (todo.todoCompletedTime!.isAfter(now)) {
            NotificationShow().showNotification(
              todo.id,
              todo.name,
              todo.description,
              todo.todoCompletedTime,
            );
          }
        }
      }
      // No archive Task
      isar.writeTxnSync(() {
        task.archive = false;
        isar.tasks.putSync(task);
      });
      tasks.refresh();
      todos.refresh();
      EasyLoading.showSuccess('noCategoryArchive'.tr, duration: duration);
    }
  }

  // Todos
  Future<void> addTodo(
    Tasks task,
    String title,
    String desc,
    String time,
    bool pined,
    Priority priority,
    List<String> tags,
  ) async {
    DateTime? date;
    if (time.isNotEmpty) {
      date =
          timeformat == '12'
              ? DateFormat.yMMMEd(locale.languageCode).add_jm().parse(time)
              : DateFormat.yMMMEd(locale.languageCode).add_Hm().parse(time);
    }
    List<Todos> getTodos;
    getTodos =
        isar.todos
            .filter()
            .nameEqualTo(title)
            .task((q) => q.idEqualTo(task.id))
            .todoCompletedTimeEqualTo(date)
            .findAllSync();

    final todosCreate = Todos(
      name: title,
      description: desc,
      todoCompletedTime: date,
      fix: pined,
      createdTime: DateTime.now(),
      priority: priority,
      tags: tags,
    )..task.value = task;

    if (getTodos.isEmpty) {
      todos.add(todosCreate);
      isar.writeTxnSync(() {
        isar.todos.putSync(todosCreate);
        todosCreate.task.saveSync();
      });
      if (date != null && now.isBefore(date)) {
        NotificationShow().showNotification(
          todosCreate.id,
          todosCreate.name,
          todosCreate.description,
          date,
        );
      }
      EasyLoading.showSuccess('todoCreate'.tr, duration: duration);
    } else {
      EasyLoading.showError('duplicateTodo'.tr, duration: duration);
    }
  }
  
  // New method for adding recurring todos
  Future<void> addRecurringTodo(
    Tasks task,
    String title,
    String desc,
    String time,
    bool pined,
    Priority priority,
    List<String> tags,
    RecurrenceType recurrenceType,
    int recurrenceInterval,
    List<int>? recurrenceDaysOfWeek,
    int? recurrenceDayOfMonth,
    DateTime? recurrenceEndDate,
    int? recurrenceCount,
  ) async {
    DateTime? date;
    if (time.isNotEmpty) {
      date =
          timeformat == '12'
              ? DateFormat.yMMMEd(locale.languageCode).add_jm().parse(time)
              : DateFormat.yMMMEd(locale.languageCode).add_Hm().parse(time);
    }
    
    List<Todos> getTodos;
    getTodos =
        isar.todos
            .filter()
            .nameEqualTo(title)
            .task((q) => q.idEqualTo(task.id))
            .todoCompletedTimeEqualTo(date)
            .findAllSync();

    final todosCreate = Todos(
      name: title,
      description: desc,
      todoCompletedTime: date,
      fix: pined,
      createdTime: DateTime.now(),
      priority: priority,
      tags: tags,
      isRecurring: true,
      recurrenceType: recurrenceType,
      recurrenceInterval: recurrenceInterval,
      recurrenceDaysOfWeek: recurrenceDaysOfWeek,
      recurrenceDayOfMonth: recurrenceDayOfMonth,
      recurrenceEndDate: recurrenceEndDate,
      recurrenceCount: recurrenceCount,
      originalDueDate: date,
    )..task.value = task;

    if (getTodos.isEmpty) {
      todos.add(todosCreate);
      isar.writeTxnSync(() {
        isar.todos.putSync(todosCreate);
        todosCreate.task.saveSync();
      });
      if (date != null && now.isBefore(date)) {
        NotificationShow().showNotification(
          todosCreate.id,
          todosCreate.name,
          todosCreate.description,
          date,
        );
      }
      EasyLoading.showSuccess('todoCreate'.tr, duration: duration);
    } else {
      EasyLoading.showError('duplicateTodo'.tr, duration: duration);
    }
  }

  Future<void> updateTodoCheck(Todos todo) async {
    // If this is a recurring todo and it's being marked as done
    if (todo.isRecurring && !todo.done) {
      todo.done = true;
      todo.todoCompletionTime = DateTime.now();
      
      // Update the current todo
      isar.writeTxnSync(() => isar.todos.putSync(todo));
      todos.refresh();
      
      // Create the next occurrence if needed
      if (_shouldCreateNextOccurrence(todo)) {
        _createNextOccurrence(todo);
      }
    } else {
      // Regular non-recurring todo or recurring todo being unchecked
      isar.writeTxnSync(() => isar.todos.putSync(todo));
      todos.refresh();
    }
  }
  
  // Helper method to determine if we should create a next occurrence
  bool _shouldCreateNextOccurrence(Todos todo) {
    if (!todo.isRecurring) return false;
    
    // If there's a recurrence count and it's been reached, don't create next occurrence
    if (todo.recurrenceCount != null) {
      // Count existing occurrences with the same name and task
      int occurrences = todos.where((t) => 
        t.name == todo.name && 
        t.task.value?.id == todo.task.value?.id
      ).length;
      
      if (occurrences >= todo.recurrenceCount!) return false;
    }
    
    // If there's an end date and it's been reached, don't create next occurrence
    if (todo.recurrenceEndDate != null) {
      DateTime? nextDate = _calculateNextOccurrence(todo);
      if (nextDate != null && nextDate.isAfter(todo.recurrenceEndDate!)) {
        return false;
      }
    }
    
    return true;
  }
  
  // Helper method to calculate the next occurrence date
  DateTime? _calculateNextOccurrence(Todos todo) {
    if (todo.todoCompletedTime == null) return null;
    
    DateTime baseDate = todo.todoCompletedTime!;
    
    switch (todo.recurrenceType) {
      case RecurrenceType.daily:
        return baseDate.add(Duration(days: todo.recurrenceInterval));
        
      case RecurrenceType.weekly:
        // For weekly recurrence, we need to handle days of week
        if (todo.recurrenceDaysOfWeek != null && todo.recurrenceDaysOfWeek!.isNotEmpty) {
          // Get the current day of week (1-7, where 1 is Monday)
          int currentDayOfWeek = baseDate.weekday;
          
          // Find the next day of week in the recurrence pattern
          List<int> sortedDays = List.from(todo.recurrenceDaysOfWeek!)..sort();
          
          // Find the next day in the current week
          int? nextDay = sortedDays.firstWhere(
            (day) => day > currentDayOfWeek, 
            orElse: () => -1
          );
          
          if (nextDay != -1) {
            // There's a day later this week
            int daysToAdd = nextDay - currentDayOfWeek;
            return baseDate.add(Duration(days: daysToAdd));
          } else {
            // Move to the first day in the next week
            int daysToAdd = 7 - currentDayOfWeek + sortedDays.first;
            return baseDate.add(Duration(days: daysToAdd + (todo.recurrenceInterval - 1) * 7));
          }
        } else {
          // Simple weekly recurrence
          return baseDate.add(Duration(days: 7 * todo.recurrenceInterval));
        }
        
      case RecurrenceType.monthly:
        // For monthly recurrence, we need to handle day of month
        if (todo.recurrenceDayOfMonth != null) {
          // Use the specified day of month
          int year = baseDate.year;
          int month = baseDate.month + todo.recurrenceInterval;
          
          // Adjust year if needed
          while (month > 12) {
            month -= 12;
            year++;
          }
          
          // Create a date with the target day
          int day = todo.recurrenceDayOfMonth!;
          
          // Ensure the day is valid for the month
          int daysInMonth = DateTime(year, month + 1, 0).day;
          day = day > daysInMonth ? daysInMonth : day;
          
          return DateTime(year, month, day, 
            baseDate.hour, baseDate.minute, baseDate.second);
        } else {
          // Use the same day of month
          int year = baseDate.year;
          int month = baseDate.month + todo.recurrenceInterval;
          
          // Adjust year if needed
          while (month > 12) {
            month -= 12;
            year++;
          }
          
          // Create a date with the same day
          int day = baseDate.day;
          
          // Ensure the day is valid for the month
          int daysInMonth = DateTime(year, month + 1, 0).day;
          day = day > daysInMonth ? daysInMonth : day;
          
          return DateTime(year, month, day, 
            baseDate.hour, baseDate.minute, baseDate.second);
        }
        
      case RecurrenceType.yearly:
        return DateTime(
          baseDate.year + todo.recurrenceInterval,
          baseDate.month,
          baseDate.day,
          baseDate.hour,
          baseDate.minute,
          baseDate.second
        );
        
      default:
        return null;
    }
  }
  
  // Helper method to create the next occurrence of a recurring todo
  void _createNextOccurrence(Todos todo) {
    DateTime? nextDate = _calculateNextOccurrence(todo);
    if (nextDate == null) return;
    
    // Create a new todo for the next occurrence
    final nextTodo = Todos(
      name: todo.name,
      description: todo.description,
      todoCompletedTime: nextDate,
      fix: todo.fix,
      createdTime: DateTime.now(),
      priority: todo.priority,
      tags: todo.tags,
      isRecurring: true,
      recurrenceType: todo.recurrenceType,
      recurrenceInterval: todo.recurrenceInterval,
      recurrenceDaysOfWeek: todo.recurrenceDaysOfWeek,
      recurrenceDayOfMonth: todo.recurrenceDayOfMonth,
      recurrenceEndDate: todo.recurrenceEndDate,
      recurrenceCount: todo.recurrenceCount,
      originalDueDate: todo.originalDueDate,
    )..task.value = todo.task.value;
    
    // Add to database and list
    todos.add(nextTodo);
    isar.writeTxnSync(() {
      isar.todos.putSync(nextTodo);
      nextTodo.task.saveSync();
    });
    
    // Schedule notification for the next occurrence
    if (nextDate.isAfter(now)) {
      NotificationShow().showNotification(
        nextTodo.id,
        nextTodo.name,
        nextTodo.description,
        nextDate,
      );
    }
  }

  Future<void> updateTodo(
    Todos todo,
    Tasks task,
    String title,
    String desc,
    String time,
    bool pined,
    Priority priority,
    List<String> tags,
  ) async {
    DateTime? date;
    if (time.isNotEmpty) {
      date =
          timeformat == '12'
              ? DateFormat.yMMMEd(locale.languageCode).add_jm().parse(time)
              : DateFormat.yMMMEd(locale.languageCode).add_Hm().parse(time);
    }
    isar.writeTxnSync(() {
      todo.name = title;
      todo.description = desc;
      todo.todoCompletedTime = date;
      todo.fix = pined;
      todo.priority = priority;
      todo.tags = tags;
      todo.task.value = task;
      isar.todos.putSync(todo);
      todo.task.saveSync();
    });

    var newTodo = todo;
    int oldIdx = todos.indexOf(todo);
    todos[oldIdx] = newTodo;
    todos.refresh();

    if (date != null && now.isBefore(date)) {
      await flutterLocalNotificationsPlugin.cancel(todo.id);
      NotificationShow().showNotification(
        todo.id,
        todo.name,
        todo.descri
(Content truncated due to size limit. Use line ranges to read in chunks)