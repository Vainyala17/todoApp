import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';

class TaskProvider with ChangeNotifier {
  final TaskService _taskService = TaskService();
  List<TaskModel> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Get completed tasks
  List<TaskModel> get completedTasks => _tasks.where((task) => task.isCompleted).toList();

  // Get pending tasks
  List<TaskModel> get pendingTasks => _tasks.where((task) => !task.isCompleted).toList();

  // Get task count
  int get taskCount => _tasks.length;
  int get completedTaskCount => completedTasks.length;
  int get pendingTaskCount => pendingTasks.length;

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Fetch all tasks
  Future<void> fetchTasks() async {
    _setLoading(true);
    _setError(null);

    try {
      _tasks = await _taskService.getAllTasks();
      _setLoading(false);
    } catch (e) {
      _setError('Failed to fetch tasks: ${e.toString()}');
      _setLoading(false);
    }
  }

  // Add a new task
  Future<void> addTask(TaskModel task) async {
    _setLoading(true);
    _setError(null);

    try {
      final newTask = await _taskService.createTask(task);
      _tasks.add(newTask);
      _setLoading(false);
    } catch (e) {
      _setError('Failed to add task: ${e.toString()}');
      _setLoading(false);
    }
  }

  // Update an existing task
  Future<void> updateTask(TaskModel task) async {
    _setLoading(true);
    _setError(null);

    try {
      final updatedTask = await _taskService.updateTask(task);
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
      }
      _setLoading(false);
    } catch (e) {
      _setError('Failed to update task: ${e.toString()}');
      _setLoading(false);
    }
  }

  // Delete a task
  Future<void> deleteTask(String taskId) async {
    _setLoading(true);
    _setError(null);

    try {
      await _taskService.deleteTask(taskId);
      _tasks.removeWhere((task) => task.id == taskId);
      _setLoading(false);
    } catch (e) {
      _setError('Failed to delete task: ${e.toString()}');
      _setLoading(false);
    }
  }

  // Toggle task completion status
  Future<void> toggleTaskCompletion(String taskId) async {
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex == -1) return;

    final task = _tasks[taskIndex];
    final updatedTask = task.copyWith(
      isCompleted: !task.isCompleted,
      updatedAt: DateTime.now(),
    );

    await updateTask(updatedTask);
  }

  // Clear all tasks
  Future<void> clearAllTasks() async {
    _setLoading(true);
    _setError(null);

    try {
      // Delete all tasks from Firebase
      for (TaskModel task in _tasks) {
        if (task.id != null) {
          await _taskService.deleteTask(task.id!);
        }
      }
      _tasks.clear();
      _setLoading(false);
    } catch (e) {
      _setError('Failed to clear tasks: ${e.toString()}');
      _setLoading(false);
    }
  }

  // Clear completed tasks
  Future<void> clearCompletedTasks() async {
    _setLoading(true);
    _setError(null);

    try {
      final completedTasks = _tasks.where((task) => task.isCompleted).toList();
      for (TaskModel task in completedTasks) {
        if (task.id != null) {
          await _taskService.deleteTask(task.id!);
        }
      }
      _tasks.removeWhere((task) => task.isCompleted);
      _setLoading(false);
    } catch (e) {
      _setError('Failed to clear completed tasks: ${e.toString()}');
      _setLoading(false);
    }
  }

  // Clear error message
  void clearError() {
    _setError(null);
  }
}