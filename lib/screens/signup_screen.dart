import 'package:flutter/material.dart';
import 'package:ashesilife/auth_service.dart';
import 'package:ashesilife/services/firestore_service.dart';
import 'package:ashesilife/theme/app_colors.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _service = FirestoreService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;
  String? _selectedMajor;
  String? _errorMessage;
  List<String> _majors = [];

  static const _fallbackMajors = [
    'Business Administration',
    'Computer Engineering',
    'Computer Science',
    'Economics',
    'Electrical Engineering',
    'Law',
    'Mechanical Engineering',
    'Mechatronics',
    'MIS',
  ];

  @override
  void initState() {
    super.initState();
    _loadMajors();
  }

  Future<void> _loadMajors() async {
    try {
      final fetched = await _service.fetchMajors();
      setState(() {
        _majors = fetched.isNotEmpty ? fetched : _fallbackMajors;
      });
    } catch (_) {
      setState(() {
        _majors = _fallbackMajors;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    setState(() {
      _errorMessage = null;
    });
    final name = _nameController.text.trim();
    final id = _studentIdController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();
    if (name.isEmpty ||
        id.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirm.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields.';
      });
      return;
    }
    if (_selectedMajor == null) {
      setState(() {
        _errorMessage = 'Please select your major.';
      });
      return;
    }
    if (!email.endsWith('@ashesi.edu.gh')) {
      setState(() {
        _errorMessage = 'Please use your Ashesi email (@ashesi.edu.gh).';
      });
      return;
    }
    if (password.length < 6) {
      setState(() {
        _errorMessage = 'Password must be at least 6 characters.';
      });
      return;
    }
    if (password != confirm) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
      });
      return;
    }
    if (!_agreedToTerms) {
      setState(() {
        _errorMessage = 'You must agree to the Terms of Service to continue.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
    });
    final String? error = await _authService.signUp(
      fullName: name,
      email: email,
      password: password,
      studentId: id,
      major: _selectedMajor!,
    );
    setState(() {
      _isLoading = false;
    });
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _errorMessage = error;
      });
    } else {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightMaroon,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, top: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Back to Login',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Join Ashesi Life',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Create your account to get started',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Full Name',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: 'Francis Kwame Sewor',
                          prefixIcon: Icon(Icons.person_outlined),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Student ID',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _studentIdController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: '25010336',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Major',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedMajor,
                        decoration: const InputDecoration(
                          hintText: 'Select your major',
                          prefixIcon: Icon(Icons.school_outlined),
                        ),
                        items: _majors
                            .map((m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(m),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() {
                          _selectedMajor = v;
                        }),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Email Address',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: 'your.name@ashesi.edu.gh',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Password',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: 'Create a strong password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(() {
                              _obscurePassword = !_obscurePassword;
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Confirm Password',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleSignUp(),
                        decoration: InputDecoration(
                          hintText: 'Re-enter your password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(() {
                              _obscureConfirm = !_obscureConfirm;
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Checkbox(
                            value: _agreedToTerms,
                            onChanged: (v) => setState(() {
                              _agreedToTerms = v ?? false;
                            }),
                            activeColor: AppColors.lightMaroon,
                          ),
                          Expanded(
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 13,
                                ),
                                children: [
                                  TextSpan(text: 'I agree to the '),
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: TextStyle(
                                      color: AppColors.lightMaroon,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: TextStyle(
                                      color: AppColors.lightMaroon,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 4),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignUp,
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Already have an account? '),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                color: AppColors.lightMaroon,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
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
