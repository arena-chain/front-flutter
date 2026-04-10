import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/core/api/riot/riot_api.dart';
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';
import 'package:arena_chain_flutter/screens/feature_auth/viewmodel/auth_viewmodel.dart';
<<<<<<< HEAD
import 'package:arena_chain_flutter/navigation.dart';
=======
import 'package:arena_chain_flutter/screens/player/feature_home/viewmodel/level_viewmodel.dart';
import 'package:arena_chain_flutter/navigation.dart';
import 'package:arena_chain_flutter/screens/player/feature_home/_common/side_drawer.dart';
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056

class PlayerProfileScreen extends StatefulWidget {
  const PlayerProfileScreen({super.key});

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  final RiotApi _riotApi = RiotApi();
  final TokenStorage _tokenStorage = TokenStorage();

  bool _isLoadingLinkStatus = true;
  String _linkStatus = 'unlinked';
  String? _riotGameName;
  String? _riotTagLine;
  String? _riotRegion;

  late final TextEditingController _nicknameController;
  String? _avatarUrl;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController();

    // Initialize with data on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final user = authViewModel.currentUser;
      _nicknameController.text = user?.nickname ?? 'Player';
      _avatarUrl = user?.avatar ?? '';
      setState(() {});
      _checkLinkStatus();
<<<<<<< HEAD
=======
      context.read<LevelViewModel>().fetchMyLevel();
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
    });
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _checkLinkStatus() async {
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        if (mounted) setState(() => _isLoadingLinkStatus = false);
        return;
      }

      final result = await _riotApi.getLinkStatus(token: token);
      if (mounted) {
        setState(() {
          _linkStatus = result['status'] ?? 'unlinked';
          _riotGameName = result['riotGameName'];
          _riotTagLine = result['riotTagLine'];
          _riotRegion = result['riotRegion'];
          _isLoadingLinkStatus = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingLinkStatus = false);
    }
  }

  void _generateRandomAvatar() {
    final styles = ['avataaars', 'bottts', 'pixel-art', 'lorelei', 'adventurer'];
    final randomStyle = styles[Random().nextInt(styles.length)];
    final randomSeed = Random().nextInt(100000).toString();

    setState(() {
      _avatarUrl = 'https://api.dicebear.com/7.x/$randomStyle/png?seed=$randomSeed';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nouvel avatar généré !', style: TextStyle(color: Colors.black)),
        backgroundColor: Color(0xFF00FF00),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleSave() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    // First update locally for instant feedback
    authViewModel.updateLocalProfile(nickname: _nicknameController.text, avatarUrl: _avatarUrl);

    setState(() {
      _isEditing = false;
    });

    // Then persist to backend + local storage so it survives logout/login
    final success = await authViewModel.updateProfile(
      nickname: _nicknameController.text,
      avatarUrl: _avatarUrl,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Profil mis à jour avec succès.' : 'Sauvegarde locale uniquement (hors ligne).',
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: const Color(0xFF00FF00),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        final user = authViewModel.currentUser;
        final country = user?.country ?? 'TUNISIA';
        // If not editing, display truth from state or input. If editing, display input.
        final nickname = _isEditing ? _nicknameController.text : (_nicknameController.text.isNotEmpty ? _nicknameController.text : (user?.nickname ?? 'Player'));
        final email = user?.email ?? '';
        final isPro = user?.profile?.isPro ?? false;

        return Scaffold(
<<<<<<< HEAD
          backgroundColor: const Color(0xFF0A0E1A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0A0E1A),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Row(
              children: [
                Icon(Icons.person, color: Color(0xFF00FF00), size: 24),
                SizedBox(width: 8),
                Text(
                  'My Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, color: Color(0xFF00FF00)),
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.settings);
                },
=======
          backgroundColor: const Color(0xFF121212),
          drawer: const SideDrawer(),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0A0E1A),
            elevation: 0,
            leading: Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFF00FF00)),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
                tooltip: 'Menu',
              ),
            ),
            title: const Text(
              'Profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            actions: [
              if (Navigator.canPop(context))
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              IconButton(
                icon: Icon(
                  _isEditing ? Icons.close : Icons.edit_outlined,
                  color: const Color(0xFF00FF00),
                ),
                onPressed: () {
                  setState(() => _isEditing = !_isEditing);
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Color(0xFF00FF00)),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
<<<<<<< HEAD
              children: [
                const SizedBox(height: 24),
                _buildProfileHeader(nickname, email, isPro),
                const SizedBox(height: 24),
                _buildStatsSection(),
                const SizedBox(height: 24),
                _buildTeamManagementSection(authViewModel),
                const SizedBox(height: 24),
=======
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isEditing) ...[
                  const SizedBox(height: 16),
                  _buildProfileHeader(nickname, email, isPro),
                  const SizedBox(height: 24),
                ] else ...[
                  _buildCinematicHero(context, nickname, email, isPro, country),
                  const SizedBox(height: 28),
                  _buildEndorsementsSection(),
                  const SizedBox(height: 28),
                  _buildPortfolioGallery(context),
                  const SizedBox(height: 28),
                  _buildActivityFeed(context, nickname),
                  const SizedBox(height: 28),
                ],
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
                _buildConnectedGameAccounts(),
                const SizedBox(height: 24),
                _buildMyLeagues(),
                const SizedBox(height: 24),
                _buildAchievements(),
<<<<<<< HEAD
                const SizedBox(height: 24),
=======
                const SizedBox(height: 32),
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
              ],
            ),
          ),
        );
      },
    );
  }

