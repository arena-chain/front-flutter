import 'package:arena_chain_flutter/navigation.dart';
import 'package:arena_chain_flutter/screens/feature_auth/viewmodel/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CheckInAgentDashboardScreen extends StatefulWidget {
  const CheckInAgentDashboardScreen({super.key});

  @override
  State<CheckInAgentDashboardScreen> createState() =>
      _CheckInAgentDashboardScreenState();
}

class _CheckInAgentDashboardScreenState
    extends State<CheckInAgentDashboardScreen> {
  int _currentIndex = 0;
  static const List<_BookedTicket> _mockBookedTickets = [
    _BookedTicket(
      id: 'TCK-10021',
      eventName: 'Arena Championship - Day 1',
      holderName: 'Sami Trabelsi',
      seat: 'A-14',
      status: 'Booked',
    ),
    _BookedTicket(
      id: 'TCK-10022',
      eventName: 'Arena Championship - Day 1',
      holderName: 'Ines Ben Ali',
      seat: 'A-15',
      status: 'Booked',
    ),
    _BookedTicket(
      id: 'TCK-10031',
      eventName: 'Valorant Qualifiers',
      holderName: 'Youssef K.',
      seat: 'C-07',
      status: 'Checked In',
    ),
    _BookedTicket(
      id: 'TCK-10047',
      eventName: 'FIFA Showmatch',
      holderName: 'Mariam H.',
      seat: 'B-03',
      status: 'Booked',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;

    final pages = <Widget>[
      _HomeTab(
        nickname: user?.nickname ?? 'Agent',
        bookedTickets: _mockBookedTickets,
      ),
      const _ScannerTab(),
      _AccountTab(
        nickname: user?.nickname ?? 'Agent',
        email: user?.email ?? 'No email',
        role: user?.role ?? 'check-in-agent',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-in Agent'),
      ),
      drawer: _CheckInAgentSideDrawer(
        selectedIndex: _currentIndex,
        onSelect: (index) {
          setState(() => _currentIndex = index);
          Navigator.pop(context);
        },
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}

class _CheckInAgentSideDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  const _CheckInAgentSideDrawer({
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthViewModel>().currentUser;
    final nickname = user?.nickname ?? 'Agent';
    final initial = nickname.isNotEmpty ? nickname[0].toUpperCase() : 'A';

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(nickname),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              child: Text(initial),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Home'),
            selected: selectedIndex == 0,
            onTap: () => onSelect(0),
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_scanner),
            title: const Text('Scanner'),
            selected: selectedIndex == 1,
            onTap: () => onSelect(1),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Account'),
            selected: selectedIndex == 2,
            onTap: () => onSelect(2),
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Logout'),
            onTap: () async {
              await context.read<AuthViewModel>().logout();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (route) => false,
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final String nickname;
  final List<_BookedTicket> bookedTickets;
  const _HomeTab({required this.nickname, required this.bookedTickets});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Welcome $nickname',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        const Text(
          'Dedicated dashboard for check-in-agent role.',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 24),
        Card(
          child: ListTile(
            leading: const Icon(Icons.confirmation_num_outlined),
            title: const Text('Ticket Validation Queue'),
            subtitle: Text(
              '${bookedTickets.where((t) => t.status == 'Booked').length} booked tickets waiting',
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Booked Tickets',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ...bookedTickets.map(
          (ticket) => Card(
            child: ListTile(
              leading: Icon(
                ticket.status == 'Checked In'
                    ? Icons.verified
                    : Icons.confirmation_number_outlined,
                color: ticket.status == 'Checked In'
                    ? Colors.green
                    : Colors.orangeAccent,
              ),
              title: Text('${ticket.holderName} • ${ticket.eventName}'),
              subtitle: Text('Ticket ${ticket.id} • Seat ${ticket.seat}'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: ticket.status == 'Checked In'
                      ? Colors.green.withValues(alpha: 0.18)
                      : Colors.orange.withValues(alpha: 0.18),
                ),
                child: Text(
                  ticket.status,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: ticket.status == 'Checked In'
                        ? Colors.green.shade300
                        : Colors.orange.shade300,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BookedTicket {
  final String id;
  final String eventName;
  final String holderName;
  final String seat;
  final String status;

  const _BookedTicket({
    required this.id,
    required this.eventName,
    required this.holderName,
    required this.seat,
    required this.status,
  });
}

class _ScannerTab extends StatelessWidget {
  const _ScannerTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.qr_code_scanner, size: 42),
                SizedBox(height: 12),
                Text(
                  'Scanner module placeholder',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text(
                  'Next: connect camera scanner + POST /api/tickets/validate.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountTab extends StatelessWidget {
  final String nickname;
  final String email;
  final String role;

  const _AccountTab({
    required this.nickname,
    required this.email,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'My Account',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nickname: $nickname'),
                const SizedBox(height: 8),
                Text('Email: $email'),
                const SizedBox(height: 8),
                Text('Role: $role'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
