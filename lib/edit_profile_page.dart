import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/custom_button.dart';
import 'widgets/custom_input_field.dart';
import 'models/student.dart' as student_model;

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers for form fields
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  late TextEditingController _addressController;
  late TextEditingController _programController;
  late TextEditingController _yearController;
  late TextEditingController _semesterController;

  // Dropdown values
  String _selectedGender = 'Male';

  // Loading state
  bool _isLoading = false;
  student_model.Student? _currentStudent;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    try {
      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Build a minimal student profile from FirebaseAuth without any dummy data
      final now = DateTime.now();
      final minimalStudent = student_model.Student(
        id: user.uid,
        name: user.displayName ?? (user.email?.split('@').first ?? 'Student'),
        email: user.email ?? '',
        studentId: '',
        phone: '',
        dateOfBirth: '',
        gender: 'Male',
        address: '',
        program: '',
        year: '',
        semester: '',
        cgpa: 0.0,
        creditsCompleted: 0,
        totalCredits: 0,
        expectedGraduation: '',
        createdAt: now,
        updatedAt: now,
      );

      setState(() {
        _currentStudent = minimalStudent;
        // Initialize controllers with current data
        _nameController = TextEditingController(text: minimalStudent.name);
        _phoneController = TextEditingController(text: minimalStudent.phone);
        _dobController = TextEditingController(
          text: minimalStudent.dateOfBirth,
        );
        _addressController = TextEditingController(
          text: minimalStudent.address,
        );
        _programController = TextEditingController(
          text: minimalStudent.program,
        );
        _yearController = TextEditingController(text: minimalStudent.year);
        _semesterController = TextEditingController(
          text: minimalStudent.semester,
        );
        _selectedGender = minimalStudent.gender;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading student data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    if (_currentStudent != null) {
      _nameController.dispose();
      _phoneController.dispose();
      _dobController.dispose();
      _addressController.dispose();
      _programController.dispose();
      _yearController.dispose();
      _semesterController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _currentStudent == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Edit Profile',
            style: TextStyle(
              color: Colors.black87,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.black87,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isLoading ? Colors.grey : const Color(0xFF6366F1),
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Picture Section
              _buildProfilePictureSection(),

              // Personal Information Form
              _buildPersonalInformationForm(),

              // Action Buttons
              _buildActionButtons(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Picture with edit overlay
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                  border: Border.all(color: const Color(0xFF6366F1), width: 3),
                ),
                child: const Icon(
                  Icons.person,
                  size: 60,
                  color: Color(0xFF6366F1),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _changeProfilePicture,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF6366F1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Tap camera icon to change photo',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInformationForm() {
    return Container(
      margin: const EdgeInsets.all(20.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 20),

          // Full Name
          CustomInputField(
            controller: _nameController,
            labelText: 'Full Name',
            prefixIcon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your full name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Program
          CustomInputField(
            controller: _programController,
            labelText: 'Program',
            prefixIcon: Icons.school_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your program';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Phone Number
          CustomInputField(
            controller: _phoneController,
            labelText: 'Phone Number',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Date of Birth
          CustomInputField(
            controller: _dobController,
            labelText: 'Date of Birth',
            prefixIcon: Icons.calendar_today_outlined,
            readOnly: true,
            onTap: () => _selectDate(context),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select your date of birth';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Gender Dropdown
          _buildGenderDropdown(),
          const SizedBox(height: 16),

          // Address
          CustomInputField(
            controller: _addressController,
            labelText: 'Address',
            prefixIcon: Icons.location_on_outlined,
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Year
          CustomInputField(
            controller: _yearController,
            labelText: 'Year',
            prefixIcon: Icons.school_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your year';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Semester
          CustomInputField(
            controller: _semesterController,
            labelText: 'Semester',
            prefixIcon: Icons.calendar_today_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your semester';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[50],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedGender,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
              items: ['Male', 'Female', 'Other'].map((String gender) {
                return DropdownMenuItem<String>(
                  value: gender,
                  child: Text(
                    gender,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedGender = newValue;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          CustomButton(
            text: _isLoading ? 'Saving...' : 'Save Changes',
            onPressed: () => _saveProfile(),
            backgroundColor: const Color(0xFF6366F1),
            textColor: Colors.white,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: 'Cancel',
            onPressed: () => Navigator.pop(context),
            backgroundColor: Colors.grey[200]!,
            textColor: Colors.black87,
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2002, 3, 15), // Default date
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF6366F1)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dobController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  void _changeProfilePicture() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Change Profile Picture',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPhotoOption(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Camera feature coming soon!'),
                          ),
                        );
                      },
                    ),
                    _buildPhotoOption(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Gallery feature coming soon!'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: const Color(0xFF6366F1)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _currentStudent == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Update student data
      final updatedStudent = _currentStudent!.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        dateOfBirth: _dobController.text.trim(),
        address: _addressController.text.trim(),
        gender: _selectedGender,
        program: _programController.text.trim(),
        year: _yearController.text.trim(),
        semester: _semesterController.text.trim(),
      );

      // No Firestore persistence here; just update local state
      _currentStudent = updatedStudent;

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to profile page
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
