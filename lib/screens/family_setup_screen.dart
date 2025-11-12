// lib/screens/family_setup_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_grocery_list/blocs/auth/auth_event.dart';
import 'package:my_grocery_list/blocs/family_setup/family_setup_event.dart';
import 'package:my_grocery_list/blocs/family_setup/family_setup_state.dart';
import 'package:my_grocery_list/screens/auth_wrapper_screen.dart';
import 'package:my_grocery_list/utils/color_utils.dart';
import '../blocs/family_setup/family_setup_bloc.dart';
import '../blocs/auth/auth_bloc.dart';

class FamilySetupScreen extends StatefulWidget {
  final bool isCreatingNew;

  const FamilySetupScreen({super.key, this.isCreatingNew = true});

  @override
  State<FamilySetupScreen> createState() => _FamilySetupScreenState();
}

class _FamilySetupScreenState extends State<FamilySetupScreen> {
  late bool _isCreatingFamily;

  @override
  void initState() {
    super.initState();
    _isCreatingFamily = widget.isCreatingNew;
  }

  final _formKey = GlobalKey<FormState>();
  final _familyNameController = TextEditingController();
  final _memberNameController = TextEditingController();
  final _inviteCodeController = TextEditingController();

  @override
  void dispose() {
    _familyNameController.dispose();
    _memberNameController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final color = ColorUtils.getColorByIndex(0);

      if (_isCreatingFamily) {
        context.read<FamilySetupBloc>().add(
          CreateFamily(
            _familyNameController.text.trim(),
            _memberNameController.text.trim(),
            color,
          ),
        );
      } else {
        context.read<FamilySetupBloc>().add(
          JoinFamily(
            _inviteCodeController.text.trim().toUpperCase(),
            _memberNameController.text.trim(),
            color,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Setup'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(AuthSignOutRequested());
            },
          ),
        ],
      ),
      body: BlocConsumer<FamilySetupBloc, FamilySetupState>(
        listener: (context, state) {
          if (state is FamilySetupError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is FamilySetupSuccess) {
            // Show success dialog with invite code if created a family
            if (_isCreatingFamily) {
              _showSuccessDialog(context, state.inviteCode);
            } else {
              // Just show success message for joining
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Successfully joined family!'),
                  backgroundColor: Colors.green,
                ),
              );
              // Trigger auth check to reload the app
              context.read<AuthBloc>().add(AuthCheckRequested());
            }
          }
        },
        builder: (context, state) {
          final isLoading = state is FamilySetupLoading;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icon
                    Icon(
                      Icons.people,
                      size: 80,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Text(
                      'Set Up Your Family',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Create a new family or join an existing one',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Toggle Buttons
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: true,
                          label: Text('Create Family'),
                          icon: Icon(Icons.add),
                        ),
                        ButtonSegment(
                          value: false,
                          label: Text('Join Family'),
                          icon: Icon(Icons.group_add),
                        ),
                      ],
                      selected: {_isCreatingFamily},
                      onSelectionChanged:
                          isLoading
                              ? null
                              : (Set<bool> selection) {
                                setState(() {
                                  _isCreatingFamily = selection.first;
                                  _formKey.currentState?.reset();
                                });
                              },
                    ),
                    const SizedBox(height: 32),

                    // Conditional Fields
                    if (_isCreatingFamily) ...[
                      // Family Name Field
                      TextFormField(
                        controller: _familyNameController,
                        decoration: const InputDecoration(
                          labelText: 'Family Name',
                          hintText: 'e.g., Smith Family',
                          prefixIcon: Icon(Icons.home),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a family name';
                          }
                          return null;
                        },
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      // Invite Code Field
                      TextFormField(
                        controller: _inviteCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Invite Code',
                          hintText: 'ABC123',
                          prefixIcon: Icon(Icons.vpn_key),
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(6),
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[A-Z0-9]'),
                          ),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an invite code';
                          }
                          if (value.length != 6) {
                            return 'Invite code must be 6 characters';
                          }
                          return null;
                        },
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Your Name Field (common to both)
                    TextFormField(
                      controller: _memberNameController,
                      decoration: const InputDecoration(
                        labelText: 'Your Name',
                        hintText: 'e.g., John',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          isLoading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : Text(
                                _isCreatingFamily
                                    ? 'Create Family'
                                    : 'Join Family',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                    const SizedBox(height: 24),

                    // Info Card
                    Card(
                      color: Colors.blue[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue[700],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _isCreatingFamily
                                        ? 'About Creating a Family'
                                        : 'About Joining a Family',
                                    style: TextStyle(
                                      color: Colors.blue[900],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isCreatingFamily
                                  ? 'You\'ll receive a unique invite code that you can share with family members so they can join your grocery list.'
                                  : 'Ask a family member for their invite code to join their grocery list. You\'ll be able to view and edit items together.',
                              style: TextStyle(
                                color: Colors.blue[900],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String inviteCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.celebration, color: Colors.green),
                SizedBox(width: 8),
                Text('Family Created!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your family has been created successfully. Share this invite code with family members:',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        inviteCode,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: inviteCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Invite code copied to clipboard'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  // Navigate to fresh AuthWrapperScreen which will check for family
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const AuthWrapperScreen(),
                    ),
                    (route) => false,
                  );
                },
                child: const Text('Continue'),
              ),
            ],
          ),
    );
  }
}
