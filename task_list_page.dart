import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'add_task_page.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  final SupabaseClient supabase = Supabase.instance.client;

  List<dynamic> _tasks = [];
  bool _isLoading = false;

  Future<void> _fetchTasks() async {
    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _tasks = [];
          _isLoading = false;
        });
        return;
      }

      final response = await supabase
          .from('tareas')
          .select()
          .or('usuario_id.eq.${user.id},compartida.eq.true')
          .order('fecha_creacion', ascending: false);

      setState(() {
        _tasks = response as List<dynamic>;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar tareas: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleTaskCompletion(String taskId, bool currentState) async {
    try {
      final res = await supabase
          .from('tareas')
          .update({'estado': !currentState})
          .eq('id', taskId)
          .select()
          .single();

      // Actualizar la lista local
      setState(() {
        int index = _tasks.indexWhere((t) => t['id'] == taskId);
        if (index != -1) {
          _tasks[index]['estado'] = !currentState;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar tarea: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Tareas'),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? const Center(child: Text('No hay tareas para mostrar'))
              : RefreshIndicator(
                  onRefresh: _fetchTasks,
                  child: ListView.builder(
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      return Card(
                        margin:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: task['foto_url'] != null
                              ? Image.network(
                                  task['foto_url'],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.task_alt_rounded, size: 40),
                          title: Text(task['titulo'] ?? 'Sin título'),
                          subtitle: Text(
                            task['compartida'] == true ? 'Compartida' : 'Privada',
                            style: TextStyle(
                              color: task['compartida'] == true
                                  ? Colors.green
                                  : Colors.grey[600],
                            ),
                          ),
                          trailing: Checkbox(
                            value: task['estado'] == true,
                            onChanged: (value) {
                              _toggleTaskCompletion(task['id'], task['estado']);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTaskPage()),
          );
          if (result == true) {
            _fetchTasks();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
