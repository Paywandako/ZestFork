import 'package:flutter/foundation.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';
import 'package:zest/app/data/db.dart';
import 'package:zest/app/controller/todo_controller.dart';
import 'package:zest/app/utils/show_dialog.dart';
import 'package:zest/app/ui/widgets/button.dart';
import 'package:zest/app/ui/widgets/text_form.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zest/main.dart';

class TodosAction extends StatefulWidget {
  const TodosAction({
    super.key,
    required this.text,
    required this.edit,
    required this.category,
    this.task,
    this.todo,
  });
  final String text;
  final Tasks? task;
  final Todos? todo;
  final bool edit;
  final bool category;

  @override
  State<TodosAction> createState() => _TodosActionState();
}

class _TodosActionState extends State<TodosAction> {
  final formKey = GlobalKey<FormState>();
  final todoController = Get.put(TodoController());
  Tasks? selectedTask;
  List<Tasks>? task;
  final FocusNode categoryFocusNode = FocusNode();
  final FocusNode titleFocusNode = FocusNode();
  TextEditingController textTodoConroller = TextEditingController();
  TextEditingController titleTodoEdit = TextEditingController();
  TextEditingController descTodoEdit = TextEditingController();
  TextEditingController timeTodoEdit = TextEditingController();
  TextEditingController tagsTodoEdit = TextEditingController();

  bool todoPined = false;
  Priority todoPriority = Priority.none;
  List<String> todoTags = [];
  
  // New fields for recurrence
  bool isRecurring = false;
  RecurrenceType recurrenceType = RecurrenceType.none;
  int recurrenceInterval = 1;
  List<int> recurrenceDaysOfWeek = [];
  int? recurrenceDayOfMonth;
  DateTime? recurrenceEndDate;
  int? recurrenceCount;

  late final _EditingController controller;

  @override
  initState() {
    if (widget.edit) {
      selectedTask = widget.todo!.task.value;
      textTodoConroller.text = widget.todo!.task.value!.title;
      titleTodoEdit = TextEditingController(text: widget.todo!.name);
      descTodoEdit = TextEditingController(text: widget.todo!.description);
      timeTodoEdit = TextEditingController(
        text:
            widget.todo!.todoCompletedTime != null
                ? timeformat == '12'
                    ? DateFormat.yMMMEd(
                      locale.languageCode,
                    ).add_jm().format(widget.todo!.todoCompletedTime!)
                    : DateFormat.yMMMEd(
                      locale.languageCode,
                    ).add_Hm().format(widget.todo!.todoCompletedTime!)
                : '',
      );
      todoPined = widget.todo!.fix;
      todoPriority = widget.todo!.priority;
      todoTags = widget.todo!.tags;
      
      // Initialize recurrence fields if editing
      isRecurring = widget.todo!.isRecurring;
      recurrenceType = widget.todo!.recurrenceType;
      recurrenceInterval = widget.todo!.recurrenceInterval;
      recurrenceDaysOfWeek = widget.todo!.recurrenceDaysOfWeek ?? [];
      recurrenceDayOfMonth = widget.todo!.recurrenceDayOfMonth;
      recurrenceEndDate = widget.todo!.recurrenceEndDate;
      recurrenceCount = widget.todo!.recurrenceCount;
    }
    controller = _EditingController(
      titleTodoEdit.text,
      descTodoEdit.text,
      timeTodoEdit.text,
      todoPined,
      selectedTask,
      todoPriority,
      todoTags,
    );
    super.initState();
  }

  Future<void> onPopInvokedWithResult(bool didPop, dynamic result) async {
    if (didPop) {
      return;
    } else if (!controller.canCompose.value) {
      Get.back();
      return;
    }

    final shouldPop = await showAdaptiveDialogTextIsNotEmpty(
      context: context,
      onPressed: () {
        titleTodoEdit.clear();
        descTodoEdit.clear();
        timeTodoEdit.clear();
        textTodoConroller.clear();
        tagsTodoEdit.clear();
        Get.back(result: true);
      },
    );

    if (shouldPop == true && mounted) {
      Get.back();
    }
  }

