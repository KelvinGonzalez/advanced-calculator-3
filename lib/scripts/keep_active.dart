import 'dart:io';

import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient(Platform.environment["SUPABASE_URL"]!,
      Platform.environment["SUPABASE_KEY"]!);

  await supabase.rpc("keep_active");
  print("Request sent");
}
