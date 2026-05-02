import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/core/models/nft_model.dart';
import 'package:arena_chain_flutter/screens/player/feature_marketplace/viewmodel/marketplace_viewmodel.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with SingleTickerProviderStateMixin {
  static const Color _neon = Color(0xFF39FF14);
  static const Color _surface = Color(0xFF111214);
  static const Color _bg = Color(0xFF0A0A0A);

  late TabController _tabController;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      final vm = context.read<MarketplaceViewModel>();
      vm.setTab(_tabController.index == 0
          ? MarketplaceTab.marketplace
          : MarketplaceTab.myNfts);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketplaceViewModel>().initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'NFT Marketplace',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          Consumer<MarketplaceViewModel>(
            builder: (context2, vm, child) => IconButton(
              icon: Icon(Icons.refresh_rounded, color: _neon.withValues(alpha: 0.9)),
              onPressed: vm.isLoading ? null : () => vm.refresh(),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _neon,
          labelColor: _neon,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.store_rounded, size: 18), text: 'Marketplace'),
            Tab(icon: Icon(Icons.diamond_rounded, size: 18), text: 'Mes NFTs'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: Consumer<MarketplaceViewModel>(
              builder: (context2, vm, child) => _buildBody(vm),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Consumer<MarketplaceViewModel>(
      builder: (context2, vm, child) => Container(
        color: Colors.black,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          children: [
            // Search bar
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(Icons.search, color: Colors.white38, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Rechercher un NFT...',
                        hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: vm.setSearchQuery,
                    ),
                  ),
                  if (vm.searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchCtrl.clear();
                        vm.setSearchQuery('');
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(Icons.close, color: Colors.white38, size: 16),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Rarity filter chips
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _rarityChip(vm, null, 'Tous'),
                  ...NftRarity.values.map((r) => _rarityChip(vm, r, r.label)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rarityChip(MarketplaceViewModel vm, NftRarity? rarity, String label) {
    final selected = vm.filterRarity == rarity;
    final color = rarity != null ? _rarityColor(rarity) : _neon;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => vm.setFilterRarity(rarity),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.15) : _surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? color.withValues(alpha: 0.5) : Colors.white12,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? color : Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(MarketplaceViewModel vm) {
    switch (vm.status) {
      case MarketplaceStatus.initial:
      case MarketplaceStatus.loading:
        return _buildSkeleton();
      case MarketplaceStatus.error:
        return _buildError(vm);
      case MarketplaceStatus.loaded:
        return _buildLoaded(vm);
    }
  }

  Widget _buildLoaded(MarketplaceViewModel vm) {
    final nfts = vm.filteredNfts;
    if (nfts.isEmpty) return _buildEmpty(vm);
    return RefreshIndicator(
      color: _neon,
      backgroundColor: _surface,
      onRefresh: vm.refresh,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.68,
        ),
        itemCount: nfts.length,
        itemBuilder: (_, i) => _NftCard(
          nft: nfts[i],
          isMyNft: vm.activeTab == MarketplaceTab.myNfts,
          onBuy: () => _confirmBuy(vm, nfts[i]),
          onList: () => _showListModal(vm, nfts[i]),
          onUnlist: () => vm.unlistNft(nfts[i]),
        ),
      ),
    );
  }

  Widget _buildEmpty(MarketplaceViewModel vm) {
    return RefreshIndicator(
      color: _neon,
      backgroundColor: _surface,
      onRefresh: vm.refresh,
      child: ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Center(
            child: Column(
              children: [
                Icon(Icons.store_rounded,
                    size: 56, color: _neon.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                Text(
                  vm.activeTab == MarketplaceTab.marketplace
                      ? 'Aucun NFT disponible'
                      : 'Vous ne possédez aucun NFT',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  vm.activeTab == MarketplaceTab.marketplace
                      ? 'Vérifiez plus tard ou ajustez les filtres.'
                      : 'Achetez des NFTs sur le marketplace.',
                  style: const TextStyle(color: Colors.white38, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(MarketplaceViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 56, color: Colors.red.withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            Text(
              vm.errorMessage ?? 'Erreur réseau',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _neon,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              onPressed: vm.refresh,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.68,
      ),
      itemCount: 6,
      itemBuilder: (context2, index) => _SkeletonCard(),
    );
  }

  void _confirmBuy(MarketplaceViewModel vm, NftModel nft) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.shopping_cart_rounded, color: Color(0xFF39FF14), size: 20),
          SizedBox(width: 8),
          Text('Confirmer l\'achat',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(nft.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('${nft.displayPrice.toStringAsFixed(0)} AC',
                style: TextStyle(color: _neon, fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.white38)),
          ),
          Consumer<MarketplaceViewModel>(
            builder: (context2, v, child) => ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _neon,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: v.isBuying
                  ? null
                  : () async {
                      Navigator.pop(context);
                      final ok = await vm.buyNft(nft);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ok ? 'NFT acheté !' : 'Achat échoué'),
                          backgroundColor: ok ? Colors.green.shade800 : Colors.red.shade800,
                        ));
                      }
                    },
              child: const Text('Acheter', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  void _showListModal(MarketplaceViewModel vm, NftModel nft) {
    final priceCtrl = TextEditingController(
        text: (nft.price * 1.2).toStringAsFixed(0));
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mettre en vente : ${nft.name}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 16),
            const Text('Prix (AC)', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: _neon.withValues(alpha: 0.3))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: _neon)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: _neon,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () async {
                  final price = double.tryParse(priceCtrl.text) ?? 0;
                  if (price <= 0) return;
                  Navigator.pop(context);
                  final ok = await vm.listNftForSale(nft, price);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(ok ? 'NFT mis en vente !' : 'Échec de la mise en vente'),
                      backgroundColor: ok ? Colors.green.shade800 : Colors.red.shade800,
                    ));
                  }
                },
                child: const Text('Confirmer la mise en vente',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── NFT Card ────────────────────────────────────────────────────────────────

class _NftCard extends StatelessWidget {
  final NftModel nft;
  final bool isMyNft;
  final VoidCallback onBuy;
  final VoidCallback onList;
  final VoidCallback onUnlist;

  const _NftCard({
    required this.nft,
    required this.isMyNft,
    required this.onBuy,
    required this.onList,
    required this.onUnlist,
  });

  @override
  Widget build(BuildContext context) {
    final color = _rarityColor(nft.rarity);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111214),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withValues(alpha: 0.15),
                          Colors.black,
                        ],
                      ),
                    ),
                  ),
                  if (nft.imageUrl.isNotEmpty)
                    Image.network(
                      nft.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, err, st) => Icon(
                        Icons.image_not_supported_outlined,
                        color: color.withValues(alpha: 0.4),
                        size: 36,
                      ),
                    ),
                  // Rarity badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        nft.rarity.label,
                        style: TextStyle(
                          color: color,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  if (nft.isListed && isMyNft)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.blue.withValues(alpha: 0.4)),
                        ),
                        child: const Text('En vente',
                            style: TextStyle(color: Colors.lightBlue, fontSize: 9, fontWeight: FontWeight.w700)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nft.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                ),
                if (nft.description.isNotEmpty)
                  Text(
                    nft.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.diamond_rounded,
                            size: 12, color: const Color(0xFF39FF14)),
                        const SizedBox(width: 4),
                        Text(
                          '${nft.displayPrice.toStringAsFixed(0)} AC',
                          style: const TextStyle(
                              color: Color(0xFF39FF14),
                              fontWeight: FontWeight.w800,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildActionButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (!isMyNft) {
      return SizedBox(
        width: double.infinity,
        height: 30,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF39FF14).withValues(alpha: 0.12),
            foregroundColor: const Color(0xFF39FF14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            side: BorderSide(color: const Color(0xFF39FF14).withValues(alpha: 0.3)),
            padding: EdgeInsets.zero,
          ),
          onPressed: onBuy,
          child: const Text('Acheter',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
        ),
      );
    }
    if (nft.isListed) {
      return SizedBox(
        width: double.infinity,
        height: 30,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.withValues(alpha: 0.12),
            foregroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
            padding: EdgeInsets.zero,
          ),
          onPressed: onUnlist,
          child: const Text('Retirer',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      height: 30,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.withValues(alpha: 0.12),
          foregroundColor: Colors.lightBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: BorderSide(color: Colors.blue.withValues(alpha: 0.3)),
          padding: EdgeInsets.zero,
        ),
        onPressed: onList,
        child: const Text('Mettre en vente',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
      ),
    );
  }
}

// ── Skeleton Card ────────────────────────────────────────────────────────────

class _SkeletonCard extends StatefulWidget {
  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context2, anim) => Container(
        decoration: BoxDecoration(
          color: Color.fromRGBO(17, 18, 20, _anim.value + 0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: _anim.value * 0.06),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shimmerBox(height: 12, width: 100),
                  const SizedBox(height: 6),
                  _shimmerBox(height: 10, width: 70),
                  const SizedBox(height: 8),
                  _shimmerBox(height: 28, width: double.infinity),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBox({required double height, required double width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: _anim.value * 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// ── Helper ───────────────────────────────────────────────────────────────────

Color _rarityColor(NftRarity rarity) {
  switch (rarity) {
    case NftRarity.COMMON:
      return Colors.grey;
    case NftRarity.UNCOMMON:
      return const Color(0xFF10B981);
    case NftRarity.RARE:
      return const Color(0xFF38BDF8);
    case NftRarity.EPIC:
      return const Color(0xFF8B5CF6);
    case NftRarity.LEGENDARY:
      return const Color(0xFF39FF14);
    case NftRarity.MYTHIC:
      return const Color(0xFFEF4444);
  }
}
