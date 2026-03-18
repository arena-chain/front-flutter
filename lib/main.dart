import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/navigation.dart';
import 'package:arena_chain_flutter/screens/feature_auth/viewmodel/auth_viewmodel.dart';
import 'package:arena_chain_flutter/core/config/api_config.dart';
import 'package:arena_chain_flutter/core/models/feature_auth/auth_state.dart';
import 'package:arena_chain_flutter/screens/player/feature_friends/view_model/friends_view_model.dart';
import 'package:arena_chain_flutter/screens/player/feature_tournemets/view_model/tournaments_view_model.dart';
import 'package:arena_chain_flutter/screens/player/feature_matchmaking/view_model/matchmaking_view_model.dart';
import 'package:arena_chain_flutter/screens/player/feature_home/player_home.dart';
import 'package:arena_chain_flutter/screens/feature_auth/ui/login_screen.dart';
import 'package:arena_chain_flutter/screens/feature_auth/ui/splash_screen.dart';
import 'package:arena_chain_flutter/screens/scouter/ui/scouter_home_screen.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthViewModel()..checkAuthStatus(),
        ),
        ChangeNotifierProxyProvider<AuthViewModel, FriendsViewModel>(
          create: (context) => FriendsViewModel(currentUserId: ''),
          update: (context, auth, previous) => 
            FriendsViewModel(currentUserId: auth.currentUser?.id ?? ''),
        ),
        ChangeNotifierProxyProvider<AuthViewModel, TournamentsViewModel>(
          create: (context) => TournamentsViewModel(currentUserId: ''),
          update: (context, auth, previous) => 
            TournamentsViewModel(currentUserId: auth.currentUser?.id ?? ''),
        ),
        ChangeNotifierProxyProvider<AuthViewModel, MatchmakingViewModel>(
          create: (_) => MatchmakingViewModel(),
          update: (context, auth, previous) {
            final vm = previous ?? MatchmakingViewModel();
            vm.onAuthChanged(auth.authState == AuthState.authenticated);
            return vm;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Arena-Chain',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: GoogleFonts.inter().fontFamily,
          scaffoldBackgroundColor: const Color(0xFF080B14),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0D1117),
            brightness: Brightness.dark,
            primary: const Color(0xFF00FF00),
            secondary: const Color(0xFF7B2FBE),
            surface: const Color(0xFF0D1117),
            onSurface: Colors.white,
          ).copyWith(
            outline: const Color(0xFF1E2740),
            outlineVariant: const Color(0xFF1E2740),
          ),
          useMaterial3: true,
        ),
        home: Consumer<AuthViewModel>(
          builder: (context, authViewModel, child) {
            switch (authViewModel.authState) {
              case AuthState.authenticated:
                final role = authViewModel.currentUser?.role ?? '';
                if (role == 'scouter') return const ScouterHomeScreen();
                return const PlayerHomeScreen();
              case AuthState.unauthenticated:
                return const LoginScreen();
              case AuthState.loading:
                return const SplashScreen();
            }
          },
        ),
        routes: AppRoutes.routes..remove(AppRoutes.splash),
      ),
    );
  }
}
