import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:arena_chain_flutter/core/api/nft_api.dart';
import 'package:arena_chain_flutter/core/models/nft_model.dart';

enum MarketplaceStatus { initial, loading, loaded, error }
enum MarketplaceTab { marketplace, myNfts }

/// Tri disponible pour la liste des NFTs
enum NftSortOrder { priceAsc, priceDesc, rarityDesc }

/// ViewModel du marketplace NFT.
/// Gère la couche data, le polling automatique (30s) et les filtres.
class MarketplaceViewModel extends ChangeNotifier {
  final NftApi _api = NftApi();

  // ── État ──────────────────────────────────────────────────────────────
  MarketplaceStatus _status = MarketplaceStatus.initial;
  MarketplaceTab _activeTab = MarketplaceTab.marketplace;
  String? _errorMessage;

  // ── Données brutes ────────────────────────────────────────────────────
  List<NftModel> _marketplaceNfts = [];
  List<NftModel> _myNfts = [];
  List<NftTransaction> _transactions = [];

  // ── Filtres ───────────────────────────────────────────────────────────
  NftRarity? _filterRarity; // null = toutes les raretés
  String _searchQuery = '';
  NftSortOrder _sortOrder = NftSortOrder.priceAsc;

  // ── Action en cours ───────────────────────────────────────────────────
  bool _isBuying = false;
  bool _isListing = false;

  // ── Polling ───────────────────────────────────────────────────────────
  Timer? _pollingTimer;
  static const Duration _pollingInterval = Duration(seconds: 30);

  // ── Getters ───────────────────────────────────────────────────────────
  MarketplaceStatus get status => _status;
  MarketplaceTab get activeTab => _activeTab;
  String? get errorMessage => _errorMessage;
  List<NftTransaction> get transactions => _transactions;
  NftRarity? get filterRarity => _filterRarity;
  String get searchQuery => _searchQuery;
  NftSortOrder get sortOrder => _sortOrder;
  bool get isBuying => _isBuying;
  bool get isListing => _isListing;
  bool get isLoading => _status == MarketplaceStatus.loading;

