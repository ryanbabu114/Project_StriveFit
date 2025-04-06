import 'package:flutter/material.dart';
import 'LoginPage.dart';

class GymHomePage extends StatefulWidget {
  const GymHomePage({super.key});

  @override
  State<GymHomePage> createState() => _GymHomePageState();
}

class _GymHomePageState extends State<GymHomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOut,
        ));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 🔘 Reusable button builder with animation
  Widget _buildRoleButton(BuildContext context, String label, Widget page) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo[500],
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 6,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => page),
              );
            },
            child: Text(
              label,
              style: const TextStyle(fontSize: 20, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Strive Fit', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.indigo.withOpacity(0.8),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // ✅ Background Image
          Positioned.fill(
            child: Image.asset(
              'images/jym1.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // ✅ Dark overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.4),
            ),
          ),

          // ✅ Animated Content
          Center(
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 32),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Welcome to Strive Fit',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Are you a Trainer, Client, Owner or Admin?',
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // 👤 Buttons
                      _buildRoleButton(
                          context,
                          'Client',
                          const LoginPage(
                              isTrainer: false,
                              isOwner: false,
                              isAdmin: false,
                              isClient: true)),
                      const SizedBox(height: 20),
                      _buildRoleButton(
                          context,
                          'Trainer',
                          const LoginPage(
                              isTrainer: true,
                              isOwner: false,
                              isAdmin: false,
                              isClient: false)),
                      const SizedBox(height: 20),
                      _buildRoleButton(
                          context,
                          'Owner',
                          const LoginPage(
                              isTrainer: false,
                              isOwner: true,
                              isAdmin: false,
                              isClient: false)),
                      const SizedBox(height: 20),
                      _buildRoleButton(
                          context,
                          'Admin',
                          const LoginPage(
                              isTrainer: false,
                              isOwner: false,
                              isAdmin: true,
                              isClient: false)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
