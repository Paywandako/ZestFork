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
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('After'),
                  value: recurrenceCount != null,
                  groupValue: recurrenceCount != null,
                  onChanged: (value) {
                    setState(() {
                      recurrenceCount = 5; // Default value
                      recurrenceEndDate = null;
                    });
                  },
                ),
              ),
              if (recurrenceCount != null)
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Occurrences',
                      hintText: 'Count',
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: recurrenceCount.toString(),
                    onChanged: (value) {
                      setState(() {
                        recurrenceCount = int.tryParse(value) ?? 5;
                        if (recurrenceCount! < 1) recurrenceCount = 1;
                      });
                    },
                  ),
                ),
              if (recurrenceCount == null)
                const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ],
    );
    
    // Show end date if selected
    Widget endDateDisplay = const SizedBox.shrink();
    if (recurrenceEndDate != null) {
      endDateDisplay = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          'Ends on: ${DateFormat.yMMMd(locale.languageCode).format(recurrenceEndDate!)}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: recurrenceTypeDropdown,
        ),
        if (recurrenceType != RecurrenceType.none)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: intervalInput,
          ),
        if (recurrenceType == RecurrenceType.weekly)
          daysOfWeekSelection,
        if (recurrenceType == RecurrenceType.monthly)
          dayOfMonthSelection,
        if (recurrenceType != RecurrenceType.none)
          endRecurrenceOptions,
        if (recurrenceEndDate != null)
          endDateDisplay,
      ],
    );
  }
  
  // Helper method to get the suffix text for interval input
  String _getIntervalSuffix() {
    switch (recurrenceType) {
      case RecurrenceType.daily:
        return recurrenceInterval == 1 ? 'day' : 'days';
      case RecurrenceType.weekly:
        return recurrenceInterval == 1 ? 'week' : 'weeks';
      case RecurrenceType.monthly:
        return recurrenceInterval == 1 ? 'month' : 'months';
      case RecurrenceType.yearly:
        return recurrenceInterval == 1 ? 'year' : 'years';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final todoCategory =
        widget.category
            ? RawAutocomplete<Tasks>(
              focusNode: categoryFocusNode,
              textEditingController: textTodoConroller,
              fieldViewBuilder: (
                BuildContext context,
                TextEditingController fieldTextEditingController,
                FocusNode fieldFocusNode,
                VoidCallback onFieldSubmitted,
              ) {
                return MyTextForm(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  controller: textTodoConroller,
                  focusNode: categoryFocusNode,
                  labelText: 'selectCategory'.tr,
                  type: TextInputType.text,
                  icon: const Icon(IconsaxPlusLinear.folder_2),
                  iconButton:
                      textTodoConroller.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(
                              IconsaxPlusLinear.close_square,
                              size: 18,
                            ),
                            onPressed: () {
                              textTodoConroller.clear();
                              setState(() {});
                            },
                          )
                          : null,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'selectCategory'.tr;
                    }
                    return null;
                  },
                );
              },
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<Tasks>.empty();
                }
                return getTaskAll(textEditingValue.text);
              },
              onSelected: (Tasks selection) async {
                textTodoConroller.text = selection.title;
                selectedTask = selection;
                setState(() {
                  if (widget.edit) controller.task.value = selectedTask;
                });

                Future.microtask(() {
                  if (context.mounted) {
                    FocusScope.of(context).requestFocus(titleFocusNode);
                  }
                });

                categoryFocusNode.unfocus();
              },
              displayStringForOption: (Tasks option) => option.title,
              optionsViewBuilder: (
                BuildContext context,
                AutocompleteOnSelected<Tasks> onSelected,
                Iterable<Tasks> options,
              ) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 200,
                        maxWidth: 300,
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final Tasks option = options.elementAt(index);
                          return InkWell(
                            onTap: () => onSelected(option),
                            child: Builder(
                              builder: (BuildContext context) {
                                final bool highlight =
                                    AutocompleteHighlightedOption.of(context) ==
                                        index;
                                if (highlight) {
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((Duration timeStamp) {
                                    Scrollable.ensureVisible(context,
                                        alignment: 0.5);
                                  });
                                }
                                return Container(
                                  color: highlight
                                      ? Theme.of(context).focusColor
                                      : null,
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        height: 15,
                                        width: 15,
                                        decoration: BoxDecoration(
                                          color: Color(option.taskColor),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(option.title),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            )
            : const SizedBox.shrink();

    final titleInput = MyTextForm(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      controller: titleTodoEdit,
      focusNode: titleFocusNode,
      labelText: 'todoTitle'.tr,
      type: TextInputType.text,
      icon: const Icon(IconsaxPlusLinear.text),
      iconButton:
          titleTodoEdit.text.isNotEmpty
              ? IconButton(
                icon: const Icon(IconsaxPlusLinear.close_square, size: 18),
                onPressed: () {
                  titleTodoEdit.clear();
                  setState(() {});
                },
              )
              : null,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'todoTitle'.tr;
        }
        return null;
      },
    );

    final descriptionInput = MyTextForm(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      controller: descTodoEdit,
      labelText: 'todoDescription'.tr,
      type: TextInputType.text,
      icon: const Icon(IconsaxPlusLinear.document_text),
      iconButton:
          descTodoEdit.text.isNotEmpty
              ? IconButton(
                icon: const Icon(IconsaxPlusLinear.close_square, size: 18),
                onPressed: () {
                  descTodoEdit.clear();
                  setState(() {});
                },
              )
              : null,
    );

    final tagsInput = MyTextForm(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      controller: tagsTodoEdit,
      labelText: 'todoTags'.tr,
      type: TextInputType.text,
      icon: const Icon(IconsaxPlusLinear.tag),
      iconButton:
          tagsTodoEdit.text.isNotEmpty
              ? IconButton(
                icon: const Icon(IconsaxPlusLinear.close_square, size: 18),
                onPressed: () {
                  tagsTodoEdit.clear();
                  setState(() {});
                },
              )
              : null,
      onSubmitted: (value) {
        if (value.isNotEmpty) {
          setState(() {
            todoTags.add(value);
            controller.tags.value = todoTags;
            tagsTodoEdit.clear();
          });
        }
      },
    );

    final submitButton = MyButton(
      elevation: 4,
      onPressed: onPressed,
      text: widget.edit ? 'edit'.tr : 'create'.tr,
    );

    final todoDateWidget = ChoiceChip(
      elevation: 4,
      avatar: const Icon(IconsaxPlusLinear.calendar),
      label: Text(
        timeTodoEdit.text.isEmpty ? 'todoDate'.tr : timeTodoEdit.text,
      ),
      selected: timeTodoEdit.text.isNotEmpty,
      onSelected: (value) async {
        if (value) {
          final selectedDateTime = await showOmniDateTimePicker(
            context: context,
            type: OmniDateTimePickerType.dateAndTime,
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

          if (selectedDateTime != null) {
            setState(() {
              timeTodoEdit.text =
                  timeformat == '12'
                      ? DateFormat.yMMMEd(
                        locale.languageCode,
                      ).add_jm().format(selectedDateTime)
                      : DateFormat.yMMMEd(
                        locale.languageCode,
                      ).add_Hm().format(selectedDateTime);
              if (widget.edit) controller.time.value = timeTodoEdit.text;
            });
          }
        } else {
          setState(() {
            timeTodoEdit.clear();
            if (widget.edit) controller.time.value = '';
          });
        }
      },
    );

    final todoPriorityWidget = PopupMenuButton<Priority>(
      elevation: 4,
      position: PopupMenuPosition.under,
      initialValue: todoPriority,
      child: ChoiceChip(
        elevation: 4,
        avatar: Icon(IconsaxPlusLinear.flag, color: todoPriority.color),
        label: Text(todoPriority.name.tr),
        selected: todoPriority != Priority.none,
        onSelected: (value) {},
      ),
      itemBuilder: (context) {
        final menuController = PopupMenuController();
        return Priority.values.map(
          (priority) {
            return PopupMenuItem<Priority>(
              value: priority,
              onTap: () {
                setState(() {
                  todoPriority = priority;
                  if (widget.edit) controller.priority.value = priority;
                });
              },
              child: PopupMenuItemButton(
                controller: menuController,
                avatar: Icon(IconsaxPlusLinear.flag, color: priority.color),
                label: Text(priority.name.tr),
                onPressed: () {
                  if (menuController.isOpen) {
                    menuController.close();
                  } else {
                    menuController.open();
                  }
                },
              ),
            );
          },
        ).toList();
      },
    );

    final todoFixWidget = ChoiceChip(
      elevation: 4,
      avatar: const Icon(IconsaxPlusLinear.attach_square),
      label: Text('todoPined'.tr),
      selected: todoPined,
      onSelected: (value) {
        setState(() {
          todoPined = value;
          if (widget.edit) controller.pined.value = value;
        });
      },
    );
    
    // New recurring widget
    final todoRecurringWidget = ChoiceChip(
      elevation: 4,
      avatar: const Icon(IconsaxPlusLinear.repeat),
      label: Text('Recurring'),
      selected: isRecurring,
      onSelected: (value) {
        setState(() {
          isRecurring = value;
          if (!isRecurring) {
            recurrenceType = RecurrenceType.none;
          } else {
            recurrenceType = RecurrenceType.daily;
          }
        });
      },
    );

    final attributes = Row(
      children: [
        todoDateWidget,
        const Gap(10),
        todoPriorityWidget,
        const Gap(10),
        todoFixWidget,
        const Gap(10),
        todoRecurringWidget,
      ],
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: onPopInvokedWithResult,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 7),
                    child: Text(
                      widget.text,
                      style: context.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  todoCategory,
                  titleInput,
                  descriptionInput,
                  tagsInput,
                  _buildChips(),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    child: attributes,
                  ),
                  _buildRecurrenceOptions(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: submitButton,
                  ),
                  const Gap(10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditingController extends ChangeNotifier {
  _EditingController(
    this.initialTitle,
    this.initialDescription,
    this.initialTime,
    this.initialPined,
    this.initialTask,
    this.initialPriority,
    this.initialTags,
  ) {
    title.value = initialTitle;
    description.value = initialDescription;
    time.value = initialTime;
    pined.value = initialPined;
    task.value = initialTask;
    priority.value = initialPriority;
    tags.value = initialTags;
    title.addListener(_updateCanCompose);
    description.addListener(_updateCanCompose);
    time.addListener(_updateCanCompose);
    pined.addListener(_updateCanCompose);
    task.addListener(_updateCanCompose);
    priority.addListener(_updateCanCompose);
    tags.addListener(_updateCanCompose);
  }
  final String? initialTitle;
  final String? initialDescription;
  final String? initialTime;
  final bool? initialPined;
  final Tasks? initialTask;
  final Priority initialPriority;
  final List<String>? initialTags;
  final title = ValueNotifier<String?>(null);
  final description = ValueNotifier<String?>(null);
  final time = ValueNotifier<String?>(null);
  final pined = ValueNotifier<bool?>(null);
  final task = ValueNotifier<Tasks?>(null);
  final priority = ValueNotifier(Priority.none);
  final tags = ValueNotifier<List<String>?>(null);
  final _canCompose = ValueNotifier(false);
  ValueListenable<bool> get canCompose => _canCompose;
  void _updateCanCompose() {
    _canCompose.value =
        (title.value != initialTitle) ||
        (description.value != initialDescription) ||
        (time.value != initialTime) ||
        (pined.value != initialPined) ||
        (task.value != initialTask) ||
        (priority.value != initialPriority) ||
        (tags.value != initialTags);
  }
  @override
  void dispose() {
    title.removeListener(_updateCanCompose);
    description.removeListener(_updateCanCompose);
    time.removeListener(_updateCanCompose);
    pined.removeListener(_updateCanCompose);
    task.removeListener(_updateCanCompose);
    priority.removeListener(_updateCanCompose);
    tags.removeListener(_updateCanCompose);
    super.dispose();
  }
}
