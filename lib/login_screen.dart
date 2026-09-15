import 'package:flutter/material.dart';
import 'package:duet_smart_bus_tracker/models/user_model.dart';
import 'package:duet_smart_bus_tracker/services/auth_service.dart';
import 'package:duet_smart_bus_tracker/main_screen.dart';
import 'package:duet_smart_bus_tracker/driver_screen.dart';
import 'package:duet_smart_bus_tracker/admin_screen.dart';
import 'package:duet_smart_bus_tracker/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  UserRole _selectedRole = UserRole.student;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController.text = "delowar20@gmail.com";
    _passwordController.text = "1234";
  }

  void _onRoleChanged(UserRole role) {
    setState(() {
      _selectedRole = role;
      if (role == UserRole.student) {
        _emailController.text = "student@duet.ac.bd";
      } else if (role == UserRole.driver) {
        _emailController.text = "driver@duet.ac.bd";
      }
    });
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final inputEmail = _emailController.text.trim().toLowerCase();
      final effectiveRole = (inputEmail == "admin@duet.ac.bd" || inputEmail.contains("admin"))
          ? UserRole.admin
          : _selectedRole;

      AuthResponse response = await AuthService.login(
        _emailController.text,
        _passwordController.text,
        effectiveRole,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (response.status == AuthStatus.success) {
        Widget destination;
        if (effectiveRole == UserRole.admin) {
          destination = const AdminScreen();
        } else if (effectiveRole == UserRole.driver) {
          destination = const DriverScreen();
        } else {
          destination = const MainScreen();
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      } else if (response.status == AuthStatus.pendingApproval) {
        _showStatusDialog(
          title: "Approval Pending",
          message: response.message ?? "Your driver account is pending Admin approval.",
          icon: Icons.hourglass_empty,
          color: Colors.orange,
        );
      } else if (response.status == AuthStatus.rejected) {
        _showStatusDialog(
          title: "Request Rejected",
          message: response.message ?? "Your driver application was not approved by Admin.",
          icon: Icons.cancel_outlined,
          color: Colors.red,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? "Invalid credentials. Please try again.")),
        );
      }
    }
  }

  void _showStatusDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // Logo & Header (Hidden or smaller in small heights)
                    if (MediaQuery.of(context).size.height > 500)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD6E3FF),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Icon(
                            Icons.directions_bus,
                            size: 50,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    const Center(
                      child: Text(
                        "DUET Smart Bus Tracker",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF191C21),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        _getRoleSubtitle(),
                        style: const TextStyle(color: Color(0xFF424752), fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      "Select Login Role",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECEDF6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          _buildRoleTab(UserRole.student, "Student", Icons.school),
                          _buildRoleTab(UserRole.driver, "Driver", Icons.drive_eta),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text("Email Address", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: "Enter your university email",
                        prefixIcon: const Icon(Icons.email_outlined),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFE1E2EA)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFE1E2EA)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty || !value.contains('@')) {
                          return "Please enter a valid email address";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text("Password", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: "Enter your password",
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFE1E2EA)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFE1E2EA)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty || value.length < 8) {
                          return "Password must be at least 8 characters";
                        }
                        return null;
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text("Forgot Password?"),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getRoleColor(),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                "Login as ${_getRoleName()}",
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_selectedRole == UserRole.driver
                            ? "Want to become a driver?"
                            : "Don't have an account?"),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SignupScreen(initialRole: _selectedRole),
                              ),
                            );
                          },
                          child: Text(
                            _selectedRole == UserRole.driver ? "Apply as Driver" : "Sign Up",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Admin Web Portal: https://admin.duet.ac.bd (Open on Desktop Browser)"),
                              duration: Duration(seconds: 4),
                            ),
                          );
                        },
                        icon: const Icon(Icons.language, size: 14, color: Color(0xFF727783)),
                        label: const Text(
                          "Admin Web Portal ↗ (Desktop Browser)",
                          style: TextStyle(fontSize: 11, color: Color(0xFF727783)),
                        ),
                      ),
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

  Widget _buildRoleTab(UserRole role, String title, IconData icon) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: InkWell(
        onTap: () => _onRoleChanged(role),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? _getRoleColorFor(role) : const Color(0xFF727783),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                  color: isSelected ? _getRoleColorFor(role) : const Color(0xFF727783),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRoleName() {
    if (_selectedRole == UserRole.driver) {
      return "Driver";
    }
    return "Student";
  }

  String _getRoleSubtitle() {
    if (_selectedRole == UserRole.driver) {
      return "Driver Portal • Broadcast bus location & shift updates";
    }
    return "Student Portal • Track campus shuttles in real-time";
  }

  Color _getRoleColor() {
    return _getRoleColorFor(_selectedRole);
  }

  Color _getRoleColorFor(UserRole role) {
    if (role == UserRole.driver) {
      return Colors.green[700]!;
    }
    return const Color(0xFF1565C0);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
