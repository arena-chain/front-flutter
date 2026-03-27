import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/screens/feature_auth/ui/splash_screen.dart';
import 'package:arena_chain_flutter/screens/feature_auth/ui/login_screen.dart';
import 'package:arena_chain_flutter/screens/feature_auth/ui/signup_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_home/player_home.dart';
import 'package:arena_chain_flutter/screens/player/feature_profile/ui/player_profile_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_home/_common/notification.dart';
import 'package:arena_chain_flutter/screens/player/feature_profile/ui/settings_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_profile/ui/my_channel_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_profile/ui/subscriptions_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_leagues/ui/leagues_list_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_news/ui/news_list_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String playerHome = '/player/home';
  static const String playerProfile = '/player/profile';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String myChannel = '/player/channel';
  static const String subscriptions = '/player/subscriptions';
  static const String leagues = '/player/leagues';
  static const String news = '/player/news';

  static Map<String, WidgetBuilder> get routes => {
        splash: (context) => const SplashScreen(),
        login: (context) => const LoginScreen(),
        signup: (context) => const SignupScreen(),
        playerHome: (context) => const PlayerHomeScreen(),
        playerProfile: (context) => const PlayerProfileScreen(),
        notifications: (context) => const NotificationScreen(),
        settings: (context) => const SettingsScreen(),
        myChannel: (context) => const MyChannelScreen(),
        subscriptions: (context) => const SubscriptionsScreen(),
        leagues: (context) => const LeaguesListScreen(),
        news: (context) => const NewsListScreen(),
      };
}
