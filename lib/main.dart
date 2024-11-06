import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'widgets/game_page.dart';

void main() async {
  await Supabase.initialize(
    url: 'https://nniqcvicztcvudlgxovx.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5uaXFjdmljenRjdnVkbGd4b3Z4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA4Njk1OTQsImV4cCI6MjA0NjQ0NTU5NH0.FI7cdU_xasnXu_s01McwrDncjUpaT0gvDjOVmuhPi1o',
    realtimeClientOptions: const RealtimeClientOptions(eventsPerSecond: 40),
  );

  runApp(const AsteroidsFlameApp());
}

// Extract Supabase client for easy access to Supabase
final supabase = Supabase.instance.client;

class AsteroidsFlameApp extends StatelessWidget {
  const AsteroidsFlameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'UFO Shooting Game',
      debugShowCheckedModeBanner: false,
      home: GamePage(),
    );
  }
}
