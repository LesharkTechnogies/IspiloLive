import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../model/repository/social_repository.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _description = '';
  bool _isPrivate = false;
  bool _isLoading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      final group = await PostRepository.createGroup(
        name: _name,
        description: _description,
        isPrivate: _isPrivate,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group created successfully!')),
      );
      Navigator.pop(context); // Go back
      
  
    } catch (e) {
      debugPrint('Error creating group: $e'); // Print to terminal
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create group. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appGreen = theme.brightness == Brightness.dark
        ? const Color(0xFF0E4D45)
        : const Color(0xFF075E54);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: appGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Create Group',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(5.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Group Name',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 1.h),
                    TextFormField(
                      decoration: const InputDecoration(
                        hintText: 'Enter group name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                      onSaved: (value) => _name = value?.trim() ?? '',
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      'Description',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 1.h),
                    TextFormField(
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'What is this group about?',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                      onSaved: (value) => _description = value?.trim() ?? '',
                    ),
                    SizedBox(height: 3.h),
                    SwitchListTile(
                      title: const Text('Private Group'),
                      subtitle: const Text('Only members can see posts and members.'),
                      value: _isPrivate,
                      onChanged: (val) => setState(() => _isPrivate = val),
                    ),
                    SizedBox(height: 5.h),
                    SizedBox(
                      width: double.infinity,
                      height: 6.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appGreen,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _submit,
                        child: Text(
                          'Create Group',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
