import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focus_study/services/firestore_service.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:focus_study/screens/task_history.dart';
import 'package:focus_study/screens/add_task.dart';
import 'package:focus_study/screens/task_detail.dart';
import 'package:focus_study/models/task.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // App theme colors
  static const Color _primaryBlue = Color(0xFF5394ED);
  static const Color _darkBlue = Color(0xFF1A52CE);
  static const Color _lightBlue = Color(0xFFE8F0FD);
  static const Color _trackBlue = Color(0xFFE7ECF5);
  static const Color _background = Color(0xFFF0F3FF);
  static const Color _inactiveGrey = Color(0xFF8C93A0);

  int index = 0;

  String _userName = '';
  final FirestoreService _firestoreService = FirestoreService();

  late final Stream<List<Task>> _tasksStream = _firestoreService
      .getTasksStream();

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userName = prefs.getString('userName') ?? 'there';
    });
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning!';
    if (hour < 17) return 'Good Afternoon!';
    return 'Good Evening!';
  }

  String _formatFocusTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  void _openTaskDetail(String taskId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskDetail(taskId: taskId)),
    ).then((result) {
      if (result == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 17.0),
          child: StreamBuilder<List<Task>>(
            stream: _tasksStream,
            builder: (context, snapshot) {
              final tasks = snapshot.data ?? [];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildHeroCard(tasks),
                  const SizedBox(height: 20),
                  const Text(
                    "Today's Plan",
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(child: _buildTaskList(snapshot, tasks)),
                  const SizedBox(height: 12),
                  _buildMotivationCard(),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  //  Header
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _lightBlue,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.person, color: _primaryBlue),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greeting,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _inactiveGrey,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _userName,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: _darkBlue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Hero card
  Widget _buildHeroCard(List<Task> tasks) {
    final total = tasks.length;
    final done = tasks.where((t) => t.isCompleted).length;
    final focusSeconds = tasks.fold<int>(0, (sum, t) => sum + t.studiedSeconds);
    final ratio = total == 0 ? 0.0 : done / total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [_primaryBlue, Color(0xFFB1D1FF)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Focus",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$done of $total tasks completed',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_formatFocusTime(focusSeconds)} focus time',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.35),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Image.asset(
            'assets/books.png',
            fit: BoxFit.contain,
            height: 90,
            width: 90,
          ),
        ],
      ),
    );
  }

  // Task list
  Widget _buildTaskList(AsyncSnapshot<List<Task>> snapshot, List<Task> tasks) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryBlue),
      );
    }
    if (snapshot.hasError) {
      return _buildMessage(Icons.error_outline, 'Something went wrong');
    }
    if (tasks.isEmpty) {
      return _buildMessage(Icons.menu_book_rounded, 'No tasks yet — add one!');
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: tasks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, i) => _buildTaskCard(tasks[i]),
    );
  }

  Widget _buildMessage(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: _primaryBlue.withValues(alpha: 0.4)),
          const SizedBox(height: 10),
          Text(text, style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openTaskDetail(task.id),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _lightBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.book_rounded,
                  color: _primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF2D2D2D),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          task.duration,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      value: task.progress,
                      backgroundColor: _trackBlue,
                      strokeWidth: 4,
                      strokeCap: StrokeCap.round,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        _primaryBlue,
                      ),
                    ),
                  ),
                  Text(
                    '${(task.progress * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Motivation card
  Widget _buildMotivationCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(bottom: 40, left: 4, right: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _lightBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: _primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Motivation',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2),
                Text(
                  "Consistency beats talent when talent doesn't work hard",
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: Colors.black54,
                    fontStyle: FontStyle.italic,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Bottom navigation
  CurvedNavigationBarItem _navItem(IconData icon, String label, int i) {
    final selected = index == i;
    return CurvedNavigationBarItem(
      child: Icon(
        icon,
        size: 28,
        color: selected ? Colors.white : _inactiveGrey,
      ),
      label: label,
      labelStyle: TextStyle(
        fontSize: 12,
        color: selected ? _darkBlue : _inactiveGrey,
      ),
    );
  }

  Widget _buildBottomNav() {
    return CurvedNavigationBar(
      height: 60,
      index: index,
      items: [
        _navItem(Icons.home, 'Dashboard', 0),
        _navItem(Icons.add_circle_rounded, 'Add', 1),
        _navItem(Icons.history_edu_outlined, 'History', 2),
      ],
      color: Colors.white,
      buttonBackgroundColor: _darkBlue,
      backgroundColor: _background,
      animationCurve: Curves.easeInOut,
      animationDuration: const Duration(milliseconds: 300),
      onTap: (i) {
        setState(() => index = i);

        if (i == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTask()),
          ).then((result) {
            if (!mounted) return;
            // Return the highlight to Dashboard when coming back
            setState(() => index = 0);
            if (result == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Task added successfully!'),
                  duration: Duration(seconds: 2),
                  backgroundColor: Colors.green,
                ),
              );
            }
          });
        } else if (i == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TaskHistory()),
          ).then((_) {
            if (mounted) setState(() => index = 0);
          });
        }
      },
    );
  }
}
