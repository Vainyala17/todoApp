import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';

class TaskService {
  // Replace with your Firebase Realtime Database URL
  static const String _baseUrl = 'https://todoapp-34f22-default-rtdb.firebaseio.com';

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Get tasks endpoint for current user
  String get _tasksEndpoint => '$_baseUrl/users/$_currentUserId/tasks.json';

  // Get single task endpoint
  String _taskEndpoint(String taskId) => '$_baseUrl/users/$_currentUserId/tasks/$taskId.json';

  // Get all tasks for current user
  Future<List<TaskModel>> getAllTasks() async {
    print("🟢 TaskService currentUserId: $_currentUserId");

    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await http.get(Uri.parse(_tasksEndpoint));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data == null) {
          return [];
        }

        List<TaskModel> tasks = [];
        data.forEach((key, value) {
          tasks.add(TaskModel.fromMap(Map<String, dynamic>.from(value), key));
        });

        // Sort tasks by creation date (newest first)
        tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return tasks;
      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching tasks: $e');
    }
  }

  // Create a new task
  Future<TaskModel> createTask(TaskModel task) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await http.post(
        Uri.parse(_tasksEndpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(task.toMap()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final taskId = data['name'];
        return task.copyWith(id: taskId);
      } else {
        throw Exception('Failed to create task: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating task: $e');
    }
  }

  // Update an existing task
  Future<TaskModel> updateTask(TaskModel task) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    if (task.id == null) {
      throw Exception('Task ID cannot be null');
    }

    try {
      final response = await http.put(
        Uri.parse(_taskEndpoint(task.id!)),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(task.toMap()),
      );

      if (response.statusCode == 200) {
        return task;
      } else {
        throw Exception('Failed to update task: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating task: $e');
    }
  }

  // Delete a task
  Future<void> deleteTask(String taskId) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await http.delete(Uri.parse(_taskEndpoint(taskId)));

      if (response.statusCode != 200) {
        throw Exception('Failed to delete task: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting task: $e');
    }
  }

  // Get a single task by ID
  Future<TaskModel?> getTaskById(String taskId) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await http.get(Uri.parse(_taskEndpoint(taskId)));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data == null) {
          return null;
        }

        return TaskModel.fromMap(Map<String, dynamic>.from(data), taskId);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load task: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching task: $e');
    }
  }

  // Delete all tasks for current user
  Future<void> deleteAllTasks() async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await http.delete(Uri.parse(_tasksEndpoint));

      if (response.statusCode != 200) {
        throw Exception('Failed to delete all tasks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting all tasks: $e');
    }
  }

  // Search tasks by title
  Future<List<TaskModel>> searchTasks(String query) async {
    final allTasks = await getAllTasks();

    return allTasks.where((task) {
      return task.title.toLowerCase().contains(query.toLowerCase()) ||
          task.description.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Get tasks by completion status
  Future<List<TaskModel>> getTasksByStatus(bool isCompleted) async {
    final allTasks = await getAllTasks();

    return allTasks.where((task) => task.isCompleted == isCompleted).toList();
  }

  // Get tasks count
  Future<Map<String, int>> getTasksCount() async {
    final allTasks = await getAllTasks();

    return {
      'total': allTasks.length,
      'completed': allTasks.where((task) => task.isCompleted).length,
      'pending': allTasks.where((task) => !task.isCompleted).length,
    };
  }
}