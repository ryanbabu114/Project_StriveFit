import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Adminpage/AdminPage.dart';
import '../Clientpage/ClientPage.dart';
import '../Owner/OwnerPage.dart';
import '../Trainerpage/TrainerPage.dart';
import 'ForgotPasswordPage.dart';
import 'SignUpPage.dart';

class LoginPage extends StatefulWidget {
  final bool isTrainer;
  final bool isOwner;
  final bool isClient;
  final bool isAdmin;

  const LoginPage({
    super.key,
    required this.isTrainer,
    required this.isOwner,
    required this.isClient,
    required this.isAdmin,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _supabase = Supabase.instance.client;
  bool isLoading = false;

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields.')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user != null) {
        final userId = response.user!.id;

        final roleResponse = await _supabase
            .from('profiles')
            .select('role')
            .eq('user_id', userId)
            .maybeSingle();

        if (roleResponse == null || !roleResponse.containsKey('role')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Your account has no assigned role.')),
          );
          await _supabase.auth.signOut();
          setState(() => isLoading = false);
          return;
        }

        final role = roleResponse['role'].toLowerCase();

        if (role == 'trainer' && widget.isTrainer) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TrainerPage(username: response.user!.email!),
            ),
          );
        } else if (role == 'client' && widget.isClient) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ClientPage(username: response.user!.email!),
            ),
          );
        } else if (role == 'owner' && widget.isOwner) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OwnerPage(username: response.user!.email!),
            ),
          );
        } else if (role == 'admin' && widget.isAdmin) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Adminpage(username: response.user!.email!),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unauthorized login attempt!')),
          );
          await _supabase.auth.signOut();
        }
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong. Try again.')),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    String title;
    if (widget.isOwner) {
      title = "Owner Login";
    } else if (widget.isTrainer) {
      title = "Trainer Login";
    } else if (widget.isClient) {
      title = "Client Login";
    } else if (widget.isAdmin) {
      title = "Admin Login";
    } else {
      title = "Login";
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        backgroundColor: Colors.indigo[700],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Welcome Back!',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 24),
                    isLoading
                        ? const CircularProgressIndicator()
                        : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo[300],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _login,
                        child: const Text(
                          'Login',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordPage(),
                          ),
                        );
                      },
                      child: const Text("Forgot Password?"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
