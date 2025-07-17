import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _titleController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isCompleted = false;
  bool _isShared = false;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        final Uint8List imageBytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageBytes = imageBytes;
          _selectedImageName = pickedFile.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar la imagen: $e')),
      );
    }
  }

  // Nuevo método para mostrar diálogo y elegir fuente
  Future<void> _showImageSourceDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Seleccionar fuente de imagen'),
        actions: [
          TextButton.icon(
            icon: Icon(Icons.photo_library),
            label: Text('Galería'),
            onPressed: () {
              Navigator.of(context).pop();
              _pickImage(ImageSource.gallery);
            },
          ),
          TextButton.icon(
            icon: Icon(Icons.camera_alt),
            label: Text('Cámara'),
            onPressed: () {
              Navigator.of(context).pop();
              _pickImage(ImageSource.camera);
            },
          ),
        ],
      ),
    );
  }

  Future<String?> _uploadImage(Uint8List imageBytes, String fileName) async {
  try {
    final path = 'tareas_fotos/$fileName';
    await supabase.storage.from('fotospublicas').uploadBinary(path, imageBytes);
    return supabase.storage.from('fotospublicas').getPublicUrl(path);
  } catch (e) {
    print('Error al subir la imagen: $e');
    return null;
  }
}


  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      String? imageUrl;
      if (_selectedImageBytes != null) {
        final fileName = 'task_${DateTime.now().millisecondsSinceEpoch}.jpg';
        imageUrl = await _uploadImage(_selectedImageBytes!, fileName);
      }
      await supabase.from('tareas').insert({
        'titulo': _titleController.text.trim(),
        'estado': _isCompleted,
        'foto_url': imageUrl,
        'fecha_creacion': DateTime.now().toIso8601String(),
        'usuario_id': user?.id,
        'compartida': _isShared,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar tarea: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Nueva Tarea')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView( // mejor usar ListView para scroll en pantallas pequeñas
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Título de la tarea'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Ingrese un título' : null,
              ),
              SwitchListTile(
                title: Text('¿Tarea completada?'),
                value: _isCompleted,
                onChanged: (val) => setState(() => _isCompleted = val),
              ),
              SwitchListTile(
                title: Text('¿Compartida con otros?'),
                value: _isShared,
                onChanged: (val) => setState(() => _isShared = val),
              ),

              // Sección de foto con vista previa y botón para seleccionar
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.purple[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.purple[300]!, width: 2),
                      ),
                      child: _selectedImageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.memory(
                                _selectedImageBytes!,
                                width: 150,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(
                              Icons.person_rounded,
                              size: 60,
                              color: Colors.deepPurple,
                            ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _showImageSourceDialog,
                      icon: Icon(_selectedImageBytes != null
                          ? Icons.edit_rounded
                          : Icons.camera_alt_rounded),
                      label:
                          Text(_selectedImageBytes != null ? 'Cambiar foto' : 'Agregar foto'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveTask,
                      child: Text('Guardar Tarea'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}