  void onPressed() {
    if (formKey.currentState!.validate()) {
      textTrim(titleTodoEdit);
      textTrim(descTodoEdit);
      
      if (isRecurring) {
        // Handle recurring todo creation/update
        widget.edit
            ? todoController.updateRecurringTodo(
                widget.todo!,
                selectedTask!,
                titleTodoEdit.text,
                descTodoEdit.text,
                timeTodoEdit.text,
                todoPined,
                todoPriority,
                todoTags,
                isRecurring,
                recurrenceType,
                recurrenceInterval,
                recurrenceDaysOfWeek.isNotEmpty ? recurrenceDaysOfWeek : null,
                recurrenceDayOfMonth,
                recurrenceEndDate,
                recurrenceCount,
              )
            : widget.category
            ? todoController.addRecurringTodo(
                selectedTask!,
                titleTodoEdit.text,
                descTodoEdit.text,
                timeTodoEdit.text,
                todoPined,
                todoPriority,
                todoTags,
                recurrenceType,
                recurrenceInterval,
                recurrenceDaysOfWeek.isNotEmpty ? recurrenceDaysOfWeek : null,
                recurrenceDayOfMonth,
                recurrenceEndDate,
                recurrenceCount,
              )
            : todoController.addRecurringTodo(
                widget.task!,
                titleTodoEdit.text,
                descTodoEdit.text,
                timeTodoEdit.text,
                todoPined,
                todoPriority,
                todoTags,
                recurrenceType,
                recurrenceInterval,
                recurrenceDaysOfWeek.isNotEmpty ? recurrenceDaysOfWeek : null,
                recurrenceDayOfMonth,
                recurrenceEndDate,
                recurrenceCount,
              );
      } else {
        // Handle regular todo creation/update
        widget.edit
            ? todoController.updateTodo(
                widget.todo!,
                selectedTask!,
                titleTodoEdit.text,
                descTodoEdit.text,
                timeTodoEdit.text,
                todoPined,
                todoPriority,
                todoTags,
              )
            : widget.category
            ? todoController.addTodo(
                selectedTask!,
                titleTodoEdit.text,
                descTodoEdit.text,
                timeTodoEdit.text,
                todoPined,
                todoPriority,
                todoTags,
              )
            : todoController.addTodo(
                widget.task!,
                titleTodoEdit.text,
                descTodoEdit.text,
                timeTodoEdit.text,
                todoPined,
                todoPriority,
                todoTags,
              );
      }
      
      textTodoConroller.clear();
      titleTodoEdit.clear();
      descTodoEdit.clear();
      timeTodoEdit.clear();
      tagsTodoEdit.clear();
      Get.back();
    }
  }

  @override
  void dispose() {
    textTodoConroller.dispose();
    titleTodoEdit.dispose();
    descTodoEdit.dispose();
    timeTodoEdit.dispose();
    tagsTodoEdit.dispose();
    controller.dispose();
    super.dispose();
  }

  Future<List<Tasks>> getTaskAll(String pattern) async {
    List<Tasks> getTask;
    getTask = isar.tasks.filter().archiveEqualTo(false).findAllSync();
    return getTask.where((element) {
      final title = element.title.toLowerCase();
      final query = pattern.toLowerCase();
      return title.contains(query);
    }).toList();
  }

  textTrim(value) {
    value.text = value.text.trim();
    while (value.text.contains('  ')) {
      value.text = value.text.replaceAll('  ', ' ');
    }
  }

  Widget _buildChips() {
    List<Widget> chips = [];

    for (int i = 0; i < todoTags.length; i++) {
      Padding actionChip = Padding(
        padding: const EdgeInsets.only(right: 5),
        child: InputChip(
          elevation: 4,
          label: Text(todoTags[i]),
          deleteIcon: const Icon(IconsaxPlusLinear.close_square, size: 15),
          onDeleted: () {
            setState(() {
              todoTags = List<String>.from(todoTags)..removeAt(i);
              controller.tags.value = todoTags;
            });
          },
        ),
      );

      chips.add(actionChip);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(children: chips),
    );
  }
  
