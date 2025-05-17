import 'package:flutter/material.dart';
import 'package:recipe_cart/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  final Function toggleView;

  const RegisterScreen({Key? key, required this.toggleView}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  // Text field state
  String email = '';
  String password = '';
  String displayName = '';
  String error = '';
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Logo and App Name
                Column(
                  children: [
                    Icon(
                      Icons.restaurant,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Recipe Cart',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create your account',
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Register Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      // Display Name Field
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (val) => val!.isEmpty ? 'Enter your name' : null,
                        onChanged: (val) {
                          setState(() => displayName = val);
                        },
                      ),
                      const SizedBox(height: 20.0),

                      // Email Field
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Enter an email';
                          }
                          final emailPattern = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailPattern.hasMatch(val)) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                        onChanged: (val) {
                          setState(() => email = val);
                        },
                      ),
                      const SizedBox(height: 20.0),

                      // Password Field
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                        validator: (val) =>
                        val!.length < 6 ? 'Password must be 6+ chars long' : null,
                        onChanged: (val) {
                          setState(() => password = val);
                        },
                      ),
                      const SizedBox(height: 30.0),

                      // Register Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        onPressed: loading ? null : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() => loading = true);

                            print("Starting registration process with email: $email");

                            dynamic result = await _auth.registerWithEmailAndPassword(
                                email, password, displayName);

                            if (result == null) {
                              setState(() {
                                error = 'Please supply a valid email and password (6+ characters)';
                                loading = false;
                                print("Registration failed: $error");
                              });
                            } else {
                              print("Registration successful");
                            }
                          }
                        },
                        child: loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                          'Register',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),

                      // Error Message
                      const SizedBox(height: 12.0),
                      Text(
                        error,
                        style: const TextStyle(color: Colors.red, fontSize: 14.0),
                      ),

                      // Sign In Option
                      const SizedBox(height: 20.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Already have an account?'),
                          TextButton(
                            onPressed: () => widget.toggleView(),
                            child: const Text('Sign In'),
                          ),
                        ],
                      ),
                    ],
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