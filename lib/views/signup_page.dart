import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vchat/views/login_page.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isPasswordVisible = false;
  bool isLoading = false;
  final supabase = Supabase.instance.client;

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      // 1. First check if user exists in auth table
      final authResponse = await supabase.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        data: {'name': nameController.text.trim()},
      );
      if (authResponse.user != null) {
        // 2. Check if user already exists in your users table
        final existingUser =
            await supabase
                .from('users')
                .select()
                .eq('id', authResponse.user!.id)
                .maybeSingle();

        if (existingUser == null) {
          // 3. Only insert if user doesn't exist
          await supabase.from('users').insert({
            'id': authResponse.user!.id,
            'name': nameController.text.trim(),
            'email': emailController.text.trim(),
            'password': passwordController.text.trim(),
            'created_at': DateTime.now().toIso8601String(),
          });

          debugPrint('User created successfully');
        } else {
          debugPrint('User already exists in database');
          // User exists in auth but we'll proceed anyway
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! You can now login.'),
            backgroundColor: Colors.green,
          ),
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
          );
        }
      }
    } on AuthException catch (e) {
      debugPrint('Auth Error: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('General Error: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Signup")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const CircleAvatar(radius: 60, child: Text("V chat")),
                const SizedBox(height: 20),
                _buildTextField(nameController, "Name", Icons.person),
                _buildTextField(
                  emailController,
                  "Email",
                  Icons.email,
                  email: true,
                ),
                _buildTextField(
                  passwordController,
                  "Password",
                  Icons.lock,
                  password: true,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 120,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : registerUser,
                    child:
                        isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : Center(
                              child: const Text(
                                "Register",
                                style: TextStyle(color: Colors.blue),
                              ),
                            ),
                  ),
                ),
                TextButton(
                  onPressed:
                      isLoading
                          ? null
                          : () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginPage(),
                              ),
                            );
                          },
                  child: const Text(
                    "Already have an account? Login",
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool email = false,
    bool phone = false,
    bool password = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: password && !isPasswordVisible,
        keyboardType:
            phone
                ? TextInputType.phone
                : (email ? TextInputType.emailAddress : TextInputType.text),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon:
              password
                  ? IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed:
                        () => setState(
                          () => isPasswordVisible = !isPasswordVisible,
                        ),
                  )
                  : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return "Please enter $label";
          if (email && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
            return "Enter a valid email";
          }
          if (phone && !RegExp(r'^\d{10,15}$').hasMatch(value)) {
            return "Enter a valid phone number";
          }
          if (password && value.length < 6) {
            return "Password must be at least 6 characters";
          }
          return null;
        },
      ),
    );
  }
}
