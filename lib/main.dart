import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/navigation.dart';
import 'package:arena_chain_flutter/screens/feature_auth/viewmodel/auth_viewmodel.dart';
import 'package:arena_chain_flutter/screens/player/feature_leagues/viewmodel/league_viewmodel.dart';
import 'package:arena_chain_flutter/screens/player/feature_news/viewmodel/news_viewmodel.dart';
import 'package:arena_chain_flutter/screens/player/feature_rank/viewmodel/rank_viewmodel.dart';
import 'package:arena_chain_flutter/screens/player/feature_home/viewmodel/level_viewmodel.dart';
import 'package:arena_chain_flutter/core/models/feature_auth/auth_state.dart';
import 'package:arena_chain_flutter/screens/player/feature_home/player_home.dart';
import 'package:arena_chain_flutter/screens/feature_auth/ui/login_screen.dart';
import 'package:arena_chain_flutter/screens/feature_auth/ui/splash_screen.dart';
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
        ChangeNotifierProvider(
          create: (_) => LeagueViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => NewsViewModel()..fetchNews(refresh: true),
        ),
        ChangeNotifierProvider(
          create: (_) => RankViewModel()..fetchMyRanks(),
        ),
        ChangeNotifierProvider(
          create: (_) => LevelViewModel(),
        ),
      ],
      child: MaterialApp(
        title: 'Arena-Chain',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: GoogleFonts.inter().fontFamily,
          scaffoldBackgroundColor: const Color(0xFF0F0C08),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF00FF00),
            brightness: Brightness.dark,
            primary: const Color(0xFF00FF00),
            surface: const Color(0xFF0F0C08),
          ),
          useMaterial3: true,
        ),
        home: Consumer<AuthViewModel>(
          builder: (context, authViewModel, child) {
            switch (authViewModel.authState) {
              case AuthState.authenticated:
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
