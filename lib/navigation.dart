import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/screens/feature_auth/ui/splash_screen.dart';
import 'package:arena_chain_flutter/screens/feature_auth/ui/login_screen.dart';
import 'package:arena_chain_flutter/screens/feature_auth/ui/signup_screen.dart';
import 'package:arena_chain_flutter/screens/feature_auth/ui/signup_team_manager_screen.dart';
import 'package:arena_chain_flutter/screens/admin/ui/admin_home_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_home/player_home.dart';
import 'package:arena_chain_flutter/screens/player/feature_profile/ui/player_profile_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_home/_common/notification.dart';
import 'package:arena_chain_flutter/screens/player/feature_profile/ui/settings_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_profile/ui/my_channel_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_profile/ui/subscriptions_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_profile/ui/my_account_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_leagues/ui/leagues_list_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_friends/ui/add_friend_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_tournemets/ui/create_tournament_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_tournemets/ui/booking_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_tournemets/ui/ticket_screen.dart';
import 'package:arena_chain_flutter/core/models/feature_tournaments/tournament_model.dart';
import 'package:arena_chain_flutter/screens/player/feature_matchmaking/ui/matchmaking_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_matchmaking/ui/game_room_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_news/ui/news_list_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String signupTeamManager = '/signup/team-manager';
  static const String playerHome = '/player/home';
  static const String playerProfile = '/player/profile';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String adminHome = '/admin/home';
  static const String myAccount = '/player/my-account';

  static const String myChannel = '/player/channel';
  static const String subscriptions = '/player/subscriptions';
  static const String leagues = '/player/leagues';
  static const String news = '/player/news';
  static const String addFriend = '/player/friends/add';
  static const String createTournament = '/tournaments/create';
  static const String tournamentBooking = '/tournaments/booking';
  static const String tournamentTicket = '/tournaments/ticket';
  static const String matchmaking = '/player/matchmaking';
  static const String gameRoom = '/player/game-room';

  static Map<String, WidgetBuilder> get routes => {
        splash: (context) => const SplashScreen(),
        login: (context) => const LoginScreen(),
        signup: (context) => const SignupScreen(),
        signupTeamManager: (context) => const SignupTeamManagerScreen(),
        playerHome: (context) => const PlayerHomeScreen(),
        playerProfile: (context) => const PlayerProfileScreen(),
        notifications: (context) => const NotificationScreen(),
        settings: (context) => const SettingsScreen(),
        adminHome: (context) => const AdminHomeScreen(),
        myAccount: (context) => const MyAccountScreen(),
        myChannel: (context) => const MyChannelScreen(),
        subscriptions: (context) => const SubscriptionsScreen(),
        leagues: (context) => const LeaguesListScreen(),
        news: (context) => const NewsListScreen(),
        leagues: (context) => Scaffold(
          backgroundColor: const Color(0xFF0A0E1A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0A0E1A),
            title: const Text('Leagues', style: TextStyle(color: Colors.white)),
            leading: const BackButton(color: Colors.white),
          ),
          body: const LeaguesListScreen(),
        ),
        addFriend: (context) => const AddFriendScreen(),
        createTournament: (context) => const CreateTournamentScreen(),
        tournamentBooking: (context) {
          final args = ModalRoute.of(context)!.settings.arguments as TournamentModel;
          return BookingScreen(tournament: args);
        },
        tournamentTicket: (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return TicketScreen(
            tournament: args['tournament'] as TournamentModel,
            ticketCount: args['ticketCount'] as int,
          );
        },
        matchmaking: (context) => const MatchmakingScreen(),
        gameRoom: (context) => const GameRoomScreen(),
      };
}
