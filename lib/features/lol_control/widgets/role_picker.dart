import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/services/rift_service.dart';

const _kGold = Color(0xFFC89B3C);
const _kSurface = Color(0xFF111827);
const _kSelectedText = Color(0xFF0A0E1A);

/// LCU path for updating solo-queue position preferences.
const kLcuPositionPreferencesPath =
    '/lol-lobby/v2/lobby/members/localMember/position-preferences';

class _RoleDef {
  final String lcu;
  final String label;
  const _RoleDef(this.lcu, this.label);
}

const _kRoles = <_RoleDef>[
  _RoleDef('TOP', 'TOP'),
  _RoleDef('JUNGLE', 'JGL'),
  _RoleDef('MIDDLE', 'MID'),
  _RoleDef('BOTTOM', 'BOT'),
  _RoleDef('UTILITY', 'SUP'),
  _RoleDef('FILL', 'FILL'),
];

String normalizeLcuRole(String? raw) {
  if (raw == null || raw.isEmpty) return 'UNSELECTED';
  final u = raw.toUpperCase().trim();
  switch (u) {
    case 'TOP':
      return 'TOP';
    case 'JUNGLE':
    case 'JGL':
      return 'JUNGLE';
    case 'MIDDLE':
    case 'MID':
      return 'MIDDLE';
    case 'BOTTOM':
    case 'BOT':
    case 'ADC':
      return 'BOTTOM';
    case 'UTILITY':
    case 'SUP':
    case 'SUPPORT':
      return 'UTILITY';
    case 'FILL':
      return 'FILL';
    case 'UNSELECTED':
      return 'UNSELECTED';
    default:
      return 'UNSELECTED';
  }
}

/// Primary / secondary role selectors for draft & ranked queues (Mimic-style).
class RolePicker extends StatefulWidget {
  final String initialPrimary;
  final String initialSecondary;

  const RolePicker({
    super.key,
    required this.initialPrimary,
    required this.initialSecondary,
  });

  @override
  State<RolePicker> createState() => _RolePickerState();
}

class _RolePickerState extends State<RolePicker> {
  late String _primary;
  late String _secondary;

  @override
  void initState() {
    super.initState();
    _primary = normalizeLcuRole(widget.initialPrimary);
    _secondary = normalizeLcuRole(widget.initialSecondary);
  }

  @override
  void didUpdateWidget(RolePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final np = normalizeLcuRole(widget.initialPrimary);
    final ns = normalizeLcuRole(widget.initialSecondary);
    final op = normalizeLcuRole(oldWidget.initialPrimary);
    final os = normalizeLcuRole(oldWidget.initialSecondary);
    if (np != op || ns != os) {
      setState(() {
        _primary = np;
        _secondary = ns;
      });
    }
  }

  void _sendPreferences() {
    // LCU PUT body uses firstPreference/secondPreference (same as Mimic web), not
    // firstPositionPreference which is only on lobby member state from GET/subscribe.
    context.read<RiftService>().sendLcuRequest(
          'PUT',
          kLcuPositionPreferencesPath,
          {
            'firstPreference': _primary,
            'secondPreference': _secondary,
          },
        );
  }

  void _onPrimaryTap(String lcu) {
    setState(() {
      _primary = lcu;
      if (_secondary == lcu && lcu != 'FILL') {
        _secondary = 'UNSELECTED';
      }
    });
    _sendPreferences();
  }

  void _onSecondaryTap(String lcu) {
    setState(() {
      _secondary = lcu;
      if (_primary == lcu && lcu != 'FILL') {
        _primary = 'UNSELECTED';
      }
    });
    _sendPreferences();
  }

  Widget _roleButtonRow({
    required String selectedLcu,
    required void Function(String lcu) onTap,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            for (final r in _kRoles)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _RoleChip(
                    label: r.label,
                    selected: selectedLcu == r.lcu,
                    onTap: () => onTap(r.lcu),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _kSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _kGold.withValues(alpha: 0.3)),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Position Preferences',
              style: TextStyle(
                color: _kGold,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Primary',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(height: 8),
            _roleButtonRow(
              selectedLcu: _primary == 'UNSELECTED' ? '' : _primary,
              onTap: _onPrimaryTap,
            ),
            const SizedBox(height: 16),
            Text(
              'Secondary',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(height: 8),
            _roleButtonRow(
              selectedLcu: _secondary == 'UNSELECTED' ? '' : _secondary,
              onTap: _onSecondaryTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const unselectedBg = Color(0xFF0A0E1A);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
          decoration: BoxDecoration(
            color: selected ? _kGold : unselectedBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? _kGold : Colors.white.withValues(alpha: 0.12),
            ),
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: selected ? _kSelectedText : Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
