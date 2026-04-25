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
import 'package:arena_chain_flutter/screens/leagues/player_leagues_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_friends/ui/add_friend_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_friends/ui/friends_list_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_friends/ui/player_public_profile_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_tournemets/ui/create_tournament_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_tournemets/ui/booking_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_tournemets/ui/ticket_screen.dart';
import 'package:arena_chain_flutter/core/models/feature_tournaments/tournament_model.dart';
import 'package:arena_chain_flutter/screens/player/feature_matchmaking/ui/matchmaking_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_matchmaking/ui/game_room_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_news/ui/news_list_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_messages/ui/messages_screen.dart';
import 'package:arena_chain_flutter/screens/Team_Manager/manager_application_screen.dart';
import 'package:arena_chain_flutter/screens/admin/admin_manager_approval_screen.dart';
import 'package:arena_chain_flutter/screens/Team_Manager/team_manager_dashboard.dart';
import 'package:arena_chain_flutter/screens/Team_Manager/recruit_player_screen.dart';
import 'package:arena_chain_flutter/screens/Team_Manager/manage_roster_screen.dart';
import 'package:arena_chain_flutter/screens/player/player_invitations_screen.dart';
import 'package:arena_chain_flutter/screens/Team_Manager/team_feed_screen.dart';
import 'package:arena_chain_flutter/screens/Team_Manager/team_profile_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_live/ui/live_stream_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_live/ui/scheduled_streams_screen.dart';
import 'package:arena_chain_flutter/screens/scouter/ui/scouter_home_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_chat/ui/chat_list_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_chat/ui/chat_detail_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_chat/ui/group_chat_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_ticketing/event_browse_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_ticketing/ticket_wallet_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_ticketing/event_details_screen.dart';
import 'package:arena_chain_flutter/core/models/feature_ticketing/ticketing_models.dart';

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
  static const String messages = '/player/messages';
  static const String addFriend = '/player/friends/add';
  static const String friendsList = '/player/friends';
  static const String playerPublicProfile = '/player/profile/public';
  static const String createTournament = '/tournaments/create';
  static const String tournamentBooking = '/tournaments/booking';
  static const String tournamentTicket = '/tournaments/ticket';
  static const String matchmaking = '/player/matchmaking';
  static const String gameRoom = '/player/game-room';
  static const String chatList = '/player/chat';
  static const String chatDetail = '/player/chat/detail';
  static const String groupChat = '/player/chat/groups';
  static const String browseEvents = '/player/events';
  static const String ticketWallet = '/player/tickets';
  static const String eventDetails = '/player/event/details';

  // Team & Manager Routes
  static const String managerApplication = '/manager/apply';
  static const String adminManagerApproval = '/admin/managers';
  static const String managerDashboard = '/manager/dashboard';
  static const String recruitPlayer = '/manager/recruit';
  static const String manageRoster = '/manager/roster';
  static const String playerInvitations = '/player/invitations';
  static const String teamFeed = '/team/feed';
  static const String teamProfile = '/team/profile';
  static const String liveStream = '/player/live-stream';
  static const String scheduledStreams = '/player/scheduled-streams';
  static const String scouterHome = '/scouter/home';

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
        leagues: (context) => const PlayerLeaguesScreen(),
        news: (context) => const NewsListScreen(),
        messages: (context) => const MessagesScreen(),
        addFriend: (context) => const AddFriendScreen(),
        friendsList: (context) => const FriendsListScreen(),
        playerPublicProfile: (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          String userId;
          String? preNick;
          String? preEmail;
          String? preAvatar;
          if (args is Map<String, dynamic>) {
            userId = args['userId'] as String;
            preNick = args['nickname'] as String?;
            preEmail = args['email'] as String?;
            preAvatar = args['avatar'] as String?;
          } else {
            userId = args as String;
          }
          return PlayerPublicProfileScreen(
            targetUserId: userId,
            prefillNickname: preNick,
            prefillEmail: preEmail,
            prefillAvatarUrl: preAvatar,
          );
        },
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
        chatList: (context) => const ChatListScreen(),
        groupChat: (context) => const GroupChatScreen(),
        chatDetail: (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ChatDetailScreen(
            userId: args['userId'] as String,
            nickname: args['nickname'] as String,
            avatar: args['avatar'] as String?,
          );
        },

        // Team & Manager Screen mappings
        managerApplication: (context) => const ManagerApplicationScreen(),
        adminManagerApproval: (context) => const AdminManagerApprovalScreen(),
        managerDashboard: (context) {
          final teamId = ModalRoute.of(context)!.settings.arguments as String;
          return ManagerDashboardScreen(teamId: teamId);
        },
        recruitPlayer: (context) {
          final teamId = ModalRoute.of(context)!.settings.arguments as String;
          return RecruitPlayerScreen(teamId: teamId);
        },
        manageRoster: (context) {
          final teamId = ModalRoute.of(context)!.settings.arguments as String;
          return ManageRosterScreen(teamId: teamId);
        },
        playerInvitations: (context) => const PlayerInvitationsScreen(),
        teamFeed: (context) {
          final teamId = ModalRoute.of(context)!.settings.arguments as String;
          return TeamFeedScreen(teamId: teamId);
        },
        teamProfile: (context) {
          final teamId = ModalRoute.of(context)!.settings.arguments as String;
          return TeamProfileScreen(teamId: teamId);
        },
        liveStream: (context) {
          final streamId = ModalRoute.of(context)!.settings.arguments as String;
          return LiveStreamScreen(streamId: streamId);
        },
        scheduledStreams: (context) => const ScheduledStreamsScreen(),
        scouterHome: (context) => const ScouterHomeScreen(),
        browseEvents: (context) => const PlayerHomeScreen(initialIndex: 3),
        ticketWallet: (context) => const PlayerHomeScreen(initialIndex: 6),
        eventDetails: (context) {
          final args = ModalRoute.of(context)!.settings.arguments as EventModel;
          return EventDetailsScreen(event: args);
        },
      };
}
