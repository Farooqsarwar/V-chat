import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vchat/views/chat_screen.dart';
import 'package:vchat/views/signup_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Added Form Key
  bool isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey, // Assign Form Key
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  const CircleAvatar(
                    radius: 60,
                    child: Text("V chat"),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Secure Chat ",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Email Field
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  TextFormField(
                    controller: passwordController,
                    obscureText: !isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () => setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        }),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Forgot Password Button
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/forgot-password');
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Login Button
                  SizedBox(
                    width: 100,
                    height: 60,
                    child: TextButton(
                      onPressed: () => loginUser(context), // Call login function
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Register Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                         Navigator.push(context, MaterialPageRoute(builder: (context)=>SignupPage()));
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          foregroundColor: Colors.blue,
                        ),
                        child: const Text(
                          'Register',
                          style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void loginUser(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        );

        final supabase = Supabase.instance.client; // Get Supabase instance

        final AuthResponse res = await supabase.auth.signInWithPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        // Close loading indicator
        if (context.mounted) {
          Navigator.pop(context);
        }

        if (res.user != null) {
          emailController.clear();
          passwordController.clear();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully logged in'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.push(context, MaterialPageRoute(builder: (context)=>ChatScreen())); // Added missing semicolon
        }
      } catch (e) {
        if (context.mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        emailController.clear();
        passwordController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
        print("Login failed: $e");
      }
    }
  }
}
