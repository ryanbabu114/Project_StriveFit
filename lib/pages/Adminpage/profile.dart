import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilesScreen extends StatefulWidget {
  final String username;

  const ProfilesScreen({Key? key, required this.username}) : super(key: key);

  @override
  _ProfilesScreenState createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> profiles = [];
  bool isLoading = true;
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      fetchProfiles();
      listenToProfileUpdates();
    });
  }

  Future<void> fetchProfiles() async {
    try {
      final List<dynamic> response =
      await supabase.from('profiles').select().eq('email', widget.username);
      if (mounted) {
        setState(() {
          profiles = response.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void listenToProfileUpdates() {
    _subscription = supabase
        .from('profiles')
        .stream(primaryKey: ['user_id'])
        .eq('email', widget.username)
        .listen((data) {
      if (mounted) {
        setState(() {
          profiles = data.cast<Map<String, dynamic>>();
        });
      }
    });
  }

  Future<void> updateProfile(
      String id,
      String name,
      String email,
      String role,
      double? height,
      double? weight,
      int? age,
      String? dob,
      String? imageUrl) async {
    await supabase.from('profiles').update({
      'name': name,
      'email': email,
      'role': role,
      'height': height,
      'weight': weight,
      'age': age,
      'date_of_birth': dob,
      if (imageUrl != null) 'image_url': imageUrl,
    }).eq('user_id', id);

    fetchProfiles();
  }

  void showEditDialog(BuildContext context, Map<String, dynamic> profile) {
    TextEditingController nameController =
    TextEditingController(text: profile['name'] ?? '');
    TextEditingController emailController =
    TextEditingController(text: profile['email'] ?? '');
    TextEditingController roleController =
    TextEditingController(text: profile['role'] ?? '');
    TextEditingController heightController =
    TextEditingController(text: profile['height']?.toString() ?? '');
    TextEditingController weightController =
    TextEditingController(text: profile['weight']?.toString() ?? '');
    TextEditingController ageController =
    TextEditingController(text: profile['age']?.toString() ?? '');
    TextEditingController dobController =
    TextEditingController(text: profile['date_of_birth'] ?? '');
    String? imageUrl = profile['image_url'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name')),
                TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email')),
                TextField(
                    controller: roleController,
                    decoration: const InputDecoration(labelText: 'Role')),
                TextField(
                    controller: heightController,
                    decoration: const InputDecoration(labelText: 'Height (cm)'),
                    keyboardType: TextInputType.number),
                TextField(
                    controller: weightController,
                    decoration: const InputDecoration(labelText: 'Weight (kg)'),
                    keyboardType: TextInputType.number),
                TextField(
                    controller: ageController,
                    decoration: const InputDecoration(labelText: 'Age'),
                    keyboardType: TextInputType.number),
                TextField(
                    controller: dobController,
                    decoration:
                    const InputDecoration(labelText: 'Date of Birth')),
                if (imageUrl != null && imageUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Image.network(imageUrl!,
                        height: 100, width: 100, fit: BoxFit.cover),
                  ),
                TextButton(
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? pickedFile =
                    await picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      String? uploadedUrl =
                      await uploadImage(File(pickedFile.path));
                      if (uploadedUrl != null) {
                        setDialogState(() => imageUrl = uploadedUrl);
                      }
                    }
                  },
                  child: const Text('Change Image'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                updateProfile(
                  profile['user_id'],
                  nameController.text,
                  emailController.text,
                  roleController.text,
                  double.tryParse(heightController.text),
                  double.tryParse(weightController.text),
                  int.tryParse(ageController.text),
                  dobController.text,
                  imageUrl,
                );
                Navigator.pop(context);
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      final String filePath =
          'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('profileimages').upload(filePath, imageFile);
      return supabase.storage.from('profileimages').getPublicUrl(filePath);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile - ${widget.username}'),
        backgroundColor: Colors.indigo[600],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : profiles.isEmpty
          ? const Center(
        child: Text(
          "No profile found",
          style: TextStyle(fontSize: 20),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: profiles.length,
        itemBuilder: (context, index) {
          final profile = profiles[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 6,
            margin: const EdgeInsets.symmetric(vertical: 12),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (profile['image_url'] != null &&
                      profile['image_url'].isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Image.network(
                        profile['image_url'],
                        height: 120,
                        width: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    profile['name'] ?? 'No Name',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ProfileInfoRow(
                      icon: Icons.email, text: profile['email']),
                  ProfileInfoRow(
                      icon: Icons.person,
                      text: "Role: ${profile['role'] ?? 'N/A'}"),
                  ProfileInfoRow(
                      icon: Icons.height,
                      text:
                      "Height: ${profile['height']?.toString() ?? 'N/A'} cm"),
                  ProfileInfoRow(
                      icon: Icons.monitor_weight,
                      text:
                      "Weight: ${profile['weight']?.toString() ?? 'N/A'} kg"),
                  ProfileInfoRow(
                      icon: Icons.cake,
                      text: "Age: ${profile['age']?.toString() ?? 'N/A'}"),
                  ProfileInfoRow(
                      icon: Icons.calendar_today,
                      text: "DOB: ${profile['date_of_birth'] ?? 'N/A'}"),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () =>
                        showEditDialog(context, profile),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo[300],
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

// 🧩 Helper widget for better UI layout of profile details
class ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String? text;

  const ProfileInfoRow({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.indigo[400], size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text ?? 'N/A',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
