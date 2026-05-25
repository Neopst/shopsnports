import 'package:flutter/material.dart';

/// Simple production task tracker for ShopsNports app
class TaskTracker extends StatelessWidget {
  final List<String> tasks;
  final List<bool> completed;

  const TaskTracker({super.key, required this.tasks, required this.completed});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Production Task Tracker',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...List.generate(
                tasks.length, (i) => _buildTask(tasks[i], completed[i])),
          ],
        ),
      ),
    );
  }

  Widget _buildTask(String task, bool done) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: done ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              task,
              style: TextStyle(
                fontSize: 16,
                decoration: done ? TextDecoration.lineThrough : null,
                color: done ? Colors.grey : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Example usage (add to any screen):
/// TaskTracker(
///   tasks: [
///     'Implement shipping request flow',
///     'Integrate affiliate dashboard',
///     'Enable push notifications',
///     'Test on Android and iOS',
///     'Finalize Firestore security rules',
///     'Production deployment',
///   ],
///   completed: [true, true, true, false, false, false],
/// )
