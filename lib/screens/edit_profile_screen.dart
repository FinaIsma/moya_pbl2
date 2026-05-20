import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final Color darkTeal = const Color(0xFF2C535D);
  final Color lightGrey = const Color(0xFFEDEDED);
  final Color successGreen = const Color(0xFF55AC68);
  final Color softPink = const Color(0xFFFDE8EF); 

  final _fullNameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _dobController = TextEditingController();
  String? _selectedGender;
  DateTime? _selectedDate;

  XFile? _pickedFile;
  bool _isLoading = false;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _fullNameController.text = doc['fullName'] ?? doc['name'] ?? '';
          _nicknameController.text = doc['name'] ?? doc['name'] ?? '';
          _dobController.text = doc['dob'] ?? '';
          _selectedGender = doc['gender'];
          _currentImageUrl = doc['profileImage'];
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _pickedFile = picked);
    }
  }

  Future<String?> _uploadToCloudinary() async {
    if (_pickedFile == null) return _currentImageUrl;

    try {
      
      String cloudName = "drkxaqn7z"; 
      String uploadPreset = "mooya_preset";

      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset;

      if (kIsWeb) {
        final bytes = await _pickedFile!.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: 'profile.jpg'));
      } else {
        request.files.add(await http.MultipartFile.fromPath('file', _pickedFile!.path));
      }

      final response = await request.send();
      if (response.statusCode == 200) {
        final res = await http.Response.fromStream(response);
        return jsonDecode(res.body)['secure_url'];
      }
    } catch (e) {
      print("Error Upload: $e");
    }
    return _currentImageUrl;
  }

  Future<void> _saveProfile() async {
    if (_fullNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nama tidak boleh kosong")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String? imageUrl = await _uploadToCloudinary();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fullName': _fullNameController.text,
        'name': _nicknameController.text,
        'dob': _dobController.text,
        'gender': _selectedGender ?? '',
        'profileImage': imageUrl,
      }, SetOptions(merge: true));

      Navigator.pop(context);
    } catch (e) {
      print("Error Save: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(color: softPink, shape: BoxShape.circle),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Text('Edit Profile', 
                          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: darkTeal)),
                      ],
                    ),
                    const SizedBox(height: 30),
                    
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.blue.withOpacity(0.2),
                            backgroundImage: _pickedFile != null 
                              ? (kIsWeb ? NetworkImage(_pickedFile!.path) : FileImage(File(_pickedFile!.path)) as ImageProvider)
                              : (_currentImageUrl != null ? NetworkImage(_currentImageUrl!) : null),
                            child: (_pickedFile == null && _currentImageUrl == null)
                                ? const Icon(Icons.person, size: 50, color: Colors.white) : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(color: Color(0xFF2D474E), shape: BoxShape.circle),
                                child: const Icon(Icons.edit, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    // INPUT FIELDS
                    _buildField("Full Name", _fullNameController),
                    _buildField("Name", _nicknameController),
                    _buildDateField(),
                    _buildGenderDropdown(),
                  ],
                ),
              ),
            ),
            // TOMBOL SAVE DI BAWAH
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: successGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Save Edit', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(label, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
          ),
          TextField(
            controller: controller,
            style: GoogleFonts.poppins(fontSize: 15),
            decoration: InputDecoration(
              filled: true,
              fillColor: lightGrey, 
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
  // Date picker field
  Widget _buildDateField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Date of Birth', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
          ),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: lightGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _dobController.text.isEmpty ? 'Select date' : _dobController.text,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: _dobController.text.isEmpty ? Colors.grey : Colors.black,
                    ),
                  ),
                  Icon(Icons.calendar_today_outlined, size: 18, color: darkTeal),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Gender dropdown
  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Gender', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
          ),
          DropdownButtonFormField<String>(
            value: _selectedGender,
            hint: Text('Select gender', style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey)),
            decoration: InputDecoration(
              filled: true,
              fillColor: lightGrey,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            style: GoogleFonts.poppins(fontSize: 15, color: Colors.black),
            dropdownColor: Colors.white,
            icon: Icon(Icons.keyboard_arrow_down, color: darkTeal),
            items: ['Male', 'Female', 'Prefer not to say']
                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                .toList(),
            onChanged: (val) => setState(() => _selectedGender = val),
          ),
        ],
      ),
    );
  }

  // Date picker logic
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: darkTeal),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dobController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }
}