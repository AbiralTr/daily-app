import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';

/// The single, app-wide database instance. Closed automatically when the
/// provider is disposed (which, for this provider, only happens on app exit).
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
