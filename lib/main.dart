import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:my_grocery_list/blocs/family/family_bloc.dart';
import 'package:my_grocery_list/blocs/family/family_event.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_bloc.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_event.dart';
import 'package:my_grocery_list/screens/grocery_list_screen.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => GroceryBloc()..add(LoadGroceryData()),
        ),
        BlocProvider(create: (context) => FamilyBloc()..add(LoadFamilyData())),
      ],
      child: MaterialApp(
        title: 'Family Grocery List',
        theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
        home: const GroceryListScreen(),
      ),
    );
  }
}
