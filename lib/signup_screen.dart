import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:duet_smart_bus_tracker/models/user_model.dart';
import 'package:duet_smart_bus_tracker/services/auth_service.dart';
import 'package:duet_smart_bus_tracker/login_screen.dart';

class SignupScreen extends StatefulWidget {
  final UserRole initialRole;

  const SignupScreen({super.key, this.initialRole = UserRole.student});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController(); // Username
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  // Student Specific
  final _studentIdController = TextEditingController();
  
  // Driver Specific
  final _licensePlateController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  late UserRole _selectedRole;
  String _selectedBus = "Bus 402";
  String _selectedDepartment = "CSE (Computer Science)";
  String _selectedSemester = "32";
  String _selectedGender = "Male";
  DateTime? _selectedDob;
  DateTime? _selectedLicenseExpiry;

  bool _isLoading = false;
  bool _obscurePassword = true;

  final List<String> _buses = ["Bus 402", "Bus 405", "Bus 410", "Bus 412"];
  
  final List<String> _departments = [
    "CSE (Computer Science)",
    "EEE (Electrical)",
    "ME (Mechanical)",
    "CE (Civil)",
    "TE (Textile)",
    "Arch (Architecture)",
    "CHE (Chemical)",
  ];

  final List<String> _semesters = ["11", "12", "21", "22", "31", "32", "41", "42"];
  final List<String> _genders = ["Male", "Female", "Other"];

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
  }

  void _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDob == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select Date of Birth")));
        return;
      }
      if (_selectedRole == UserRole.driver && _selectedLicenseExpiry == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select License Expiry Date")));
        return;
      }

      setState(() => _isLoading = true);

      AuthResponse response = await AuthService.registerUser(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        role: _selectedRole,
        fullName: _fullNameController.text,
        phone: _phoneController.text,
        dob: DateFormat('yyyy-MM-dd').format(_selectedDob!),
        gender: _selectedGender,
        address: _addressController.text,
        studentId: _selectedRole == UserRole.student ? _studentIdController.text : null,
        semester: _selectedRole == UserRole.student ? _selectedSemester : null,
        licenseNumber: _selectedRole == UserRole.driver ? _licensePlateController.text : null,
        licenseExpiry: (_selectedRole == UserRole.driver && _selectedLicenseExpiry != null) 
            ? DateFormat('yyyy-MM-dd').format(_selectedLicenseExpiry!) 
            : null,
        emergencyContactName: _selectedRole == UserRole.driver ? _emergencyNameController.text : null,
        emergencyContactPhone: _selectedRole == UserRole.driver ? _emergencyPhoneController.text : null,
        preferredBus: _selectedRole == UserRole.driver ? _selectedBus : null,
        department: _selectedRole == UserRole.student ? _selectedDepartment.split(' ')[0] : null,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (response.status == AuthStatus.pendingApproval) {
        _showSuccessDialog(response.message);
      } else if (response.status == AuthStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.message ?? "Registration successful. Please log in.",
            ),
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => LoginScreen(),
          ),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? "Registration failed. Please try again.")),
        );
      }
    }
  }

  void _showSuccessDialog(String? message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green),
            SizedBox(width: 8),
            Text("Request Submitted"),
          ],
        ),
        content: Text(message ?? "Registration submitted. Waiting for approval."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Back to Login", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isDob) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1960),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isDob) {
          _selectedDob = picked;
        } else {
          _selectedLicenseExpiry = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF191C21)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildRoleSelector(),
                const SizedBox(height: 32),
                
                _buildSectionTitle("Account Credentials"),
                _buildTextField("Username", _nameController, Icons.alternate_email, "e.g. delowar"),
                _buildTextField("Email Address", _emailController, Icons.email_outlined, "university email", isEmail: true),
                _buildTextField("Password", _passwordController, Icons.lock_outline, "min 8 characters & 1 letter", isPassword: true),
                _buildTextField("Confirm Password", _confirmPasswordController, Icons.lock_reset_outlined, "repeat password", isConfirmPassword: true),
                
                const SizedBox(height: 24),
                _buildSectionTitle("Personal Details"),
                _buildTextField("Full Name", _fullNameController, Icons.person_outline, "e.g. Delowar Hossain"),
                _buildDatePicker("Date of Birth", _selectedDob, true),
                _buildGenderDropdown(),
                _buildTextField("Mobile Number", _phoneController, Icons.phone_outlined, "e.g. 01738976919", isPhone: true),
                _buildTextField("Address", _addressController, Icons.location_on_outlined, "e.g. Duet, Gazipur"),
                
                if (_selectedRole == UserRole.student) ...[
                  const SizedBox(height: 24),
                  _buildSectionTitle("Academic Information"),
                  _buildTextField("Student ID", _studentIdController, Icons.badge_outlined, "e.g. 2204084"),
                  _buildDepartmentDropdown(),
                  _buildSemesterDropdown(),
                ],
                
                if (_selectedRole == UserRole.driver) ...[
                  const SizedBox(height: 24),
                  _buildSectionTitle("Vehicle & Emergency"),
                  _buildTextField("License Plate", _licensePlateController, Icons.directions_bus_outlined, "e.g. 1234"),
                  _buildDatePicker("License Expiry Date", _selectedLicenseExpiry, false),
                  _buildBusDropdown(),
                  const SizedBox(height: 16),
                  _buildTextField("Emergency Contact Name", _emergencyNameController, Icons.contact_emergency_outlined, "e.g. Abul Kashem"),
                  _buildTextField("Emergency Contact Phone", _emergencyPhoneController, Icons.phone_android_outlined, "e.g. 01769276219", isPhone: true),
                ],
                
                const SizedBox(height: 40),
                _buildSubmitButton(),
                const SizedBox(height: 20),
                _buildLoginLink(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String title = "Create Account";
    String subtitle = "Join the DUET Smart Bus community";
    if (_selectedRole == UserRole.driver) {
      title = "Driver Application";
      subtitle = "Join the transport team at DUET";
    } else if (_selectedRole == UserRole.admin) {
      title = "Admin Registration";
      subtitle = "Create an Admin account for Campus Portal";
    }

    return Column(
      children: [
        Center(
          child: Text(
            title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF191C21)),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF424752)),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Row(
        children: [
          Container(width: 4, height: 16, color: _selectedRole == UserRole.driver ? Colors.green : const Color(0xFF1565C0)),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.bold, 
              color: Colors.grey[700],
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFECEDF6), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          _buildRoleOption(UserRole.student, "Student", Icons.school),
          _buildRoleOption(UserRole.driver, "Driver", Icons.drive_eta),
          if (kIsWeb || widget.initialRole == UserRole.admin)
            _buildRoleOption(UserRole.admin, "Admin", Icons.admin_panel_settings),
        ],
      ),
    );
  }

  Widget _buildRoleOption(UserRole role, String label, IconData icon) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedRole = role),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? (role == UserRole.driver ? Colors.green[700] : const Color(0xFF1565C0)) : const Color(0xFF727783)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                  color: isSelected ? (role == UserRole.driver ? Colors.green[700] : const Color(0xFF1565C0)) : const Color(0xFF727783),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, String hint, {bool isPassword = false, bool isEmail = false, bool isPhone = false, bool isConfirmPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            obscureText: isPassword && _obscurePassword,
            keyboardType: isEmail ? TextInputType.emailAddress : (isPhone ? TextInputType.phone : TextInputType.text),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, size: 20),
              suffixIcon: isPassword ? IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ) : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE1E2EA))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE1E2EA))),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return "This field is required";
              if (isEmail && !value.contains('@')) return "Enter a valid email";
              if (isPassword) {
                if (value.length < 8) return "Password must be at least 8 characters";
                if (!RegExp(r'[A-Za-z]').hasMatch(value)) return "Must contain at least one letter";
              }
              if (isConfirmPassword && value != _passwordController.text) return "Passwords do not match";
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime? selectedDate, bool isDob) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _selectDate(context, isDob),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE1E2EA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 20, color: Colors.grey),
                  const SizedBox(width: 12),
                  Text(
                    selectedDate == null ? "Select Date" : DateFormat('yyyy-MM-dd').format(selectedDate),
                    style: TextStyle(color: selectedDate == null ? Colors.grey : Colors.black),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return _buildDropdown("Gender", _selectedGender, _genders, (val) => setState(() => _selectedGender = val!));
  }

  Widget _buildDepartmentDropdown() {
    return _buildDropdown("Department", _selectedDepartment, _departments, (val) => setState(() => _selectedDepartment = val!));
  }

  Widget _buildSemesterDropdown() {
    return _buildDropdown("Current Semester", _selectedSemester, _semesters, (val) => setState(() => _selectedSemester = val!));
  }

  Widget _buildBusDropdown() {
    return _buildDropdown("Assigned Bus", _selectedBus, _buses, (val) => setState(() => _selectedBus = val!));
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE1E2EA))),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                onChanged: onChanged,
                items: items.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignup,
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedRole == UserRole.driver ? Colors.green[700] : const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                _selectedRole == UserRole.driver ? "Submit Driver Request" : "Sign Up",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Already have an account?"),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Login", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _studentIdController.dispose();
    _licensePlateController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }
}
