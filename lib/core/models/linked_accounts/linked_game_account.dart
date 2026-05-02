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
  final String? rankTier;
  final String? matchesCount;
  final String? mainRole;
  final String? streak;

  const LinkedGameAccount({
    required this.gameId,
    required this.displayName,
    this.avatarUrl,
    required this.statsRoute,
    required this.primaryStat,
    required this.secondaryStat,
    this.rankTier,
    this.matchesCount,
    this.mainRole,
    this.streak,
  });

  LinkedGameAccount copyWith({
    String? primaryStat,
    String? secondaryStat,
    String? displayName,
    String? avatarUrl,
    String? rankTier,
    String? matchesCount,
    String? mainRole,
    String? streak,
  }) {
    return LinkedGameAccount(
      gameId: gameId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      statsRoute: statsRoute,
      primaryStat: primaryStat ?? this.primaryStat,
      secondaryStat: secondaryStat ?? this.secondaryStat,
      rankTier: rankTier ?? this.rankTier,
      matchesCount: matchesCount ?? this.matchesCount,
      mainRole: mainRole ?? this.mainRole,
      streak: streak ?? this.streak,
    );
  }

  static String _riotDisplayName(Map<String, dynamic> riot) {
    final gn = riot['riotGameName']?.toString();
    if (gn != null && gn.isNotEmpty) return gn.toUpperCase();
    final tag = riot['riotTagLine']?.toString();
    if (tag != null && tag.isNotEmpty) return tag.toUpperCase();
    return '';
  }

  /// Steam status payloads may use camelCase or snake_case depending on gateway.
  static String? _steamAvatarFromStatus(Map<String, dynamic> steam) {
    for (final key in [
      'steamAvatarUrl',
      'steam_avatar_url',
    ]) {
      final raw = steam[key]?.toString().trim();
      if (raw != null && raw.isNotEmpty) return raw;
    }
    return null;
  }

  factory LinkedGameAccount.lol(
    Map<String, dynamic> riotStatus, {
    String primaryStat = '--',
    String secondaryStat = '--',
    String fallbackName = 'SUMMONER',
    String? rankTier,
    String? matchesCount,
    String? mainRole,
    String? streak,
  }) {
    final name = _riotDisplayName(riotStatus);
    return LinkedGameAccount(
      gameId: LinkedGameId.lol,
      displayName: name.isEmpty ? fallbackName : name,
      avatarUrl: riotStatus['riotAvatarUrl']?.toString(),
      statsRoute: LinkedGameStatsRoutes.lol,
      primaryStat: primaryStat,
      secondaryStat: secondaryStat,
      rankTier: rankTier,
      matchesCount: matchesCount,
      mainRole: mainRole,
      streak: streak,
    );
  }

  factory LinkedGameAccount.valorant(
    Map<String, dynamic> riotStatus, {
    String primaryStat = '--',
    String secondaryStat = '--',
    String fallbackName = 'AGENT',
    String? rankTier,
    String? matchesCount,
    String? mainRole,
    String? streak,
  }) {
    final name = _riotDisplayName(riotStatus);
    return LinkedGameAccount(
      gameId: LinkedGameId.valorant,
      displayName: name.isEmpty ? fallbackName : name,
      avatarUrl: riotStatus['riotAvatarUrl']?.toString(),
      statsRoute: LinkedGameStatsRoutes.valorant,
      primaryStat: primaryStat,
      secondaryStat: secondaryStat,
      rankTier: rankTier,
      matchesCount: matchesCount,
      mainRole: mainRole,
      streak: streak,
    );
  }

  factory LinkedGameAccount.cs2(
    Map<String, dynamic> steam, {
    String primaryStat = '--',
    String secondaryStat = '--',
    String fallbackName = 'STEAM',
    String? rankTier,
    String? matchesCount,
    String? mainRole,
    String? streak,
  }) {
    final u = steam['steamUsername']?.toString();
    return LinkedGameAccount(
      gameId: LinkedGameId.cs2,
      displayName: (u != null && u.isNotEmpty)
          ? u.toUpperCase()
          : fallbackName.toUpperCase(),
      avatarUrl: _steamAvatarFromStatus(steam),
      statsRoute: LinkedGameStatsRoutes.cs2,
      primaryStat: primaryStat,
      secondaryStat: secondaryStat,
      rankTier: rankTier,
      matchesCount: matchesCount,
      mainRole: mainRole,
      streak: streak,
    );
  }

  factory LinkedGameAccount.dota2(
    Map<String, dynamic> steam, {
    String primaryStat = '--',
    String secondaryStat = '--',
    String fallbackName = 'STEAM',
    String? rankTier,
    String? matchesCount,
    String? mainRole,
    String? streak,
  }) {
    final u = steam['steamUsername']?.toString();
    return LinkedGameAccount(
      gameId: LinkedGameId.dota2,
      displayName: (u != null && u.isNotEmpty)
          ? u.toUpperCase()
          : fallbackName.toUpperCase(),
      avatarUrl: _steamAvatarFromStatus(steam),
      statsRoute: LinkedGameStatsRoutes.dota2,
      primaryStat: primaryStat,
      secondaryStat: secondaryStat,
      rankTier: rankTier,
      matchesCount: matchesCount,
      mainRole: mainRole,
      streak: streak,
    );
  }
}