  /// NFTs filtrés et triés selon l'onglet actif
  List<NftModel> get filteredNfts {
    final source = _activeTab == MarketplaceTab.marketplace
        ? _marketplaceNfts
        : _myNfts;

    var result = source.where((nft) {
      if (_filterRarity != null && nft.rarity != _filterRarity) return false;
      if (_searchQuery.isNotEmpty &&
          !nft.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    result.sort((a, b) {
      switch (_sortOrder) {
        case NftSortOrder.priceAsc:
          return a.displayPrice.compareTo(b.displayPrice);
        case NftSortOrder.priceDesc:
          return b.displayPrice.compareTo(a.displayPrice);
        case NftSortOrder.rarityDesc:
          return b.rarity.order.compareTo(a.rarity.order);
      }
    });

    return result;
  }

  /// NFTs featured (LEGENDARY ou EPIC) pour le hero banner
  List<NftModel> get featuredNfts => _marketplaceNfts
      .where((n) =>
          n.rarity == NftRarity.LEGENDARY || n.rarity == NftRarity.EPIC)
      .take(8)
      .toList();

  // ── Initialisation ────────────────────────────────────────────────────

  /// Charge les données initiales et démarre le polling.
  Future<void> initialize() async {
    if (_status == MarketplaceStatus.loading) return;
    await _fetchAll();
    _startPolling();
  }

  /// Recharge manuellement (pull-to-refresh)
  Future<void> refresh() => _fetchAll(silent: false);

  // ── Chargement ────────────────────────────────────────────────────────

  Future<void> _fetchAll({bool silent = false}) async {
    if (!silent) {
      _status = MarketplaceStatus.loading;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final core = await Future.wait<List<NftModel>>([
        _api.getMarketplace(),
        _api.getMyNfts(),
      ]);
      _marketplaceNfts = core[0];
      _myNfts = core[1];

      try {
        _transactions = await _api.getTransactionHistory(limit: 15);
      } catch (e) {
        debugPrint('MarketplaceViewModel: transaction history optional fetch failed: $e');
        _transactions = [];
      }

      _status = MarketplaceStatus.loaded;
      _errorMessage = null;
    } catch (e) {
      debugPrint('MarketplaceViewModel._fetchAll error: $e');
      if (!silent) {
        _status = MarketplaceStatus.error;
        _errorMessage = _friendlyError(e);
      }
      // En mode silencieux (polling), on conserve les données existantes
    } finally {
      notifyListeners();
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────

  /// Achète un NFT du marketplace.
  /// Retourne true si succès, false sinon.
  Future<bool> buyNft(NftModel nft) async {
    _isBuying = true;
    notifyListeners();

    try {
      final bought = await _api.buy(nft.id);
      // Retirer du marketplace et ajouter à mes NFTs
      _marketplaceNfts.removeWhere((n) => n.id == nft.id);
      _myNfts.insert(0, bought);
      notifyListeners();
      // Rafraîchir les données complètes en arrière-plan
      _fetchAll(silent: true);
      return true;
    } catch (e) {
      debugPrint('MarketplaceViewModel.buyNft error: $e');
      return false;
    } finally {
      _isBuying = false;
      notifyListeners();
    }
  }

  /// Met un NFT en vente.
  Future<bool> listNftForSale(NftModel nft, double listPrice) async {
    _isListing = true;
    notifyListeners();

    try {
      final updated = await _api.listForSale(nft.id, listPrice);
      _myNfts = _myNfts.map((n) => n.id == updated.id ? updated : n).toList();
      notifyListeners();
      _fetchAll(silent: true);
      return true;
    } catch (e) {
      debugPrint('MarketplaceViewModel.listNftForSale error: $e');
      return false;
    } finally {
      _isListing = false;
      notifyListeners();
    }
  }

  /// Retire un NFT de la vente.
  Future<bool> unlistNft(NftModel nft) async {
    try {
      final updated = await _api.unlist(nft.id);
      _myNfts = _myNfts.map((n) => n.id == updated.id ? updated : n).toList();
      // Retirer du marketplace aussi
      _marketplaceNfts.removeWhere((n) => n.id == updated.id);
      notifyListeners();
      _fetchAll(silent: true);
      return true;
    } catch (e) {
      debugPrint('MarketplaceViewModel.unlistNft error: $e');
      return false;
    }
  }

  // ── Filtres ───────────────────────────────────────────────────────────

  void setTab(MarketplaceTab tab) {
    if (_activeTab == tab) return;
    _activeTab = tab;
    notifyListeners();
  }

  void setFilterRarity(NftRarity? rarity) {
    _filterRarity = rarity;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSortOrder(NftSortOrder order) {
    _sortOrder = order;
    notifyListeners();
  }

  void clearFilters() {
    _filterRarity = null;
    _searchQuery = '';
    _sortOrder = NftSortOrder.priceAsc;
    notifyListeners();
  }

  // ── Polling ───────────────────────────────────────────────────────────

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      debugPrint('MarketplaceViewModel: polling refresh');
      _fetchAll(silent: true);
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  String _friendlyError(Object e) {
    var raw = e.toString();
    if (raw.startsWith('Exception: ')) {
      raw = raw.substring('Exception: '.length);
    }
    final msg = raw.toLowerCase();
    if (msg.contains('socket') ||
        msg.contains('connection') ||
        msg.contains('network') ||
        msg.contains('timeout')) {
      return 'Connexion impossible. Vérifiez votre réseau.';
    }
    if (msg.contains('401') || msg.contains('403')) {
      return 'Session expirée. Reconnectez-vous.';
    }
    // Server often returns JSON `message` (e.g. "Internal server error") — show it if short.
    if (raw.length <= 200 && !msg.contains('formatexception')) {
      return raw;
    }
    return 'Impossible de charger le marketplace.';
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
