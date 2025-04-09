import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:table_calendar/table_calendar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  final List<Map<String, dynamic>> tasks = [];
  final TextEditingController nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  // Fetch tasks from Firestore
  Future<void> fetchTasks() async {
    final snapshots = await db.collection('tasks').orderBy('timestamp').get();

    setState(() {
      tasks.clear();
      tasks.addAll(
        snapshots.docs.map(
          (doc) => {
            'id': doc.id,
            'name': doc.get('name'),
            'completed': doc.get('completed') ?? false,
          },
        ),
      );
    });
  }

  // Add task
  Future<void> addTask() async {
    final taskName = nameController.text.trim();

    if (taskName.isNotEmpty) {
      final newTask = {
        'name': taskName,
        'completed': false,
        'timestamp': FieldValue.serverTimestamp(),
      };

      final docRef = await db.collection('tasks').add(newTask);

      setState(() {
        tasks.add({'id': docRef.id, ...newTask});
        nameController.clear();
      });
    }
  }

  // Update task status
  Future<void> updateTask(int index, bool completed) async {
    final task = tasks[index];
    await db.collection('tasks').doc(task['id']).update({
      'completed': completed,
    });

    setState(() {
      tasks[index]['completed'] = completed;
    });
  }

  // Delete task
  Future<void> removeTasks(int index) async {
    final task = tasks[index];
    await db.collection('tasks').doc(task['id']).delete();

    setState(() {
      tasks.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(child: Image.asset('assets/rdplogo.png', height: 80)),
            const Text(
              'RDP Daily Planner',
              style: TextStyle(
                fontFamily: 'Caveat',
                fontSize: 32,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 340,
              child: TableCalendar(
                calendarFormat: CalendarFormat.month,
                focusedDay: DateTime.now(),
                firstDay: DateTime(2025),
                lastDay: DateTime(2026),
              ),
            ),
            buildAddTaskSection(nameController, addTask),
            const SizedBox(height: 10),
            Expanded(child: buildTaskList(tasks, updateTask, removeTasks)),
          ],
        ),
      ),
      drawer: const Drawer(),
    );
  }
}

// Section to add tasks
Widget buildAddTaskSection(
  TextEditingController nameController,
  VoidCallback addTask,
) {
  return Padding(
    padding: const EdgeInsets.all(12.0),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            maxLength: 32,
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Add Task',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(onPressed: addTask, child: const Text('Add Task')),
      ],
    ),
  );
}

// Task list
Widget buildTaskList(
  List<Map<String, dynamic>> tasks,
  Function(int, bool) updateTask,
  Function(int) removeTasks,
) {
  return ListView.builder(
    physics: const NeverScrollableScrollPhysics(),
    itemCount: tasks.length,
    itemBuilder: (context, index) {
      final task = tasks[index];
      return ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: Icon(
          task['completed'] ? Icons.check_circle : Icons.circle_outlined,
        ),
        title: Text(
          task['name'],
          style: TextStyle(
            decoration: task['completed'] ? TextDecoration.lineThrough : null,
            fontSize: 22,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: task['completed'],
              onChanged: (value) => updateTask(index, value ?? false),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => removeTasks(index),
            ),
          ],
        ),
      );
    },
  );
}
