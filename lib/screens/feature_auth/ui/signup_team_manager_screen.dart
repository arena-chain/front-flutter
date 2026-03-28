import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/screens/feature_auth/viewmodel/auth_viewmodel.dart';
import 'package:arena_chain_flutter/core/models/feature_auth/auth_state.dart';
import 'package:arena_chain_flutter/navigation.dart';
import 'package:arena_chain_flutter/core/api/team_api.dart';
import 'package:arena_chain_flutter/core/models/team_model.dart';

class SignupTeamManagerScreen extends StatefulWidget {
  const SignupTeamManagerScreen({super.key});

  @override
  State<SignupTeamManagerScreen> createState() => _SignupTeamManagerScreenState();
}

class _SignupTeamManagerScreenState extends State<SignupTeamManagerScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Basic Info
  final _emailController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Profile Info
  final _organizationNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _cinController = TextEditingController();
  final _ageController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  
  String? _selectedGender;
  String? _selectedTeamId;
  List<Team> _teams = [];
  bool _isLoadingTeams = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _fetchTeams();
  }

  Future<void> _fetchTeams() async {
    setState(() => _isLoadingTeams = true);
    try {
      // Direct API call for simplicity, ideally should vary by ViewModel
      final teams = await TeamApi().getTeams();
      setState(() {
        _teams = teams;
        _isLoadingTeams = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load teams: $e')),
        );
        setState(() => _isLoadingTeams = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nicknameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _organizationNameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _cinController.dispose();
    _ageController.dispose();
    _descriptionController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _signup(AuthViewModel authViewModel) async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTeamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a team')),
      );
      return;
    }

    await authViewModel.registerTeamManager(
      email: _emailController.text.trim(),
      nickname: _nicknameController.text.trim(),
      password: _passwordController.text,
      organizationName: _organizationNameController.text.trim().isEmpty ? null : _organizationNameController.text.trim(),
      firstName: _firstNameController.text.trim().isEmpty ? null : _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim().isEmpty ? null : _lastNameController.text.trim(),
      cin: _cinController.text.trim().isEmpty ? null : _cinController.text.trim(),
      age: int.tryParse(_ageController.text.trim()),
      gender: _selectedGender,
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      phoneNumber: _phoneNumberController.text.trim().isEmpty ? null : _phoneNumberController.text.trim(),
      requestTeamId: _selectedTeamId,
    );

    if (mounted && authViewModel.authState == AuthState.authenticated) {
      // Show success dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1F36),
            title: const Text('Registration Successful', style: TextStyle(color: Colors.white)),
            content: const Text(
              'Your account is pending approval.\nYou will be notified once an admin approves your request.',
              style: TextStyle(color: Color(0xFF7A86AC)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF0F0C08),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: const Text('Team Manager Signup'),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (authViewModel.errorMessage != null)
                      Text(authViewModel.errorMessage!, style: const TextStyle(color: Colors.red)),
                    
                    // Basic Info Section
                    _buildSectionTitle('Account Info'),
                    _buildTextField(_emailController, 'Email', Icons.email, validator: (v) => v!.contains('@') ? null : 'Invalid email'),
                    _buildTextField(_nicknameController, 'Nickname', Icons.person, validator: (v) => v!.length < 3 ? 'Min 3 chars' : null),
                    _buildPasswordField(),
                    _buildConfirmPasswordField(),

                    const SizedBox(height: 24),
                    _buildSectionTitle('Personal Info'),
                    _buildTextField(_firstNameController, 'First Name', Icons.badge),
                    _buildTextField(_lastNameController, 'Last Name', Icons.badge),
                    _buildTextField(_cinController, 'CIN', Icons.perm_identity),
                    _buildTextField(_ageController, 'Age', Icons.calendar_today, keyboardType: TextInputType.number),
                    _buildGenderDropdown(),
                    _buildTextField(_phoneNumberController, 'Phone Number', Icons.phone, keyboardType: TextInputType.phone),

                    const SizedBox(height: 24),
                    _buildSectionTitle('Team Info'),
                    _buildTextField(_organizationNameController, 'Organization Name (Optional)', Icons.business),
                    _buildTextField(_descriptionController, 'Description', Icons.description, maxLines: 3),
                    const SizedBox(height: 16),
                    _buildTeamDropdown(),

                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: authViewModel.isLoading ? null : () => _signup(authViewModel),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00FF00),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: authViewModel.isLoading 
                        ? const CircularProgressIndicator()
                        : const Text('Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType, String? Function(String?)? validator, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF7A86AC)),
          prefixIcon: Icon(icon, color: const Color(0xFF7A86AC)),
          filled: true,
          fillColor: const Color(0xFF1A1F36),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildPasswordField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: 'Password',
          labelStyle: const TextStyle(color: Color(0xFF7A86AC)),
          prefixIcon: const Icon(Icons.lock, color: Color(0xFF7A86AC)),
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: const Color(0xFF7A86AC)),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          filled: true,
          fillColor: const Color(0xFF1A1F36),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (v) => v!.length < 6 ? 'Min 6 chars' : null,
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _confirmPasswordController,
        obscureText: _obscurePassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: 'Confirm Password',
          labelStyle: const TextStyle(color: Color(0xFF7A86AC)),
           prefixIcon: const Icon(Icons.lock, color: Color(0xFF7A86AC)),
          filled: true,
          fillColor: const Color(0xFF1A1F36),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (v) => v != _passwordController.text ? 'Passwords do not match' : null,
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        dropdownColor: const Color(0xFF1A1F36),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: 'Gender',
          labelStyle: const TextStyle(color: Color(0xFF7A86AC)),
          prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF7A86AC)),
          filled: true,
          fillColor: const Color(0xFF1A1F36),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
        onChanged: (v) => setState(() => _selectedGender = v),
      ),
    );
  }

  Widget _buildTeamDropdown() {
    return _isLoadingTeams 
      ? const Center(child: CircularProgressIndicator())
      : DropdownButtonFormField<String>(
          value: _selectedTeamId,
          dropdownColor: const Color(0xFF1A1F36),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Request to Join Team',
            labelStyle: const TextStyle(color: Color(0xFF7A86AC)),
            prefixIcon: const Icon(Icons.group, color: Color(0xFF7A86AC)),
            filled: true,
            fillColor: const Color(0xFF1A1F36),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: _teams.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
          onChanged: (v) => setState(() => _selectedTeamId = v),
          validator: (v) => v == null ? 'Please select a team' : null,
        );
  }
}