<<<<<<< HEAD
  Widget _buildTeamManagementSection(AuthViewModel auth) {
    final user = auth.currentUser;
    final role = user?.role.toLowerCase() ?? '';
    final isManager = role == 'team_manager';
    final isAdmin = role == 'admin';
=======
  static const Color _neon = Color(0xFF00FF00);

  Widget _buildCinematicHero(
    BuildContext context,
    String nickname,
    String email,
    bool isPro,
    String country,
  ) {
    final avatarUrl = _avatarUrl ?? '';
    final displayName = nickname.toUpperCase().replaceAll(' ', '_');
    final tierLabel = isPro ? 'ELITE_RANK' : 'PLAYER_RANK';
    final bio = isPro
        ? 'Specializing in competitive play, data-driven improvement, and team synergy. Open to scrims and org opportunities.'
        : 'Building skills across FPS & MOBA titles. Connect for games, clips, and community.';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 36),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF040609), Color(0xFF0A0E1A), Color(0xFF121212)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: CustomPaint(
            painter: _ProfileGridPainter(color: _neon.withValues(alpha: 0.12)),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 108,
                      height: 108,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [_neon.withValues(alpha: 0.9), _neon.withValues(alpha: 0.15)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _neon.withValues(alpha: 0.35),
                            blurRadius: 28,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF040609),
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: avatarUrl.isNotEmpty
                              ? Image.network(avatarUrl, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _avatarFallback(nickname))
                              : _avatarFallback(nickname),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FF00),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF040609), width: 3),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: _neon, shape: BoxShape.circle)),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        displayName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '$tierLabel | CONNECTIONS: — | FOLLOWERS: —',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11),
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.myChannel);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: _neon,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'WORK WITH ME',
                      style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Follow coming soon')),
                          );
                        },
                        icon: const Icon(Icons.person_add_alt_1, size: 18),
                        label: const Text('FOLLOW'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.addFriend);
                        },
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: const Text('MESSAGE'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  bio,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _hashChip('#${country.toUpperCase()}'),
                    if (isPro) _hashChip('#PRO'),
                    _hashChip('#ARENA'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _avatarFallback(String nickname) {
    return Center(
      child: Text(
        nickname.isNotEmpty ? nickname[0].toUpperCase() : 'P',
        style: const TextStyle(color: _neon, fontSize: 40, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _hashChip(String tag) {
    return Text(
      tag,
      style: const TextStyle(color: _neon, fontSize: 12, fontWeight: FontWeight.w700),
    );
  }

  Widget _buildEndorsementsSection() {
    final items = <(IconData, String, double)>[
      (Icons.track_changes, 'Strategic', 0.82),
      (Icons.bolt, 'Mechanics', 0.76),
      (Icons.architecture, 'Draft IQ', 0.68),
      (Icons.how_to_reg, 'Comms', 0.91),
      (Icons.handshake, 'Teamplay', 0.74),
    ];
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
<<<<<<< HEAD
          const Row(
            children: [
              Icon(Icons.groups, color: Color(0xFF00FF00), size: 20),
              SizedBox(width: 8),
              Text(
                'Team Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
=======
          Row(
            children: [
              Icon(Icons.rocket_launch_rounded, color: _neon.withValues(alpha: 0.9), size: 20),
              const SizedBox(width: 8),
              const Text(
                'ENDORSEMENTS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
                ),
              ),
            ],
          ),
<<<<<<< HEAD
          const SizedBox(height: 16),
          if (isManager)
            _buildActionTile(
              'Manager Dashboard',
              'Manage your squad, roster, and news.',
              Icons.dashboard_customize,
              const Color(0xFFE94560),
              () => Navigator.pushNamed(context, AppRoutes.managerDashboard, arguments: user?.teamId ?? ''),
            )
          else if (!isAdmin)
            _buildActionTile(
              'Become Team Manager',
              'Apply to leading your own official squad.',
              Icons.stars,
              const Color(0xFF00FF00),
              () => Navigator.pushNamed(context, AppRoutes.managerApplication),
            ),
          const SizedBox(height: 12),
          _buildActionTile(
            'Recruitment Inbox',
            'View team invitations and player offers.',
            Icons.mail_outline,
            Colors.blueAccent,
            () => Navigator.pushNamed(context, AppRoutes.playerInvitations),
=======
          const SizedBox(height: 18),
          SizedBox(
            height: 118,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, i) {
                final (icon, label, value) = items[i];
                return _endorsementRing(icon: icon, label: label, value: value);
              },
            ),
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
          ),
        ],
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildActionTile(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1221),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: const TextStyle(color: Color(0xFF7A86AC), fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
          ],
        ),
=======
  Widget _endorsementRing({required IconData icon, required String label, required double value}) {
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 3,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    value: value,
                    strokeWidth: 3,
                    color: _neon,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 22),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioGallery(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PORTFOLIO GALLERY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.myChannel),
                child: const Text('VIEW ALL', style: TextStyle(color: _neon, fontWeight: FontWeight.w800, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 132,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _portfolioCard(title: 'Q3 Scouting\nReport', icon: Icons.description_rounded, accent: const Color(0xFF4488FF)),
                const SizedBox(width: 12),
                _portfolioCard(title: 'META SHIFTS\nAnalysis', icon: Icons.analytics_rounded, accent: const Color(0xFFFFAA00)),
                const SizedBox(width: 12),
                _portfolioVideoCard(title: 'Highlights Reel'),
                const SizedBox(width: 12),
                _portfolioCard(title: 'Draft\nStrategy', icon: Icons.fact_check_rounded, accent: const Color(0xFFAA44FF)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _portfolioCard({required String title, required IconData icon, required Color accent}) {
    return Container(
      width: 148,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.2), Colors.white.withValues(alpha: 0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 28),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _portfolioVideoCard({required String title}) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.myChannel),
      child: Container(
        width: 148,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _neon.withValues(alpha: 0.45)),
          gradient: LinearGradient(
            colors: [_neon.withValues(alpha: 0.12), Colors.black.withValues(alpha: 0.5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Container(color: Colors.black.withValues(alpha: 0.35)),
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _neon.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: _neon, width: 2),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: _neon, size: 32),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityFeed(BuildContext context, String nickname) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule_rounded, color: _neon.withValues(alpha: 0.85), size: 20),
              const SizedBox(width: 8),
              const Text(
                'PROFESSIONAL ACTIVITY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _activityVideoCard(
                    title: 'META SHIFTS IN ARENA',
                    subtitle: 'Watch the latest breakdown from $nickname.',
                    timeLabel: 'Recently',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _activityArticleCard(
                    title: 'Rising Stars Report',
                    subtitle: 'Performance snapshot & next steps.',
                    timeLabel: 'Recently',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityVideoCard({required String title, required String subtitle, required String timeLabel}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black.withValues(alpha: 0.45),
                border: Border.all(color: _neon.withValues(alpha: 0.25)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.play_circle_fill_rounded, color: _neon.withValues(alpha: 0.85), size: 40),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(subtitle, maxLines: 2, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10, height: 1.3)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(timeLabel, style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 10)),
              const Spacer(),
              Icon(Icons.thumb_up_off_alt, size: 14, color: Colors.white.withValues(alpha: 0.35)),
              const SizedBox(width: 10),
              Icon(Icons.chat_bubble_outline, size: 14, color: Colors.white.withValues(alpha: 0.35)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _activityArticleCard({required String title, required String subtitle, required String timeLabel}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: _neon.withValues(alpha: 0.2),
                child: const Icon(Icons.article_rounded, color: _neon, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(subtitle, maxLines: 3, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 10, height: 1.35)),
          const SizedBox(height: 10),
          Text(timeLabel, style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 10)),
        ],
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
      ),
    );
  }

  Widget _buildConnectedGameAccounts() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.sports_esports, color: Color(0xFF00FF00), size: 20),
              SizedBox(width: 8),
              Text(
                'Connected Game Accounts',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingLinkStatus)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1221),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1A1F36)),
              ),
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Color(0xFF00FF00),
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else if (_linkStatus == 'verified')
            _buildLinkedAccountCard()
          else if (_linkStatus == 'pending_verification')
            _buildPendingAccountCard()
          else
            _buildNoAccountsCard(),
        ],
      ),
    );
  }

  Widget _buildLinkedAccountCard() {
    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(
          context,
          AppRoutes.myAccount,
          arguments: {
            'gameName': _riotGameName,
            'tagLine': _riotTagLine,
            'region': _riotRegion,
            'autoFetch': true,
          },
        );
        _checkLinkStatus();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1221),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1A1F36)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC89B3C), width: 2),
              ),
              child: const Center(
                child: Text(
                  'LoL',
                  style: TextStyle(
                    color: Color(0xFFC89B3C),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'League of Legends',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.verified, color: Color(0xFF00FF00), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${_riotGameName ?? ''}#${_riotTagLine ?? ''}',
                        style: const TextStyle(
                          color: Color(0xFF7A86AC),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFF7A86AC), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingAccountCard() {
    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(
          context,
          AppRoutes.myAccount,
          arguments: {
            'gameName': _riotGameName,
            'tagLine': _riotTagLine,
            'region': _riotRegion,
            'autoFetch': false,
          },
        );
        _checkLinkStatus();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1221),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF9800), width: 2),
              ),
              child: const Center(
                child: Text(
                  'LoL',
                  style: TextStyle(
                    color: Color(0xFFFF9800),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'League of Legends',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.pending, color: Colors.orange.shade300, size: 14),
                      const SizedBox(width: 4),
                      const Text(
                        'Pending verification',
                        style: TextStyle(
                          color: Color(0xFFFF9800),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFF7A86AC), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAccountsCard() {
    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(context, AppRoutes.myAccount);
        _checkLinkStatus();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1221),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1A1F36)),
        ),
        child: Column(
          children: [
            Icon(Icons.link_off, color: Colors.white.withOpacity(0.2), size: 40),
            const SizedBox(height: 12),
            const Text(
              'Connect your game account and fetch its data',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF7A86AC),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF00FF00).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF00FF00)),
              ),
              child: const Text(
                'Connect Now',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String nickname, String email, bool isPro) {
    final avatarUrl = _avatarUrl ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1221),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1A1F36)),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _isEditing ? _generateRandomAvatar : null,
                  child: Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FF00).withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF00FF00), width: 3),
                          image: avatarUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(avatarUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: avatarUrl.isEmpty
                            ? Center(
                                child: Text(
                                  nickname.isNotEmpty ? nickname[0].toUpperCase() : 'P',
                                  style: const TextStyle(
                                    color: Color(0xFF00FF00),
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      if (_isEditing)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.refresh, color: Colors.white, size: 24),
                                Text(
                                  'Generate',
                                  style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                )
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isEditing)
                        TextField(
                          controller: _nicknameController,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            filled: true,
                            fillColor: const Color(0xFF151515),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF1A1F36)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF00FF00)),
                            ),
                          ),
                        )
                      else
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                nickname,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Color(0xFF7A86AC), size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setState(() {
                                  _isEditing = true;
                                });
                              },
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      Text(
                        isPro ? 'Professional Player' : 'Casual Player',
                        style: const TextStyle(
                          color: Color(0xFF7A86AC),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FF00).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF00FF00)),
                        ),
                        child: const Text(
                          'Diamond',
                          style: TextStyle(
                            color: Color(0xFF00FF00),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_isEditing) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00FF00),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = false;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF1A1F36)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard('Matches', '142', Icons.sports_esports),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard('Wins', '89', Icons.emoji_events),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard('Win Rate', '63%', Icons.trending_up),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1221),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A1F36)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF00FF00), size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF00FF00),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF7A86AC),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

