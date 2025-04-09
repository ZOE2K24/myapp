import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // Add task to Firestore
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

  // Update task completion
  Future<void> updateTask(String id, bool completed) async {
    await db.collection('tasks').doc(id).update({'completed': completed});

    setState(() {
      final task = tasks.firstWhere((task) => task['id'] == id);
      task['completed'] = completed;
    });
  }

  // Delete task
  Future<void> deleteTask(String id) async {
    await db.collection('tasks').doc(id).delete();

    setState(() {
      tasks.removeWhere((task) => task['id'] == id);
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
            Expanded(child: buildTaskList(tasks, updateTask, deleteTask)),
          ],
        ),
      ),
      drawer: const Drawer(),
    );
  }
}

// Section for adding new tasks
Widget buildAddTaskSection(
  TextEditingController controller,
  VoidCallback addTask,
) {
  return Padding(
    padding: const EdgeInsets.all(12.0),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            maxLength: 32,
            controller: controller,
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

// Section to display the task list
Widget buildTaskList(
  List<Map<String, dynamic>> tasks,
  Function(String, bool) updateTask,
  Function(String) deleteTask,
) {
  if (tasks.isEmpty) {
    return const Center(child: Text('No tasks yet!'));
  }

  return ListView.builder(
    itemCount: tasks.length,
    itemBuilder: (context, index) {
      final task = tasks[index];
      return ListTile(
        title: Text(
          task['name'],
          style: TextStyle(
            decoration: task['completed'] ? TextDecoration.lineThrough : null,
          ),
        ),
        leading: Checkbox(
          value: task['completed'],
          onChanged: (value) {
            updateTask(task['id'], value ?? false);
          },
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => deleteTask(task['id']),
        ),
      );
    },
  );
}
