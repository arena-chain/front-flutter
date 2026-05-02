import 'dart:async';
import 'dart:convert';
import 'package:arena_chain_flutter/core/api/tickets_api.dart';
import 'package:arena_chain_flutter/core/models/ticket_model.dart';
import 'package:arena_chain_flutter/navigation.dart';
import 'package:arena_chain_flutter/screens/feature_auth/viewmodel/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

// ─── Theme constants ────────────────────────────────────────────────
const _bg = Color(0xFF0D0D0D);
const _surface = Color(0xFF111111);
const _border = Color(0xFF1E1E1E);
const _green = Color(0xFF39D353);
const _greenDim = Color(0xFF0F1F0F);
const _greenBorder = Color(0xFF1E3A1E);
const _amber = Color(0xFFF59E0B);
const _amberDim = Color(0xFF1A1500);
const _amberBorder = Color(0xFF2A2000);
const _textPrimary = Color(0xFFDDDDDD);
const _textMuted = Color(0xFF555555);
const _textDim = Color(0xFF333333);

// ─── Root screen ────────────────────────────────────────────────────
class CheckInAgentDashboardScreen extends StatefulWidget {
  const CheckInAgentDashboardScreen({super.key});

  @override
  State<CheckInAgentDashboardScreen> createState() =>
      _CheckInAgentDashboardScreenState();
}

