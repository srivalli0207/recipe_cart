import 'package:flutter/material.dart';
import 'package:recipe_cart/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final Function toggleView;

  const LoginScreen({Key? key, required this.toggleView}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  // Text field state
  String email = '';
  String password = '';
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
                      'Your personal recipe assistant',
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Login Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      // Email Field
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (val) => val!.isEmpty ? 'Enter an email' : null,
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

                      // Sign In Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        onPressed: loading ? null : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() => loading = true);

                            dynamic result = await _auth.signInWithEmailAndPassword(email, password);

                            if (result == null) {
                              setState(() {
                                error = 'Could not sign in with those credentials';
                                loading = false;
                              });
                            }
                          }
                        },
                        child: loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                          'Sign In',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),

                      // Error Message
                      const SizedBox(height: 12.0),
                      Text(
                        error,
                        style: const TextStyle(color: Colors.red, fontSize: 14.0),
                      ),

                      // Register Option
                      const SizedBox(height: 20.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account?"),
                          TextButton(
                            onPressed: () => widget.toggleView(),
                            child: const Text('Register'),
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