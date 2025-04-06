// [No changes here]
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UpdateProfilesScreen extends StatefulWidget {
  const UpdateProfilesScreen({Key? key, required String username}) : super(key: key);

  @override
  _UpdateProfilesScreenState createState() => _UpdateProfilesScreenState();
}

class _UpdateProfilesScreenState extends State<UpdateProfilesScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> profiles = [];
  bool isLoading = true;
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  @override
  void initState() {
    super.initState();
    fetchProfiles();
    listenToProfileUpdates();
  }

  Future<void> fetchProfiles() async {
    try {
      final response = await supabase.from('profiles').select();
      if (mounted) {
        setState(() {
          profiles = List<Map<String, dynamic>>.from(response);
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Error fetching profiles: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  void listenToProfileUpdates() {
    _subscription = supabase.from('profiles').stream(primaryKey: ['user_id']).listen((data) {
      if (mounted) {
        setState(() => profiles = List<Map<String, dynamic>>.from(data));
      }
    });
  }

  Future<void> updateProfile(String id, Map<String, dynamic> updatedData) async {
    try {
      await supabase.from('profiles').update(updatedData).eq('user_id', id);
      fetchProfiles();
    } catch (e) {
      print("❌ Error updating profile: $e");
    }
  }

  Future<void> deleteProfile(String userId) async {
    try {
      await supabase.from('profiles').delete().eq('user_id', userId);
      fetchProfiles();
    } catch (e) {
      print("❌ Error deleting profile: $e");
    }
  }

  void confirmDeleteProfile(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Profile"),
        content: const Text("Are you sure you want to delete this profile?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
            onPressed: () {
              deleteProfile(userId);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void showEditDialog(BuildContext context, Map<String, dynamic> profile) {
    TextEditingController nameController = TextEditingController(text: profile['name'] ?? '');
    TextEditingController emailController = TextEditingController(text: profile['email'] ?? '');
    TextEditingController roleController = TextEditingController(text: profile['role'] ?? '');
    TextEditingController heightController = TextEditingController(text: profile['height']?.toString() ?? '');
    TextEditingController weightController = TextEditingController(text: profile['weight']?.toString() ?? '');
    TextEditingController ageController = TextEditingController(text: profile['age']?.toString() ?? '');
    TextEditingController dobController = TextEditingController(text: profile['date_of_birth'] ?? '');
    String? imageUrl = profile['image_url'];
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                if (imageUrl?.isNotEmpty == true)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(imageUrl!, height: 100, width: 100, fit: BoxFit.cover),
                  ),
                TextButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      setDialogState(() => isUploading = true);
                      String? uploadedUrl = await uploadImage(File(pickedFile.path), profile['user_id']);
                      if (uploadedUrl != null) {
                        setDialogState(() {
                          imageUrl = uploadedUrl;
                          isUploading = false;
                        });
                      }
                    }
                  },
                  icon: const Icon(Icons.image),
                  label: isUploading ? const CircularProgressIndicator() : const Text('Change Image'),
                ),
                const SizedBox(height: 10),
                _buildTextField(nameController, 'Name'),
                _buildTextField(emailController, 'Email'),
                _buildTextField(roleController, 'Role'),
                _buildTextField(heightController, 'Height (cm)', isNumber: true),
                _buildTextField(weightController, 'Weight (kg)', isNumber: true),
                _buildTextField(ageController, 'Age', isNumber: true),
                _buildTextField(dobController, 'Date of Birth'),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                updateProfile(profile['user_id'], {
                  'name': nameController.text,
                  'email': emailController.text,
                  'role': roleController.text,
                  'height': double.tryParse(heightController.text),
                  'weight': double.tryParse(weightController.text),
                  'age': int.tryParse(ageController.text),
                  'date_of_birth': dobController.text,
                  if (imageUrl?.isNotEmpty == true) 'image_url': imageUrl,
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Future<String?> uploadImage(File imageFile, String userId) async {
    try {
      final String filePath = 'profiles/$userId/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('profileimages').upload(filePath, imageFile);
      final String publicUrl = supabase.storage.from('profileimages').getPublicUrl(filePath);
      await supabase.from('profiles').update({'image_url': publicUrl}).eq('user_id', userId);
      return publicUrl;
    } catch (e) {
      print("❌ Image Upload Error: $e");
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
      appBar: AppBar(title: const Text('All Profiles')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : profiles.isEmpty
          ? const Center(child: Text("No profiles found", style: TextStyle(fontSize: 18)))
          : ListView.builder(
        itemCount: profiles.length,
        itemBuilder: (context, index) {
          final profile = profiles[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                radius: 30,
                backgroundImage: profile['image_url']?.isNotEmpty == true
                    ? NetworkImage(profile['image_url'])
                    : null,
                child: profile['image_url']?.isNotEmpty != true
                    ? const Icon(Icons.person, size: 30)
                    : null,
              ),
              title: Text(
                profile['name'] ?? 'No Name',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  "Role: ${profile['role'] ?? 'Unknown'}\nEmail: ${profile['email'] ?? 'N/A'}",
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blueAccent),
                    onPressed: () => showEditDialog(context, profile),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => confirmDeleteProfile(context, profile['user_id']),
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
