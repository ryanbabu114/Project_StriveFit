import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';

class ExercisePage extends StatefulWidget {
  @override
  _ExercisePageState createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  final _supabase = Supabase.instance.client;
  final _nameController = TextEditingController();
  final _detailsController = TextEditingController();
  File? _selectedVideo;
  bool isUploading = false;
  VideoPlayerController? _videoController;

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);

    if (result != null && result.files.single.path != null) {
      _selectedVideo = File(result.files.single.path!);

      _videoController?.dispose();
      _videoController = VideoPlayerController.file(_selectedVideo!)
        ..initialize().then((_) {
          setState(() {});
        });

      setState(() {});
    }
  }

  Future<String?> _uploadVideo(File videoFile) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
      final filePath = 'exercise-videos/$userId/$fileName';

      await _supabase.storage.from('exercise-videos').upload(filePath, videoFile);

      return _supabase.storage.from('exercise-videos').getPublicUrl(filePath);
    } catch (e) {
      print("Upload error: $e");
      return null;
    }
  }

  Future<void> _addExercise() async {
    if (_nameController.text.isEmpty || _detailsController.text.isEmpty || _selectedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select a video.')),
      );
      return;
    }

    setState(() => isUploading = true);

    try {
      final videoUrl = await _uploadVideo(_selectedVideo!);
      if (videoUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video upload failed. Try again.')),
        );
        return;
      }

      await _supabase.from('exercises').insert({
        'trainer_id': _supabase.auth.currentUser!.id,
        'exercise_name': _nameController.text.trim(),
        'details': _detailsController.text.trim(),
        'video_url': videoUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exercise added successfully!')),
      );

      _nameController.clear();
      _detailsController.clear();
      _videoController?.dispose();
      setState(() {
        _selectedVideo = null;
        _videoController = null;
      });
    } catch (e) {
      print("Error: $e");
    }

    setState(() => isUploading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _detailsController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Exercise'),
        backgroundColor: Colors.indigo[600],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Exercise Name',
                    prefixIcon: Icon(Icons.fitness_center),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _detailsController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Exercise Details',
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                ElevatedButton.icon(
                  icon: const Icon(Icons.video_library),
                  label: const Text('Select Video'),
                  onPressed: _pickVideo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigoAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                if (_selectedVideo != null)
                  Column(
                    children: [
                      Text('Selected: ${_selectedVideo!.path.split('/').last}'),
                      const SizedBox(height: 10),
                      if (_videoController != null && _videoController!.value.isInitialized)
                        AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: () {
                          _videoController!.value.isPlaying
                              ? _videoController!.pause()
                              : _videoController!.play();
                          setState(() {});
                        },
                        icon: Icon(_videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow),
                        label: Text(_videoController!.value.isPlaying ? 'Pause Video' : 'Play Video'),
                      ),
                    ],
                  )
                else
                  const Text('No video selected'),

                const SizedBox(height: 20),

                isUploading
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                  icon: const Icon(Icons.upload_rounded),
                  label: const Text('Add Exercise'),
                  onPressed: _addExercise,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