  // Build the recurrence options UI
  Widget _buildRecurrenceOptions() {
    if (!isRecurring) return const SizedBox.shrink();
    
    // Recurrence type dropdown
    final recurrenceTypeDropdown = DropdownButtonFormField<RecurrenceType>(
      elevation: 4,
      decoration: InputDecoration(
        labelText: 'Recurrence Type',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      ),
      value: recurrenceType,
      items: RecurrenceType.values.map((type) {
        return DropdownMenuItem<RecurrenceType>(
          value: type,
          child: Text(type.name),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          recurrenceType = value!;
          // Reset specific fields when type changes
          if (recurrenceType == RecurrenceType.none) {
            isRecurring = false;
          } else if (recurrenceType != RecurrenceType.weekly) {
            recurrenceDaysOfWeek = [];
          }
        });
      },
    );
    
    // Interval input
    final intervalInput = TextFormField(
      decoration: InputDecoration(
        labelText: 'Every',
        hintText: 'Interval',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        suffixText: _getIntervalSuffix(),
      ),
      keyboardType: TextInputType.number,
      initialValue: recurrenceInterval.toString(),
      onChanged: (value) {
        setState(() {
          recurrenceInterval = int.tryParse(value) ?? 1;
          if (recurrenceInterval < 1) recurrenceInterval = 1;
        });
      },
    );
    
    // Days of week selection (for weekly recurrence)
    Widget daysOfWeekSelection = const SizedBox.shrink();
    if (recurrenceType == RecurrenceType.weekly) {
      final daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final dayChips = List<Widget>.generate(7, (index) {
        final dayIndex = index + 1; // 1-7 for Monday-Sunday
        final isSelected = recurrenceDaysOfWeek.contains(dayIndex);
        
        return Padding(
          padding: const EdgeInsets.only(right: 5),
          child: FilterChip(
            elevation: 4,
            label: Text(daysOfWeek[index]),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  recurrenceDaysOfWeek.add(dayIndex);
                } else {
                  recurrenceDaysOfWeek.remove(dayIndex);
                }
              });
            },
          ),
        );
      });
      
      daysOfWeekSelection = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 10, top: 10, bottom: 5),
            child: Text('Repeat on:'),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(children: dayChips),
          ),
        ],
      );
    }
    
    // Day of month selection (for monthly recurrence)
    Widget dayOfMonthSelection = const SizedBox.shrink();
    if (recurrenceType == RecurrenceType.monthly) {
      dayOfMonthSelection = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: TextFormField(
          decoration: InputDecoration(
            labelText: 'Day of month',
            hintText: '1-31',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          ),
          keyboardType: TextInputType.number,
          initialValue: recurrenceDayOfMonth?.toString() ?? '',
          onChanged: (value) {
            setState(() {
              recurrenceDayOfMonth = int.tryParse(value);
              if (recurrenceDayOfMonth != null) {
                if (recurrenceDayOfMonth! < 1) recurrenceDayOfMonth = 1;
                if (recurrenceDayOfMonth! > 31) recurrenceDayOfMonth = 31;
              }
            });
          },
        ),
      );
    }
    
    // End recurrence options
    final endRecurrenceOptions = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 10, top: 10, bottom: 5),
          child: Text('End recurrence:'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('Never'),
                  value: true,
                  groupValue: recurrenceEndDate == null && recurrenceCount == null,
                  onChanged: (value) {
                    setState(() {
                      recurrenceEndDate = null;
                      recurrenceCount = null;
                    });
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('On date'),
                  value: recurrenceEndDate != null,
                  groupValue: recurrenceEndDate != null,
                  onChanged: (value) async {
                    final selectedDate = await showOmniDateTimePicker(
                      context: context,
                      type: OmniDateTimePickerType.date,
                      primaryColor: Theme.of(context).colorScheme.primary,
                      backgroundColor: Theme.of(context).colorScheme.background,
                      calendarTextColor: Theme.of(context).colorScheme.onBackground,
                      tabTextColor: Theme.of(context).colorScheme.onBackground,
                      buttonTextColor: Theme.of(context).colorScheme.onPrimary,
                      timeSpinnerTextStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                      timeSpinnerHighlightedTextStyle: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      is24HourMode: timeformat == '24',
                      isShowSeconds: false,
                      startInitialDate: DateTime.now(),
                      startFirstDate: DateTime.now().subtract(
                        const Duration(days: 365 * 100),
                      ),
                      startLastDate: DateTime.now().add(
                        const Duration(days: 365 * 100),
                      ),
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                    );
                    
                    if (selectedDate != null) {
                      setState(() {
                        recurrenceEndDate = selectedDate;
                        recurrenceCount = null;
                      });
                    }
                  },
                ),
        
(Content truncated due to size limit. Use line ranges to read in chunks)