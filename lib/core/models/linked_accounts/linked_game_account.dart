enum LinkedGameId { lol, valorant, cs2, dota2 }

/// Paths must match [AppRoutes] in `navigation.dart` (no import here — avoids cycles).
abstract class LinkedGameStatsRoutes {
  static const lol = '/player/games/lol';
  static const valorant = '/player/games/valorant';
  static const cs2 = '/player/games/cs2';
  static const dota2 = '/player/games/dota2';
}

class LinkedGameAccount {
  final LinkedGameId gameId;
  final String displayName;
  final String? avatarUrl;
  final String statsRoute;
  final String primaryStat;
  final String secondaryStat;

  const LinkedGameAccount({
    required this.gameId,
    required this.displayName,
    this.avatarUrl,
    required this.statsRoute,
    required this.primaryStat,
    required this.secondaryStat,
  });

  LinkedGameAccount copyWith({
    String? primaryStat,
    String? secondaryStat,
    String? displayName,
    String? avatarUrl,
  }) {
    return LinkedGameAccount(
      gameId: gameId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      statsRoute: statsRoute,
      primaryStat: primaryStat ?? this.primaryStat,
      secondaryStat: secondaryStat ?? this.secondaryStat,
    );
  }

  static String _riotDisplayName(Map<String, dynamic> riot) {
    final gn = riot['riotGameName']?.toString();
    if (gn != null && gn.isNotEmpty) return gn.toUpperCase();
    final tag = riot['riotTagLine']?.toString();
    if (tag != null && tag.isNotEmpty) return tag.toUpperCase();
    return '';
  }

  factory LinkedGameAccount.lol(
    Map<String, dynamic> riotStatus, {
    String primaryStat = '--',
    String secondaryStat = '--',
    String fallbackName = 'SUMMONER',
  }) {
    final name = _riotDisplayName(riotStatus);
    return LinkedGameAccount(
      gameId: LinkedGameId.lol,
      displayName: name.isEmpty ? fallbackName : name,
      avatarUrl: null,
      statsRoute: LinkedGameStatsRoutes.lol,
      primaryStat: primaryStat,
      secondaryStat: secondaryStat,
    );
  }

  factory LinkedGameAccount.valorant(
    Map<String, dynamic> riotStatus, {
    String primaryStat = '--',
    String secondaryStat = '--',
    String fallbackName = 'AGENT',
  }) {
    final name = _riotDisplayName(riotStatus);
    return LinkedGameAccount(
      gameId: LinkedGameId.valorant,
      displayName: name.isEmpty ? fallbackName : name,
      avatarUrl: null,
      statsRoute: LinkedGameStatsRoutes.valorant,
      primaryStat: primaryStat,
      secondaryStat: secondaryStat,
    );
  }

  factory LinkedGameAccount.cs2(
    Map<String, dynamic> steam, {
    String primaryStat = '--',
    String secondaryStat = '--',
    String fallbackName = 'STEAM',
  }) {
    final u = steam['steamUsername']?.toString();
    return LinkedGameAccount(
      gameId: LinkedGameId.cs2,
      displayName:
          (u != null && u.isNotEmpty) ? u.toUpperCase() : fallbackName.toUpperCase(),
      avatarUrl: steam['steamAvatarUrl']?.toString(),
      statsRoute: LinkedGameStatsRoutes.cs2,
      primaryStat: primaryStat,
      secondaryStat: secondaryStat,
    );
  }

  factory LinkedGameAccount.dota2(
    Map<String, dynamic> steam, {
    String primaryStat = '--',
    String secondaryStat = '--',
    String fallbackName = 'STEAM',
  }) {
    final u = steam['steamUsername']?.toString();
    return LinkedGameAccount(
      gameId: LinkedGameId.dota2,
      displayName:
          (u != null && u.isNotEmpty) ? u.toUpperCase() : fallbackName.toUpperCase(),
      avatarUrl: steam['steamAvatarUrl']?.toString(),
      statsRoute: LinkedGameStatsRoutes.dota2,
      primaryStat: primaryStat,
      secondaryStat: secondaryStat,
    );
  }
}
