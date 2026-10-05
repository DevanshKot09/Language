import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';
import 'app/providers/theme_provider.dart';
import 'app/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  // Initialize native GoogleSignIn singleton exactly once before authentication
  if (!kIsWeb) {
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: '960393036210-a66svqibar5a4p1nn0vhm8k982oomh1b.apps.googleusercontent.com',
      );
    } catch (e) {
      debugPrint('GoogleSignIn initialization notice: $e');
    }
  }

  runApp(const LinguaApp());
}

class LinguaApp extends StatelessWidget {
  const LinguaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(
      child: _LinguaAppContent(),
    );
  }
}


class _LinguaAppContent extends ConsumerWidget {
  const _LinguaAppContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = ref.watch(themeDataProvider);

    return MaterialApp(
      title: 'LINGUA AI',
      debugShowCheckedModeBanner: false,
      theme: themeData,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
