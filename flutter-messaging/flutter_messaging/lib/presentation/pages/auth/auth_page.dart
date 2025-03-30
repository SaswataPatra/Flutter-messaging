import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../home/home_page.dart';

// Simple state provider for authentication state
final authProvider = StateProvider<bool>((ref) => false);

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isSignUp = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _errorMessage = null;
    });
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // For web demo, we'll accept any credentials
    if (mounted) {
      ref.read(authProvider.notifier).state = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // For web demo, we'll accept any credentials
    if (mounted) {
      ref.read(authProvider.notifier).state = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  Future<void> _signInAnonymously() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // For web demo
    if (mounted) {
      ref.read(authProvider.notifier).state = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App icon
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 70,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  
                  // App name
                  Text(
                    'Flutter Messaging',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Subtitle
                  Text(
                    _isSignUp ? 'Create a new account' : 'Sign in to your account',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  
                  // Error message
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Name field (only in sign-up mode)
                  if (_isSignUp) ...[
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Email field
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  
                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (_isSignUp && value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                    textInputAction: _isSignUp ? TextInputAction.next : TextInputAction.done,
                  ),
                  const SizedBox(height: 24),
                  
                  // Sign-in/Sign-up button
                  FilledButton(
                    onPressed: _isLoading ? null : (_isSignUp ? _signUp : _signIn),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_isSignUp ? 'Sign Up' : 'Sign In'),
                  ),
                  const SizedBox(height: 16),
                  
                  // Toggle mode button
                  TextButton(
                    onPressed: _toggleMode,
                    child: Text(
                      _isSignUp
                          ? 'Already have an account? Sign In'
                          : 'Don\'t have an account? Sign Up',
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Anonymous sign-in
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signInAnonymously,
                    icon: const Icon(Icons.person_outline),
                    label: const Text('Continue as Guest'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 