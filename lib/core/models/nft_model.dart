// ignore_for_file: constant_identifier_names
import 'package:flutter/foundation.dart';

/// Rarités NFT — correspond exactement aux valeurs utilisées côté Web
enum NftRarity {
  COMMON,
  UNCOMMON,
  RARE,
  EPIC,
  LEGENDARY,
  MYTHIC;

  static NftRarity fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'UNCOMMON':
        return NftRarity.UNCOMMON;
      case 'RARE':
        return NftRarity.RARE;
      case 'EPIC':
        return NftRarity.EPIC;
      case 'LEGENDARY':
        return NftRarity.LEGENDARY;
      case 'MYTHIC':
        return NftRarity.MYTHIC;
      default:
        return NftRarity.COMMON;
    }
  }

  String get label => name;

  int get order {
    switch (this) {
      case NftRarity.COMMON:
        return 0;
      case NftRarity.UNCOMMON:
        return 1;
      case NftRarity.RARE:
        return 2;
      case NftRarity.EPIC:
        return 3;
      case NftRarity.LEGENDARY:
        return 4;
      case NftRarity.MYTHIC:
        return 5;
    }
  }
}

/// Modèle propriétaire/assigné (populated depuis l'API)
@immutable
class NftUser {
  final String id;
  final String username;
  final String? nickname;

  const NftUser({
    required this.id,
    required this.username,
    this.nickname,
  });

  factory NftUser.fromJson(dynamic json) {
    if (json is String) {
      return NftUser(id: json, username: '');
    }
    if (json is Map<String, dynamic>) {
      return NftUser(
        id: json['_id'] as String? ?? '',
        username: json['username'] as String? ?? '',
        nickname: json['nickname'] as String?,
      );
    }
    return const NftUser(id: '', username: '');
  }

  String get displayName => nickname?.isNotEmpty == true ? nickname! : username;
}

/// Représente un NFT du marketplace ou de l'inventaire personnel.
/// La réponse API retourne des `NftItem` avec `nftId` populated.
@immutable
class NftModel {
  /// _id de l'NftItem (instance possédée par un joueur)
  final String id;

  /// Nom issu de nftId.name
  final String name;

  /// URL image issue de nftId.imageUrl
  final String imageUrl;

  /// Description issue de nftId.description
  final String description;

  /// Rareté issue de nftId.rarity
  final NftRarity rarity;

  /// Prix de base (AC) issu de nftId.price
  final double price;

  /// Prix de vente si listé
  final double? listPrice;

  /// Propriétaire actuel (populated ou ID string)
  final NftUser? owner;

  /// Statut : OWNED | LISTED | SOLD | BURNED
  final String status;

  /// Date de création/assignation
  final DateTime createdAt;

  const NftModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.rarity,
    required this.price,
    this.listPrice,
    this.owner,
    required this.status,
    required this.createdAt,
  });

  bool get isListed => status == 'LISTED';

  double get displayPrice => listPrice ?? price;

  /// Mappe depuis la réponse API réelle (NftItem avec nftId populated)
  factory NftModel.fromJson(Map<String, dynamic> json) {
    // Le champ nftId est soit un objet populated, soit un string ID
    final nftId = json['nftId'];
    final nftData = nftId is Map<String, dynamic> ? nftId : <String, dynamic>{};

    double parsePrice(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return NftModel(
      id: json['_id'] as String? ?? '',
      name: nftData['name'] as String? ?? 'Unknown NFT',
      imageUrl: nftData['imageUrl'] as String? ?? nftData['image'] as String? ?? '',
      description: nftData['description'] as String? ?? '',
      rarity: NftRarity.fromString(nftData['rarity'] as String?),
      price: parsePrice(nftData['price']),
      listPrice: json['listPrice'] != null ? parsePrice(json['listPrice']) : null,
      owner: json['ownerId'] != null ? NftUser.fromJson(json['ownerId']) : null,
      status: json['status'] as String? ?? 'OWNED',
      createdAt: parseDate(json['createdAt']),
    );
  }

  NftModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? description,
    NftRarity? rarity,
    double? price,
    double? listPrice,
    NftUser? owner,
    String? status,
    DateTime? createdAt,
  }) {
    return NftModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      rarity: rarity ?? this.rarity,
      price: price ?? this.price,
      listPrice: listPrice ?? this.listPrice,
      owner: owner ?? this.owner,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Transaction NFT (historique marketplace)
@immutable
class NftTransaction {
  final String id;
  final String? nftName;
  final String? nftImageUrl;
  final NftUser? fromUser;
  final NftUser? toUser;
  final String type; // MINT | LIST | UNLIST | SALE | TRANSFER | BURN
  final double price;
  final String currency;
  final DateTime createdAt;

  const NftTransaction({
    required this.id,
    this.nftName,
    this.nftImageUrl,
    this.fromUser,
    this.toUser,
    required this.type,
    required this.price,
    required this.currency,
    required this.createdAt,
  });

  factory NftTransaction.fromJson(Map<String, dynamic> json) {
    // nftItemId → { _id, nftId: { name, imageUrl } }
    final nftItem = json['nftItemId'];
    final nftData = nftItem is Map<String, dynamic>
        ? (nftItem['nftId'] is Map<String, dynamic>
            ? nftItem['nftId'] as Map<String, dynamic>
            : <String, dynamic>{})
        : <String, dynamic>{};

    double parsePrice(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return NftTransaction(
      id: json['_id'] as String? ?? '',
      nftName: nftData['name'] as String?,
      nftImageUrl: nftData['imageUrl'] as String?,
      fromUser: json['fromUserId'] != null
          ? NftUser.fromJson(json['fromUserId'])
          : null,
      toUser: json['toUserId'] != null
          ? NftUser.fromJson(json['toUserId'])
          : null,
      type: json['type'] as String? ?? 'UNKNOWN',
      price: parsePrice(json['price']),
      currency: json['currency'] as String? ?? 'AC',
      createdAt: parseDate(json['createdAt']),
    );
  }
}
