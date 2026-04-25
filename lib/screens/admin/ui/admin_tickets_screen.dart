import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/core/api/feature_ticketing/ticketing_api.dart';
import 'package:arena_chain_flutter/core/models/feature_ticketing/ticketing_models.dart';

class AdminTicketsScreen extends StatefulWidget {
  const AdminTicketsScreen({super.key});

  @override
  State<AdminTicketsScreen> createState() => _AdminTicketsScreenState();
}

class _AdminTicketsScreenState extends State<AdminTicketsScreen> {
  final TicketingApi _api = TicketingApi();
  bool _loading = true;
  bool _saving = false;
  List<EventModel> _events = [];
  String? _selectedTournamentId;
  List<TournamentTicketType> _ticketTypes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool _isAllowedAdminType(TournamentTicketType t) {
    final name = t.name.trim().toUpperCase();
    if (name.isEmpty) return false;
    if (name == 'VIP' || name == 'ELITE') return false;
    return true;
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final events = await _api.getEvents('all');
      setState(() {
        _events = events;
        if (_events.isNotEmpty) {
          _selectedTournamentId ??= _events.first.id;
          _hydrateTicketTypes();
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _hydrateTicketTypes() {
    final event = _events.firstWhere(
      (e) => e.id == _selectedTournamentId,
      orElse: () => _events.first,
    );
    _ticketTypes = event.ticketTypesList.where(_isAllowedAdminType).toList();
    if (_ticketTypes.isEmpty) {
      _ticketTypes = const [
        TournamentTicketType(name: 'STANDARD', price: 0, capacity: 100, isNft: false),
      ];
    }
  }

  void _addType() {
    setState(() {
      _ticketTypes = [
        ..._ticketTypes,
        const TournamentTicketType(name: 'STANDARD', price: 0, capacity: 100, isNft: false),
      ];
    });
  }

  void _updateType(int index, TournamentTicketType value) {
    final copy = [..._ticketTypes];
    copy[index] = value;
    setState(() => _ticketTypes = copy);
  }

  Future<void> _save() async {
    if (_selectedTournamentId == null) return;
    setState(() => _saving = true);
    try {
      final ok = await _api.addTicketTypesToTournament(_selectedTournamentId!, _ticketTypes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ok ? const Color(0xFF00FF87) : Colors.redAccent,
          content: Text(
            ok ? 'Ticket types saved.' : 'Failed to save ticket types.',
            style: TextStyle(
              color: ok ? Colors.black : Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
      if (ok) await _load();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00FF87)),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ticket Management (STANDARD + NFT)',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedTournamentId,
            dropdownColor: const Color(0xFF1A1F36),
            decoration: const InputDecoration(
              filled: true,
              fillColor: Color(0xFF111111),
              labelText: 'Tournament',
              labelStyle: TextStyle(color: Colors.white70),
              border: OutlineInputBorder(),
            ),
            items: _events
                .map((e) => DropdownMenuItem(value: e.id, child: Text(e.name)))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedTournamentId = value;
                _hydrateTicketTypes();
              });
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(
                onPressed: _addType,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF87)),
                child: const Text('+ ADD TYPE', style: TextStyle(color: Colors.black)),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF87)),
                child: Text(
                  _saving ? 'Saving...' : 'SAVE',
                  style: const TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _ticketTypes.length,
              itemBuilder: (context, index) {
                final t = _ticketTypes[index];
                return _TicketTypeCard(
                  key: ValueKey('${t.name}-$index'),
                  type: t,
                  onChanged: (next) => _updateType(index, next),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketTypeCard extends StatelessWidget {
  final TournamentTicketType type;
  final ValueChanged<TournamentTicketType> onChanged;

  const _TicketTypeCard({super.key, required this.type, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isNft = type.isNft || type.name.toUpperCase().contains('NFT');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: type.name,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  onChanged: (v) => onChanged(TournamentTicketType(
                    name: v.trim().isEmpty ? 'STANDARD' : v,
                    price: type.price,
                    capacity: type.capacity,
                    isNft: isNft,
                  )),
                ),
              ),
              const SizedBox(width: 10),
              ChoiceChip(
                label: Text(isNft ? 'NFT' : 'STANDARD'),
                selected: isNft,
                onSelected: (selected) => onChanged(
                  TournamentTicketType(
                    name: selected ? 'VIP NFT' : 'STANDARD',
                    price: type.price,
                    capacity: type.capacity,
                    isNft: selected,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: type.price.toStringAsFixed(0),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  onChanged: (v) => onChanged(TournamentTicketType(
                    name: type.name,
                    price: double.tryParse(v) ?? type.price,
                    capacity: type.capacity,
                    isNft: isNft,
                  )),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  initialValue: type.capacity.toString(),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Capacity',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  onChanged: (v) => onChanged(TournamentTicketType(
                    name: type.name,
                    price: type.price,
                    capacity: int.tryParse(v) ?? type.capacity,
                    isNft: isNft,
                  )),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