class _CheckInAgentDashboardScreenState
    extends State<CheckInAgentDashboardScreen> {
  int _currentIndex = 0;
  List<TicketModel>? _tickets;
  final TicketsApi _ticketsApi = TicketsApi();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    try {
      final tickets = await _ticketsApi.getAllTickets();
      if (mounted) setState(() => _tickets = tickets);
    } catch (_) {
      if (mounted) setState(() => _tickets = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;

    final pages = <Widget>[
      _HomeTab(tickets: _tickets, onRefresh: _loadTickets),
      const _ScannerTab(),
      _AccountTab(
        nickname: user?.nickname ?? 'Agent',
        email: user?.email ?? '',
        role: user?.role ?? 'check-in-agent',
      ),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bg,
      appBar: _ArenaAppBar(
        initial: (user?.nickname ?? 'A')[0].toUpperCase(),
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: _SideDrawer(
        selectedIndex: _currentIndex,
        onSelect: (i) {
          setState(() => _currentIndex = i);
          Navigator.pop(context);
        },
      ),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: _ArenaBottomNav(
        selectedIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ─── App bar ────────────────────────────────────────────────────────
class _ArenaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String initial;
  final VoidCallback onMenuTap;
  const _ArenaAppBar({required this.initial, required this.onMenuTap});

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _surface,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _border)),
          ),
          child: Row(
            children: [
              // Minimum ~48dp touch target; the old icon was ~16×17px and often missed taps.
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onMenuTap,
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          3,
                          (_) => Container(
                            width: 16,
                            height: 1.5,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            decoration: BoxDecoration(
                              color: _textMuted,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Check-in Agent',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Bell
              Container(
                width: 30,
                height: 30,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF252525)),
                ),
                child: const Icon(Icons.notifications_outlined,
                    color: _textMuted, size: 15),
              ),
              // Avatar
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: _bg,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Bottom nav ──────────────────────────────────────────────────────
class _ArenaBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const _ArenaBottomNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'HOME',
                active: selectedIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.qr_code_scanner_outlined,
                activeIcon: Icons.qr_code_scanner,
                label: 'SCAN',
                active: selectedIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'ACCOUNT',
                active: selectedIndex == 2,
                onTap: () => onTap(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              active ? activeIcon : icon,
              color: active ? _green : _textDim,
              size: 20,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: active ? _green : _textDim,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.06,
              ),
            ),
            if (active) ...[
              const SizedBox(height: 3),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: _green,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Side drawer ─────────────────────────────────────────────────────
class _SideDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  const _SideDrawer({required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthViewModel>().currentUser;
    final nickname = user?.nickname ?? 'Agent';
    final initial = nickname.isNotEmpty ? nickname[0].toUpperCase() : 'A';

    return Drawer(
      backgroundColor: _surface,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _border)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(initial,
                      style: const TextStyle(
                          color: _bg,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nickname,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    Text(user?.email ?? '',
                        style:
                            const TextStyle(color: _textMuted, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          _DrawerItem(
            icon: Icons.home_outlined,
            label: 'Home',
            selected: selectedIndex == 0,
            onTap: () => onSelect(0),
          ),
          _DrawerItem(
            icon: Icons.qr_code_scanner_outlined,
            label: 'Scanner',
            selected: selectedIndex == 1,
            onTap: () => onSelect(1),
          ),
          _DrawerItem(
            icon: Icons.person_outline,
            label: 'Account',
            selected: selectedIndex == 2,
            onTap: () => onSelect(2),
          ),
          const Spacer(),
          _DrawerItem(
            icon: Icons.logout,
            label: 'Logout',
            selected: false,
            danger: true,
            onTap: () async {
              await context.read<AuthViewModel>().logout();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                  context, AppRoutes.login, (_) => false);
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool danger;
  final VoidCallback onTap;
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? Colors.redAccent
        : selected
            ? _green
            : _textMuted;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _greenDim : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? _greenBorder : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ─── Home tab ────────────────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  final List<TicketModel>? tickets;
  final Future<void> Function() onRefresh;
  const _HomeTab({required this.tickets, required this.onRefresh});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  String _filter = 'all'; // all | booked | used
  String _search = '';

  List<TicketModel> get _filtered {
    final all = widget.tickets ?? [];
    return all.where((t) {
      final matchFilter = _filter == 'all'
          ? true
          : _filter == 'booked'
              ? t.status == TicketStatus.VALID
              : t.status == TicketStatus.USED;
      final q = _search.toLowerCase();
      final matchSearch = q.isEmpty ||
          t.ticketNumber.toLowerCase().contains(q) ||
          t.userName.toLowerCase().contains(q) ||
          t.userId.toLowerCase().contains(q);
      return matchFilter && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tickets == null) {
      return const Center(child: CircularProgressIndicator(color: _green));
    }

    final tickets = widget.tickets!;
    final total = tickets.length;
    final booked = tickets.where((t) => t.status == TicketStatus.VALID).length;
    final used = tickets.where((t) => t.status == TicketStatus.USED).length;
    final filtered = _filtered;

    return RefreshIndicator(
      color: _green,
      backgroundColor: _surface,
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // ── Title row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'TICKET\nMANAGEMENT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    height: 1.05,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      // navigate to scanner tab
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.qr_code_scanner,
                              color: _bg, size: 13),
                          SizedBox(width: 5),
                          Text(
                            'SCAN QR',
                            style: TextStyle(
                              color: _bg,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.05,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  GestureDetector(
                    onTap: widget.onRefresh,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: _greenBorder),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Refresh',
                        style: TextStyle(
                          color: _green,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Stats row
          Row(
            children: [
              _StatCard(label: 'Total', value: '$total', accent: false),
              const SizedBox(width: 7),
              _StatCard(label: 'Booked', value: '$booked', accent: true),
              const SizedBox(width: 7),
              _StatCard(
                  label: 'Used',
                  value: '$used',
                  accent: false,
                  dim: used == 0),
            ],
          ),
          const SizedBox(height: 14),

          // ── Filter tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterTab(
                  label: 'All',
                  icon: Icons.people_outline,
                  active: _filter == 'all',
                  onTap: () => setState(() => _filter = 'all'),
                ),
                const SizedBox(width: 6),
                _FilterTab(
                  label: 'Booked',
                  icon: Icons.confirmation_num_outlined,
                  active: _filter == 'booked',
                  onTap: () => setState(() => _filter = 'booked'),
                ),
                const SizedBox(width: 6),
                _FilterTab(
                  label: 'Used',
                  icon: Icons.check_circle_outline,
                  active: _filter == 'used',
                  onTap: () => setState(() => _filter = 'used'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Search bar
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _surface,
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: _textDim, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: _textMuted, fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'Search ticket or holder ID...',
                      hintStyle:
                          TextStyle(color: Color(0xFF2E2E2E), fontSize: 12),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    border: Border.all(color: const Color(0xFF252525)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.tune, color: _textMuted, size: 11),
                      SizedBox(width: 4),
                      Text('Filter',
                          style:
                              TextStyle(color: _textMuted, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Ticket table
          Container(
            decoration: BoxDecoration(
              color: _surface,
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Table header
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: _border)),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                          child: _TableHeadCell('Ticket / Holder')),
                      SizedBox(
                          width: 80,
                          child: _TableHeadCell('Status')),
                      SizedBox(width: 32),
                    ],
                  ),
                ),

                // Rows
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No tickets found',
                      style: TextStyle(color: _textMuted, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ...filtered.asMap().entries.map((e) {
                    final i = e.key;
                    final t = e.value;
                    return _TicketRow(
                      ticket: t,
                      isLast: i == filtered.length - 1,
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final bool accent;
  final bool dim;
  const _StatCard({
    required this.label,
    required this.value,
    required this.accent,
    this.dim = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        decoration: BoxDecoration(
          color: _surface,
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF383838),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.08,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                color: dim
                    ? const Color(0xFF2A2A2A)
                    : accent
                        ? _green
                        : Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _FilterTab({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? _green : Colors.transparent,
          border: Border.all(color: active ? _green : _border),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 11,
                color: active ? _bg : _textMuted),
            const SizedBox(width: 4),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: active ? _bg : _textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.04,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeadCell extends StatelessWidget {
  final String text;
  const _TableHeadCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFF2E2E2E),
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.08,
      ),
    );
  }
}

class _TicketRow extends StatelessWidget {
  final TicketModel ticket;
  final bool isLast;
  const _TicketRow({required this.ticket, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final isUsed = ticket.status == TicketStatus.USED;
    final eventName = ticket.tournament?.name ??
        ticket.league?.name ??
        'Event';
    final holderName = ticket.userName != 'Unknown User' ? ticket.userName : (ticket.userId.length > 8
        ? ticket.userId.substring(0, 8)
        : ticket.userId);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFF161616))),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: _greenDim,
              border: Border.all(color: _greenBorder),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline,
                color: _green, size: 14),
          ),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$holderName · $eventName',
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  ticket.ticketNumber,
                  style: const TextStyle(
                    color: _textDim,
                    fontSize: 9,
                    fontFamily: 'monospace',
                    letterSpacing: 0.02,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Badge
          SizedBox(
            width: 68,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: isUsed ? _greenDim : _amberDim,
                border: Border.all(
                    color: isUsed ? _greenBorder : _amberBorder),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isUsed ? 'USED' : 'BOOKED',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isUsed ? _green : _amber,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.04,
                ),
              ),
            ),
          ),

          const SizedBox(width: 6),

          // Dots
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: const Text(
              '···',
              style: TextStyle(
                color: Color(0xFF3A3A3A),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Scanner tab ─────────────────────────────────────────────────────
class _ScannerTab extends StatefulWidget {
  const _ScannerTab();

  @override
  State<_ScannerTab> createState() => _ScannerTabState();
}

class _ScannerTabState extends State<_ScannerTab> {
  final TicketsApi _api = TicketsApi();
  bool _isProcessing = false;
  final MobileScannerController _camera = MobileScannerController();
  Map<String, dynamic>? _scanResult;
  Timer? _resultTimer;

  Future<void> _handleScan(BarcodeCapture capture) async {
    if (_isProcessing || _scanResult != null) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    String ticketNumber;
    try {
      ticketNumber = (jsonDecode(raw) as Map)['ticketNumber'] ?? '';
    } catch (_) {
      ticketNumber = raw;
    }
    if (ticketNumber.isEmpty) return;
    await _processValidation(ticketNumber);
  }

  Future<void> _processValidation(String ticketNumber) async {
    if (_isProcessing || _scanResult != null) return;
    setState(() => _isProcessing = true);
    try {
      final response = await _api.validateTicket(ticketNumber);
      if (!mounted) return;
      setState(() {
        _scanResult = response;
        _isProcessing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scanResult = {
          'success': false,
          'scanStatus': 'NETWORK_ERROR',
          'message': 'Error: $e',
        };
        _isProcessing = false;
      });
    }
    _resultTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _scanResult = null);
    });
  }

  void _showManualEntry() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Manual Entry',
            style: TextStyle(color: Colors.white, fontSize: 15)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter ticket number',
            hintStyle: const TextStyle(color: _textMuted),
            filled: true,
            fillColor: _bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _border),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: _textMuted)),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              if (ctrl.text.trim().isNotEmpty) {
                _processValidation(ctrl.text.trim());
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _green,
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Text('Validate',
                  style: TextStyle(
                      color: _bg,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(
          controller: _camera,
          onDetect: _handleScan,
          errorBuilder: (_, error) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    color: Colors.orange, size: 48),
                const SizedBox(height: 16),
                Text('Scanner error: ${error.errorCode.name}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _showManualEntry,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: _green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Enter Manually',
                        style: TextStyle(
                            color: _bg, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isProcessing)
          Container(
            color: Colors.black54,
            child: const Center(
                child: CircularProgressIndicator(color: _green)),
          ),
        if (_scanResult != null) _buildResultOverlay(),
        if (!_isProcessing && _scanResult == null)
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _border),
                    ),
                    child: const Text('Scan Ticket QR Code',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _showManualEntry,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: _greenBorder),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Enter Manually',
                          style: TextStyle(
                              color: _green,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildResultOverlay() {
    final bool success = _scanResult!['success'] ?? false;
    final String status = _scanResult!['scanStatus'] ?? 'UNKNOWN';
    final String message = _scanResult!['message'] ?? '';

    Color bgColor;
    IconData icon;
    if (success && status == 'CONFIRMED') {
      bgColor = const Color(0xFF0F2A0F);
      icon = Icons.check_circle;
    } else if (status == 'USED') {
      bgColor = const Color(0xFF2A1F00);
      icon = Icons.warning_amber_rounded;
    } else {
      bgColor = const Color(0xFF2A0F0F);
      icon = Icons.error;
    }

    final iconColor = success && status == 'CONFIRMED'
        ? _green
        : status == 'USED'
            ? _amber
            : Colors.redAccent;

    return Container(
      color: bgColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: 72),
              const SizedBox(height: 20),
              Text(
                status,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: iconColor,
                    letterSpacing: 0.04),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: _textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _resultTimer?.cancel();
    _camera.dispose();
    super.dispose();
  }
}

// ─── Account tab ─────────────────────────────────────────────────────
class _AccountTab extends StatelessWidget {
  final String nickname;
  final String email;
  final String role;
  const _AccountTab(
      {required this.nickname, required this.email, required this.role});

  @override
  Widget build(BuildContext context) {
    final initial =
        nickname.isNotEmpty ? nickname[0].toUpperCase() : 'A';

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const Text(
          'MY ACCOUNT',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _green,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                  color: _bg,
                  fontSize: 28,
                  fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: _surface,
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _AccountRow(label: 'Nickname', value: nickname),
              _AccountRow(label: 'Email', value: email),
              _AccountRow(label: 'Role', value: role, isLast: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;
  const _AccountRow(
      {required this.label, required this.value, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(
                  color: _textDim,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.06)),
          const Spacer(),
          Text(value,
              style: const TextStyle(color: _textPrimary, fontSize: 13)),
        ],
      ),
    );
  }
}
