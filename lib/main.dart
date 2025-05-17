import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:recipe_cart/screens/profile/dietary_preferences_screen.dart';
import 'package:recipe_cart/screens/profile/edit_profile_screen.dart';
import 'package:recipe_cart/services/user_service.dart';
import 'package:recipe_cart/settings/app_settings_screen.dart';
import 'package:recipe_cart/settings/notification_settings_screen.dart';
import 'package:recipe_cart/about/about_screen.dart';
import 'package:recipe_cart/help/help_center_screen.dart';
import 'package:recipe_cart/services/theme_service.dart';
import 'package:recipe_cart/services/favorite_service.dart';
import 'package:recipe_cart/screens/favorites/favorites_screen.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:recipe_cart/services/auth_service.dart';
import 'package:recipe_cart/screens/wrapper.dart';
import 'package:recipe_cart/models/user_model.dart';
import 'package:recipe_cart/services/recipe_service.dart';
import 'package:recipe_cart/services/shopping_list_service.dart';
import 'package:recipe_cart/services/meal_plan_service.dart';
import 'package:recipe_cart/theme/app_theme.dart';
import 'package:recipe_cart/services/database_initializer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Firebase Realtime Database
  FirebaseDatabase database = FirebaseDatabase.instance;

  // Optional: Enable persistence for offline capabilities
  database.setPersistenceEnabled(true);

  // Optional: Keep synced data for specific paths (for faster access)
  database.ref('recipes').keepSynced(true);

  final databaseInitializer = DatabaseInitializer();
  await databaseInitializer.initializeDatabase();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Add ThemeService as ChangeNotifierProvider
        ChangeNotifierProvider(create: (_) => ThemeService()),
        StreamProvider<UserModel?>.value(
          value: AuthService().user,
          initialData: null,
        ),
        Provider<RecipeService>(
          create: (_) => RecipeService(),
        ),
        Provider<ShoppingListService>(
          create: (_) => ShoppingListService(),
        ),
        Provider<MealPlanService>(
          create: (_) => MealPlanService(),
        ),
        Provider<UserService>(
          create: (_) => UserService(),
        ),
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<FavoriteService>(
          create: (_) => FavoriteService(),
        ),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'Recipe Cart',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeService.themeMode,  // Use ThemeService instead of ThemeMode.system
            home: const Wrapper(),
            routes: {
              '/edit_profile': (context) => const EditProfileScreen(),
              '/dietary_preferences': (context) => const DietaryPreferencesScreen(),
              '/settings': (context) => const AppSettingsScreen(),
              '/notification_settings': (context) => const NotificationSettingsScreen(),
              '/help_center': (context) => const HelpCenterScreen(),
              '/about': (context) => const AboutScreen(),
              '/favorites': (context) => const FavoritesScreen(),
            },
          );
        },
      ),
    );
  }
}