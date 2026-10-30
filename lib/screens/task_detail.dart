import 'package:flutter/material.dart';
import 'dart:async';
import 'package:focus_study/services/firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:focus_study/models/task.dart';

class TaskDetail extends StatefulWidget {
  final String taskId;
  const TaskDetail({super.key, required this.taskId});

  @override
  State<TaskDetail> createState() => _TaskDetailState();
}

class _TaskDetailState extends State<TaskDetail> {
  // App theme colors
  static const Color _primaryBlue = Color(0xFF5394ED);
  static const Color _darkBlue = Color(0xFF1A52CE);
  static const Color _lightBlue = Color(0xFFE8F0FD);
  static const Color _trackBlue = Color(0xFFE7ECF5);
  static const Color _background = Color(0xFFF0F3FF);

  final FirestoreService _firestoreService = FirestoreService();
  Task? _task;
  bool _isLoading = true;

  Timer? _timer;
  int _secondsElapsed = 0;
  bool _isStudying = false;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadTask() async {
    try {
      final task = await _firestoreService.getTaskById(widget.taskId);
      if (!mounted) return;
      setState(() {
        _task = task;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load task failed: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load task: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleStudy() async {
    if (_isStudying) {
      _timer?.cancel();
      final newTotal = _task!.studiedSeconds + _secondsElapsed;
      final elapsedThisSession = _secondsElapsed;

      setState(() {
        _isStudying = false;
        _task = _task!.copyWith(studiedSeconds: newTotal);
        _secondsElapsed = 0;
      });

      try {
        await _firestoreService.updateStudiedSeconds(widget.taskId, newTotal);
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _task = _task!.copyWith(
            studiedSeconds: newTotal - elapsedThisSession,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save progress'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      setState(() => _isStudying = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _secondsElapsed++);
      });
    }
  }

  Future<void> _deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Task?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: _primaryBlue)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      _timer?.cancel();
      await _firestoreService
          .deleteTask(widget.taskId)
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () =>
                throw Exception('Timed out — check your connection'),
          );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Delete task failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete task: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String get _formattedTime {
    final minutes = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsElapsed % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _task == null) {
      return const Scaffold(
        backgroundColor: _background,
        body: Center(child: CircularProgressIndicator(color: _primaryBlue)),
      );
    }
    final task = _task!;
    final dueDateLabel = DateFormat('dd MMM yyyy').format(task.dueDate);

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Task Details',
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // subject + title
              _buildCard(
                child: Row(
                  children: [
                    _buildIconBox(Icons.folder_rounded),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.subject,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            task.title,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),
              // due date , duration
              Row(
                children: [
                  Expanded(
                    child: _buildCard(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 22,
                            color: _primaryBlue,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dueDateLabel,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  task.dueTime.isEmpty ? '—' : task.dueTime,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildCard(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            size: 22,
                            color: _primaryBlue,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Duration',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  task.duration,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // progress
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Progress',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${(task.progress * 100).round()}%',
                          style: const TextStyle(
                            color: _primaryBlue,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: task.progress,
                        minHeight: 10,
                        backgroundColor: _trackBlue,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          _primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // live session timer
              if (_isStudying || _secondsElapsed > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _lightBlue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _formattedTime,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _darkBlue,
                      letterSpacing: 1.5,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // study button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _toggleStudy,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isStudying
                        ? Colors.redAccent
                        : _primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isStudying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 23,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isStudying ? 'Pause Study' : 'Start Study',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // status card
              _buildCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(color: Colors.black87, fontSize: 15),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: task.isCompleted
                            ? Colors.green.withValues(alpha: 0.12)
                            : _lightBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        task.isCompleted ? 'Completed' : 'In progress',
                        style: TextStyle(
                          color: task.isCompleted ? Colors.green : _primaryBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: _deleteTask,
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                  size: 20,
                ),
                label: const Text(
                  'Delete Task',
                  style: TextStyle(color: Colors.redAccent, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconBox(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _lightBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, size: 26, color: _primaryBlue),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
