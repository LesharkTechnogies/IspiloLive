import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../core/services/user_service.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _oldPasswordCtrl = TextEditingController();
  final TextEditingController _newPasswordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();

  bool _showOldPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;

  void _toggleOldPassword() =>
      setState(() => _showOldPassword = !_showOldPassword);
  void _toggleNewPassword() =>
      setState(() => _showNewPassword = !_showNewPassword);
  void _toggleConfirmPassword() =>
      setState(() => _showConfirmPassword = !_showConfirmPassword);

  Future<void> _savePassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      await UserService.updatePassword(
        _oldPasswordCtrl.text,
        _newPasswordCtrl.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update password: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Old Password',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
              SizedBox(height: 1.h),
              TextFormField(
                controller: _oldPasswordCtrl,
                obscureText: !_showOldPassword,
                decoration: InputDecoration(
                  hintText: 'Enter old password',
                  suffixIcon: IconButton(
                    icon: Icon(_showOldPassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: _toggleOldPassword,
                  ),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter your old password'
                    : null,
              ),
              SizedBox(height: 2.h),
              Text('New Password',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
              SizedBox(height: 1.h),
              TextFormField(
                controller: _newPasswordCtrl,
                obscureText: !_showNewPassword,
                decoration: InputDecoration(
                  hintText: 'Enter new password',
                  suffixIcon: IconButton(
                    icon: Icon(_showNewPassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: _toggleNewPassword,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters long';
                  }
                  if (value == _oldPasswordCtrl.text) {
                    return 'New password must be different from old password';
                  }
                  return null;
                },
              ),
              SizedBox(height: 2.h),
              Text('Confirm Password',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
              SizedBox(height: 1.h),
              TextFormField(
                controller: _confirmPasswordCtrl,
                obscureText: !_showConfirmPassword,
                decoration: InputDecoration(
                  hintText: 'Confirm new password',
                  suffixIcon: IconButton(
                    icon: Icon(_showConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: _toggleConfirmPassword,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your new password';
                  }
                  if (value != _newPasswordCtrl.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              SizedBox(height: 4.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading 
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Save',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
