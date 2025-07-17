import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/supabase_config.dart';
import 'login.dart';
import 'task_list_page.dart';
import 'add_task_page.dart';
import 'register.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    print('Variables de entorno cargadas correctamente');
  } catch (e) {
    print('No se pudo cargar el archivo .env: $e');
    print('Usando variables de entorno del sistema...');
  }

  if (!SupabaseConfig.isConfigured) {
    print('ERROR: Credenciales de Supabase no configuradas');
    print(SupabaseConfig.debugInfo);
  } else {
    print('Credenciales de Supabase configuradas correctamente');
  }

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return MaterialApp(
      title: 'Supabase To-Do App',
      theme: ThemeData(primarySwatch: Colors.blue),
      // ista de tareas si ya está logueado
      home: supabase.auth.currentUser == null ? const LoginPage() : const TaskListPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/tasks': (context) => const TaskListPage(),
        '/add_task': (context) => const AddTaskPage(),
      },
    );
  }
}