=======
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
  Widget _buildMyLeagues() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield, color: Color(0xFF00FF00), size: 20),
              SizedBox(width: 8),
              Text(
                'My Leagues',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLeagueCard(
            name: 'Valorant Pro League',
            game: 'Valorant',
            rank: '#12',
            points: '2680 pts',
            rankBadge: 'Diamond',
            rankColor: const Color(0xFF00FF00),
          ),
          const SizedBox(height: 12),
          _buildLeagueCard(
            name: 'League of Legends Masters',
            game: 'League of Legends',
            rank: '#8',
            points: '3150 pts',
            rankBadge: 'Platinum',
            rankColor: const Color(0xFF00DDDD),
          ),
          const SizedBox(height: 12),
          _buildLeagueCard(
            name: 'CS2 Elite Division',
            game: 'CS2',
            rank: '#24',
            points: '1890 pts',
            rankBadge: 'Gold',
            rankColor: const Color(0xFFFFAA00),
          ),
        ],
      ),
    );
  }

  Widget _buildLeagueCard({
    required String name,
    required String game,
    required String rank,
    required String points,
    required String rankBadge,
    required Color rankColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1221),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A1F36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: rankColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: rankColor),
                ),
                child: Text(
                  rankBadge,
                  style: TextStyle(
                    color: rankColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F36),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              game,
              style: const TextStyle(
                color: Color(0xFF7A86AC),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rank $rank',
                style: const TextStyle(
                  color: Color(0xFF7A86AC),
                  fontSize: 13,
                ),
              ),
              Text(
                points,
                style: const TextStyle(
                  color: Color(0xFF00FF00),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events, color: Color(0xFF00FF00), size: 20),
              SizedBox(width: 8),
              Text(
                'Achievements',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildAchievementBadge('First Win', Icons.emoji_events),
              _buildAchievementBadge('10 Wins', Icons.military_tech),
              _buildAchievementBadge('50 Matches', Icons.sports_esports),
              _buildAchievementBadge('Diamond Rank', Icons.diamond),
              _buildAchievementBadge('Win Streak', Icons.local_fire_department),
              _buildAchievementBadge('Team Player', Icons.groups),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadge(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1221),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00FF00)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF00FF00), size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
<<<<<<< HEAD
=======

class _ProfileGridPainter extends CustomPainter {
  final Color color;

  _ProfileGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const step = 28.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ProfileGridPainter oldDelegate) => oldDelegate.color != color;
}
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
