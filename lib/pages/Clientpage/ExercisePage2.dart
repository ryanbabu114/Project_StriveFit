import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

class ExercisesScreen extends StatefulWidget {
  @override
  _ExercisesScreenState createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> exercises = [];
  bool isLoading = true;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    fetchExercises();
  }

  Future<void> fetchExercises() async {
    try {
      final response = await supabase
          .from('exercises')
          .select('id, exercise_name, details, video_url, trainer_id, profiles(name)');

      if (mounted) {
        setState(() {
          exercises = List<Map<String, dynamic>>.from(response);
          isLoading = false;
        });
      }
    } catch (error) {
      print("❌ Error fetching exercises: $error");
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = "Failed to load exercises. Please try again.";
        });
      }
    }
  }

  String getTrainerName(Map<String, dynamic> exercise) {
    return exercise['profiles']?['name'] ?? "Unknown";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Exercises")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage))
          : exercises.isEmpty
          ? const Center(child: Text("No exercises found"))
          : ListView.builder(
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          final exercise = exercises[index];
          final trainerName = getTrainerName(exercise);

          return Card(
            margin: const EdgeInsets.all(12),
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exercise['exercise_name'] ?? "N/A",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Trainer: $trainerName"),
                  const SizedBox(height: 8),
                  Text(exercise['details'] ?? "No details"),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.play_circle_fill, size: 32),
                      onPressed: () {
                        if (exercise['video_url'] != null &&
                            exercise['video_url'].isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  VideoPlayerScreen(videoUrl: exercise['video_url']),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// 🎬 Video Player Screen
class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerScreen({super.key, required this.videoUrl});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  ChewieController? _chewieController;
  bool isVideoReady = false;

  @override
  void initState() {
    super.initState();
    initializeVideo();
  }

  void initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _controller.initialize();

      if (_controller.value.isInitialized && mounted) {
        setState(() {
          _chewieController = ChewieController(
            videoPlayerController: _controller,
            autoPlay: true,
            looping: false,
            showControls: true,
          );
          isVideoReady = true;
        });
      }
    } catch (error) {
      print("❌ Error loading video: $error");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Video Player")),
      body: Center(
        child: isVideoReady
            ? Chewie(controller: _chewieController!)
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text("Loading Video..."),
          ],
        ),
      ),
    );
  }
}
