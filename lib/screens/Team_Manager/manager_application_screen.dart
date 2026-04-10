import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/core/api/team_api.dart';
import 'package:arena_chain_flutter/core/api/team_manager_api.dart'; // Make sure this exists and has createProfile
import 'package:arena_chain_flutter/core/models/team_model.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class ManagerApplicationScreen extends StatefulWidget {
  const ManagerApplicationScreen({super.key});

  @override
  State<ManagerApplicationScreen> createState() => _ManagerApplicationScreenState();
}

class _ManagerApplicationScreenState extends State<ManagerApplicationScreen> {
<<<<<<< HEAD
=======
  static const Color _background = Color(0xFF000000);
  static const Color _surface = Color(0xFF1A1C23);
  static const Color _neon = Color(0xFF39FF14);

>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
  final _formKey = GlobalKey<FormState>();
  final _teamApi = TeamApi();
  final _managerApi = TeamManagerApi();
  
  String? _selectedTeamId;
  final _orgNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _cinController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descController = TextEditingController();
  String _gender = 'Male';

  List<Team> _teams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    try {
      final teams = await _teamApi.getTeams();
      setState(() {
        _teams = teams;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading teams: $e')),
        );
      }
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate() || _selectedTeamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields and select a team')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'teamId': _selectedTeamId,
        'organizationName': _orgNameController.text,
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'cin': _cinController.text,
        'age': int.tryParse(_ageController.text) ?? 0,
        'gender': _gender,
        'description': _descController.text,
        'phoneNumber': _phoneController.text,
      };

      await _managerApi.createProfile(data);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted successfully! Waiting for admin approval.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting application: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< HEAD
      appBar: AppBar(
        title: const Text('Apply as Team Manager'),
        backgroundColor: const Color(0xFF1A1A2E),
      ),
      body: _isLoading && _teams.isEmpty
          ? const Center(child: CircularProgressIndicator())
=======
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'Apply as Team Manager',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: _background,
        elevation: 0,
        foregroundColor: _neon,
        iconTheme: IconThemeData(color: _neon.withValues(alpha: 0.92)),
      ),
      body: _isLoading && _teams.isEmpty
          ? Center(child: CircularProgressIndicator(color: _neon.withValues(alpha: 0.85)))
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
<<<<<<< HEAD
                    const Text(
                      'Managerial Application',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Provide your professional details to establish or manage an official team.',
                      style: TextStyle(color: Colors.grey),
=======
                    Text(
                      'Managerial Application',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: _neon.withValues(alpha: 0.22), blurRadius: 10),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Provide your professional details to establish or manage an official team.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.52),
                        fontSize: 14,
                        height: 1.35,
                      ),
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
                    ),
                    const SizedBox(height: 30),
                    
                    DropdownButtonFormField<String>(
<<<<<<< HEAD
                      dropdownColor: const Color(0xFF16213E),
=======
                      dropdownColor: _surface,
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
                      decoration: _inputDecoration('Target Team Selection *'),
                      value: _selectedTeamId,
                      items: _teams.map((team) {
                        return DropdownMenuItem(
                          value: team.id,
                          child: Text(team.name, style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedTeamId = val),
                      validator: (val) => val == null ? 'Please select a team' : null,
                    ),
                    const SizedBox(height: 20),
                    
                    TextFormField(
                      controller: _orgNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Organization Name'),
                    ),
                    const SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('First Name *'),
                            validator: (val) => val!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Last Name *'),
                            validator: (val) => val!.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    TextFormField(
                      controller: _cinController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Identity Card Number (CIN) *'),
                      validator: (val) => val!.isEmpty ? 'Required for verification' : null,
                    ),
                    const SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Age *'),
                            validator: (val) => val!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: DropdownButtonFormField<String>(
<<<<<<< HEAD
                            dropdownColor: const Color(0xFF16213E),
=======
                            dropdownColor: _surface,
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
                            decoration: _inputDecoration('Gender'),
                            value: _gender,
                            items: ['Male', 'Female', 'Other'].map((g) {
                              return DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(color: Colors.white)));
                            }).toList(),
                            onChanged: (val) => setState(() => _gender = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Phone Number *'),
                    ),
                    const SizedBox(height: 30),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 55,
<<<<<<< HEAD
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitApplication,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE94560),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Submit Application', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
=======
                      child: FilledButton(
                        onPressed: _isLoading ? null : _submitApplication,
                        style: FilledButton.styleFrom(
                          backgroundColor: _neon,
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: _neon.withValues(alpha: 0.35),
                          disabledForegroundColor: Colors.black.withValues(alpha: 0.45),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                          shadowColor: _neon.withValues(alpha: 0.35),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.black,
                                ),
                              )
                            : const Text(
                                'Submit Application',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                              ),
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
                      ),
                    ),
                  ],
                ),
              ),
            ),
<<<<<<< HEAD
      backgroundColor: const Color(0xFF1A1A2E),
=======
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
    );
  }

  InputDecoration _inputDecoration(String label) {
<<<<<<< HEAD
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFF16213E),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE94560))),
=======
    final neonSoft = BorderSide(color: _neon.withValues(alpha: 0.32));
    final neonFocus = BorderSide(color: _neon.withValues(alpha: 0.85), width: 1.5);
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
      floatingLabelStyle: TextStyle(
        color: _neon.withValues(alpha: 0.88),
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: _surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: neonSoft,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: neonSoft,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: neonFocus,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400.withValues(alpha: 0.85)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
      ),
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
    );
  }
}
