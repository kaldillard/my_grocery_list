import 'package:flutter/material.dart';
import 'package:my_grocery_list/services/supabase_service.dart';
import 'app.dart';
import 'services/storage_service.dart';
import 'repositories/grocery_repository.dart';
import 'repositories/family_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  final supabaseService = await SupabaseService.initialize(
    supabaseUrl: 'https://spgxvhfotvfyjpuciuee.supabase.co',
    supabaseAnonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNwZ3h2aGZvdHZmeWpwdWNpdWVlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI4NTc4ODMsImV4cCI6MjA3ODQzMzg4M30.oaNLgMACmsSW5hJLJ2zOslaksNTuSV1pztXk_JyYf0Y',
  );

  runApp(MyApp(supabaseService: supabaseService));
}
