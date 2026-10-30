import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:focus_study/models/task.dart';
import 'package:focus_study/services/firestore_service.dart';

class AddTask extends StatefulWidget {
  const AddTask({super.key});

  @override
  State<AddTask> createState() => _AddTaskState();
}

class _AddTaskState extends State<AddTask> {
  // App theme colors
  static const Color _primaryBlue = Color(0xFF5394ED);
  static const Color _lightBlue = Color(0xFFE8F0FD);
  static const Color _background = Color(0xFFF0F3FF);

  final _formKey = GlobalKey<FormState>();

  // controllers
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _dueTimeController = TextEditingController();
  final _durationController = TextEditingController();

  // fields
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSaving = false;

  @override
  void dispose() {
    // Always dispose controllers to avoid memory leaks
    _titleController.dispose();
    _subjectController.dispose();
    _dueDateController.dispose();
    _dueTimeController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  // Wraps date/time pickers so they use the app's blue theme
  // instead of the default Material purple.
  Widget _blueThemed(BuildContext context, Widget? child) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        colorScheme: base.colorScheme.copyWith(
          primary: _primaryBlue,
          onPrimary: Colors.white,
          secondary: _primaryBlue,
          surface: Colors.white,
          onSurface: Colors.black87,
          surfaceTint: Colors.transparent,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: _primaryBlue),
        ),
        timePickerTheme: TimePickerThemeData(
          backgroundColor: Colors.white,
          hourMinuteColor: WidgetStateColor.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? _lightBlue
                : const Color(0xFFF0F3FF),
          ),
          hourMinuteTextColor: WidgetStateColor.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? _primaryBlue
                : Colors.black87,
          ),
          dayPeriodColor: WidgetStateColor.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? _lightBlue
                : Colors.transparent,
          ),
          dayPeriodTextColor: WidgetStateColor.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? _primaryBlue
                : Colors.black54,
          ),
          dialHandColor: _primaryBlue,
          dialBackgroundColor: const Color(0xFFF0F3FF),
          entryModeIconColor: _primaryBlue,
        ),
        datePickerTheme: const DatePickerThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      child: child!,
    );
  }

  // Date picker
  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      builder: _blueThemed,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dueDateController.text = DateFormat('dd MMM yyyy').format(picked);
      });
    }
  }

  // Time picker
  Future<void> _pickTime() async {
    FocusScope.of(context).unfocus();
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: _blueThemed,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _dueTimeController.text = picked.format(context); // e.g. "10:00 PM"
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a due date')));
      return;
    }

    final minutes = int.tryParse(_durationController.text.trim()) ?? 0;

    final newTask = Task(
      id: '',
      title: _titleController.text.trim(),
      subject: _subjectController.text.trim(),
      dueDate: _selectedDate!,
      dueTime: _dueTimeController.text.trim(),
      estimatedMinutes: minutes,
      studiedSeconds: 0,
      isCompleted: false,
      createdAt: DateTime.now(),
    );

    setState(() {
      _isSaving = true;
    });

    try {
      await FirestoreService()
          .addTask(newTask)
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () =>
                throw Exception('Timed out — check your connection'),
          );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Add task failed: $e');

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add task: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          centerTitle: true,
          title: const Text(
            'Create Task',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task title
                _buildFieldLabel('Task Title'),
                const SizedBox(height: 10),
                _buildInputField(
                  controller: _titleController,
                  hintText: 'Enter your task title',
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 18),
                // Subject
                _buildFieldLabel('Subject'),
                const SizedBox(height: 10),
                _buildInputField(
                  controller: _subjectController,
                  hintText: 'e.g. English',
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 18),
                // Due Date
                _buildFieldLabel('Due Date'),
                const SizedBox(height: 10),
                _buildInputField(
                  controller: _dueDateController,
                  hintText: 'Select due date',
                  readOnly: true,
                  onTap: _pickDate,
                  suffixIcon: const Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: _primaryBlue,
                  ),
                ),
                const SizedBox(height: 18),
                // Due time
                _buildFieldLabel('Due Time'),
                const SizedBox(height: 10),
                _buildInputField(
                  controller: _dueTimeController,
                  hintText: 'Select due time',
                  readOnly: true,
                  onTap: _pickTime,
                  suffixIcon: const Icon(
                    Icons.access_time,
                    size: 20,
                    color: _primaryBlue,
                  ),
                ),
                const SizedBox(height: 18),
                // Duration
                _buildFieldLabel('Duration (minutes)'),
                const SizedBox(height: 10),
                _buildInputField(
                  controller: _durationController,
                  hintText: 'e.g. 60',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter this field';
                    }
                    final parsed = int.tryParse(value.trim());
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a valid number of minutes';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue,
                      disabledBackgroundColor: _primaryBlue.withValues(
                        alpha: 0.6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Add Task',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    String? hintText,
    Widget? suffixIcon,
    String? errorText,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputAction? textInputAction,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      cursorColor: _primaryBlue,
      validator:
          validator ??
          (value) {
            if (value == null || value.trim().isEmpty) {
              return errorText ?? 'Please enter this field';
            }
            return null;
          },
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
