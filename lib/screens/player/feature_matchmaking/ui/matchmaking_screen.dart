import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:arena_chain_flutter/screens/player/feature_matchmaking/view_model/matchmaking_view_model.dart';
import 'package:arena_chain_flutter/navigation.dart';

class MatchmakingScreen extends StatelessWidget {
  const MatchmakingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MatchmakingScreenBody();
  }
}

class _MatchmakingScreenBody extends StatelessWidget {
  const _MatchmakingScreenBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<MatchmakingViewModel>(
      builder: (context, vm, _) {
        final canToggleSchedule = vm.status == MatchmakingStatus.idle ||
            vm.status == MatchmakingStatus.error ||
            vm.status == MatchmakingStatus.cancelled ||
            vm.status == MatchmakingStatus.expired;

        return Scaffold(
          backgroundColor: const Color(0xFF0A0E1A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0A0E1A),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Matchmaking',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              if (canToggleSchedule)
                IconButton(
                  onPressed: () => vm.toggleScheduleMode(),
                  icon: Icon(
                    Icons.schedule,
                    color: vm.isScheduleMode
                        ? const Color(0xFF00FF00)
                        : const Color(0xFF7A86AC),
                  ),
                  tooltip: 'Schedule match',
                ),
            ],
          ),
          body: _buildBody(context, vm),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, MatchmakingViewModel vm) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGameAccountSelector(context, vm),
          const SizedBox(height: 24),
          _buildModeSelector(vm),
          const SizedBox(height: 24),
          _buildServerSelector(vm),
          const SizedBox(height: 24),
          _buildRegionSelector(vm),
          if (vm.isScheduleMode &&
              (vm.status == MatchmakingStatus.idle ||
                  vm.status == MatchmakingStatus.error ||
                  vm.status == MatchmakingStatus.cancelled ||
                  vm.status == MatchmakingStatus.expired)) ...[
            const SizedBox(height: 24),
            _buildSchedulePicker(context, vm),
          ],
          const SizedBox(height: 40),
          _buildActionArea(context, vm),
          if (vm.errorMessage != null) ...[
            const SizedBox(height: 16),
            _buildErrorMessage(vm.errorMessage!),
          ],
          if (vm.status == MatchmakingStatus.cancelled) ...[
            const SizedBox(height: 16),
            _buildInfoMessage('Match was cancelled. Try again!'),
          ],
          if (vm.status == MatchmakingStatus.expired) ...[
            const SizedBox(height: 16),
            _buildInfoMessage(
                'Match expired — not all players accepted in time. Try again!'),
          ],
        ],
      ),
    );
  }

  // ── Connected Game Account selector ───────────────────────────────────

  Widget _buildGameAccountSelector(
      BuildContext context, MatchmakingViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Game',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (vm.isLoadingLinkStatus)
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
        else if (vm.linkStatus == 'verified' && vm.connectedAccount != null)
          _buildConnectedAccountCard(context, vm)
        else
          _buildNoAccountCard(context),
      ],
    );
  }

  Widget _buildConnectedAccountCard(
      BuildContext context, MatchmakingViewModel vm) {
    final account = vm.connectedAccount!;
    final isSelected = vm.isAccountSelected;

    return GestureDetector(
      onTap: vm.status == MatchmakingStatus.idle
          ? () {
              if (isSelected) {
                vm.deselectAccount();
              } else {
                vm.selectAccount(account);
              }
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1221),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00FF00)
                : const Color(0xFF1A1F36),
            width: isSelected ? 2 : 1,
          ),
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
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF00FF00)
                      : const Color(0xFFC89B3C),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: account.originalIconId != null &&
                        account.originalIconId! > 0
                    ? Image.network(
                        'https://ddragon.leagueoflegends.com/cdn/14.1.1/img/profileicon/${account.originalIconId}.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
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
                      )
                    : const Center(
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
                      Icon(
                        Icons.verified,
                        color: isSelected
                            ? const Color(0xFF00FF00)
                            : const Color(0xFF7A86AC),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${account.riotGameName}#${account.riotTagLine}',
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFF00FF00)
                              : const Color(0xFF7A86AC),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    account.serverLabel,
                    style: const TextStyle(
                      color: Color(0xFF7A86AC),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF00FF00))
            else
              const Icon(Icons.radio_button_unchecked,
                  color: Color(0xFF7A86AC)),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAccountCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.myAccount);
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
            Icon(Icons.link_off,
                color: Colors.white.withOpacity(0.2), size: 40),
            const SizedBox(height: 12),
            const Text(
              'No connected game account found.\nLink your account on your profile first.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF7A86AC),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
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

  // ── Mode selector ─────────────────────────────────────────────────────

  Widget _buildModeSelector(MatchmakingViewModel vm) {
    final modes = [
      {'label': '1v1', 'code': 'CUSTOM_1V1', 'players': '2 Players'},
      {'label': '2v2', 'code': 'CUSTOM_2V2', 'players': '4 Players'},
      {'label': '5v5', 'code': 'CUSTOM_5V5', 'players': '10 Players'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Match Mode',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: modes.map((mode) {
            final isSelected = vm.selectedMode == mode['code'];
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: mode != modes.last ? 10 : 0,
                ),
                child: GestureDetector(
                  onTap: vm.status == MatchmakingStatus.idle
                      ? () {
                          vm.selectedMode = mode['code']!;
                          vm.notifyListeners();
                        }
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF00FF00).withOpacity(0.1)
                          : const Color(0xFF0F1221),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF00FF00)
                            : const Color(0xFF1A1F36),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          mode['label']!,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF00FF00)
                                : Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mode['players']!,
                          style: const TextStyle(
                            color: Color(0xFF7A86AC),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Server selector (renamed from Region) ─────────────────────────────

  Widget _buildServerSelector(MatchmakingViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Server',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1221),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1A1F36)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: MatchmakingViewModel.servers.contains(vm.selectedServer)
                  ? vm.selectedServer
                  : MatchmakingViewModel.servers.first,
              isExpanded: true,
              dropdownColor: const Color(0xFF0F1221),
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: Color(0xFF7A86AC)),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              items: MatchmakingViewModel.servers.map((server) {
                return DropdownMenuItem(
                  value: server,
                  child: Text(server),
                );
              }).toList(),
              onChanged: vm.status == MatchmakingStatus.idle
                  ? (value) {
                      if (value != null) {
                        vm.selectedServer = value;
                        vm.notifyListeners();
                      }
                    }
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  // ── Region selector (country/player region) ───────────────────────────

  Widget _buildRegionSelector(MatchmakingViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Region',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1221),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1A1F36)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: vm.selectedPlayerRegion,
              isExpanded: true,
              dropdownColor: const Color(0xFF0F1221),
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: Color(0xFF7A86AC)),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              items: MatchmakingViewModel.playerRegions.map((region) {
                return DropdownMenuItem(
                  value: region,
                  child: Text(region),
                );
              }).toList(),
              onChanged: vm.status == MatchmakingStatus.idle
                  ? (value) {
                      if (value != null) {
                        vm.selectedPlayerRegion = value;
                        vm.notifyListeners();
                      }
                    }
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  // ── Schedule picker ───────────────────────────────────────────────────

  Widget _buildSchedulePicker(BuildContext context, MatchmakingViewModel vm) {
    final hasTime = vm.scheduledTime != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.schedule, color: Color(0xFF00FF00), size: 20),
            SizedBox(width: 8),
            Text(
              'Schedule Time',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _pickDateTime(context, vm),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1221),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasTime
                    ? const Color(0xFF00FF00).withOpacity(0.5)
                    : const Color(0xFF1A1F36),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: hasTime
                      ? const Color(0xFF00FF00)
                      : const Color(0xFF7A86AC),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasTime
                        ? DateFormat('EEE, MMM d  ·  HH:mm')
                            .format(vm.scheduledTime!)
                        : 'Tap to pick date & time',
                    style: TextStyle(
                      color:
                          hasTime ? Colors.white : const Color(0xFF7A86AC),
                      fontSize: 15,
                      fontWeight:
                          hasTime ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                if (hasTime)
                  GestureDetector(
                    onTap: () => vm.clearScheduledTime(),
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFF7A86AC),
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDateTime(
      BuildContext context, MatchmakingViewModel vm) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: vm.scheduledTime ?? now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 7)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00FF00),
            onPrimary: Colors.black,
            surface: Color(0xFF0F1221),
            onSurface: Colors.white,
          ),
          dialogBackgroundColor: const Color(0xFF0F1221),
        ),
        child: child!,
      ),
    );

    if (pickedDate == null || !context.mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        vm.scheduledTime ?? now.add(const Duration(hours: 1)),
      ),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00FF00),
            onPrimary: Colors.black,
            surface: Color(0xFF0F1221),
            onSurface: Colors.white,
          ),
          dialogBackgroundColor: const Color(0xFF0F1221),
        ),
        child: child!,
      ),
    );

    if (pickedTime == null) return;

    final scheduled = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (scheduled.isBefore(DateTime.now())) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please choose a future time'),
            backgroundColor: Color(0xFFFF4444),
          ),
        );
      }
      return;
    }

    vm.setScheduledTime(scheduled);
  }

  // ── Action area (button / status) ─────────────────────────────────────

  Widget _buildActionArea(BuildContext context, MatchmakingViewModel vm) {
    switch (vm.status) {
      case MatchmakingStatus.idle:
      case MatchmakingStatus.error:
      case MatchmakingStatus.cancelled:
      case MatchmakingStatus.expired:
        return _buildFindMatchButton(vm);
      case MatchmakingStatus.searching:
        return _buildSearchingState(vm);
      case MatchmakingStatus.scheduled:
        return _buildScheduledState(vm);
      case MatchmakingStatus.pendingAcceptance:
        return _buildPendingState();
      case MatchmakingStatus.accepted:
        return _buildAcceptedState(vm);
    }
  }

  Widget _buildFindMatchButton(MatchmakingViewModel vm) {
    final isScheduled = vm.isScheduleMode && vm.scheduledTime != null;
    final canPress = !vm.isLoading &&
        (!vm.isScheduleMode || vm.scheduledTime != null) &&
        vm.isAccountSelected;

    return Column(
      children: [
        if (!vm.isAccountSelected &&
            vm.linkStatus == 'verified' &&
            vm.connectedAccount != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.orangeAccent, size: 16),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Please select your game account above to continue',
                      style: TextStyle(
                          color: Colors.orangeAccent, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: canPress ? () => vm.startSearch() : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isScheduled
                  ? const Color(0xFF00CCFF)
                  : const Color(0xFF00FF00),
              foregroundColor: Colors.black,
              disabledBackgroundColor: const Color(0xFF1A1F36),
              disabledForegroundColor: const Color(0xFF7A86AC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: vm.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(isScheduled ? Icons.schedule : Icons.search,
                          size: 24),
                      const SizedBox(width: 8),
                      Text(
                        isScheduled ? 'Schedule Match' : 'Find Match',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // ── Scheduled state ───────────────────────────────────────────────────

  Widget _buildScheduledState(MatchmakingViewModel vm) {
    final hours = vm.timeRemaining.inHours;
    final minutes = vm.timeRemaining.inMinutes.remainder(60);
    final seconds = vm.timeRemaining.inSeconds.remainder(60);
    final countdownText =
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1221),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF00CCFF).withOpacity(0.4),
            ),
          ),
          child: Column(
            children: [
              const Icon(Icons.schedule, color: Color(0xFF00CCFF), size: 40),
              const SizedBox(height: 12),
              const Text(
                'Match Scheduled',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              if (vm.scheduledTime != null)
                Text(
                  DateFormat('EEE, MMM d  ·  HH:mm')
                      .format(vm.scheduledTime!),
                  style: const TextStyle(
                    color: Color(0xFF7A86AC),
                    fontSize: 14,
                  ),
                ),
              const SizedBox(height: 20),
              const Text(
                'Starts in',
                style: TextStyle(color: Color(0xFF7A86AC), fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                countdownText,
                style: const TextStyle(
                  color: Color(0xFF00CCFF),
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00CCFF).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline,
                        color: Color(0xFF00CCFF), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Matchmaking will start automatically',
                      style:
                          TextStyle(color: Color(0xFF00CCFF), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: vm.isLoading ? null : () => vm.cancelSearch(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFF4444),
              side: const BorderSide(color: Color(0xFFFF4444)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Cancel Schedule',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  // ── Searching state ───────────────────────────────────────────────────

  Widget _buildSearchingState(MatchmakingViewModel vm) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1221),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF00FF00).withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  color: Color(0xFF00FF00),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Searching for players...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ELO: ${vm.ticket?.elo ?? "~"}',
                style: const TextStyle(
                  color: Color(0xFF7A86AC),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: vm.isLoading ? null : () => vm.cancelSearch(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFF4444),
              side: const BorderSide(color: Color(0xFFFF4444)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Cancel Search',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  // ── Pending acceptance (inline indicator) ─────────────────────────────

  Widget _buildPendingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1221),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orangeAccent.withOpacity(0.5),
        ),
      ),
      child: const Column(
        children: [
          Icon(Icons.hourglass_top, color: Colors.orangeAccent, size: 40),
          SizedBox(height: 12),
          Text(
            'Waiting for all players to accept...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Accepted (inline room code) ───────────────────────────────────────

  Widget _buildAcceptedState(MatchmakingViewModel vm) {
    final roomId = vm.activeGame?.roomInfo?.roomId ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1221),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00FF00).withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF00FF00), size: 48),
          const SizedBox(height: 12),
          const Text(
            'Match Ready!',
            style: TextStyle(
              color: Color(0xFF00FF00),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Room ID',
            style: TextStyle(color: Color(0xFF7A86AC), fontSize: 14),
          ),
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F36),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              roomId,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (ctx) => TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: roomId));
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Room ID copied!'),
                    backgroundColor: Color(0xFF00FF00),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.copy,
                  color: Color(0xFF00FF00), size: 18),
              label: const Text(
                'Copy to Clipboard',
                style: TextStyle(color: Color(0xFF00FF00)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Map: ${vm.activeGame?.roomInfo?.map ?? "Summoner\'s Rift"}',
            style:
                const TextStyle(color: Color(0xFF7A86AC), fontSize: 14),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline,
                    color: Colors.orangeAccent, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Open LoL on your PC > Join Custom Game > use this ID as the room name.',
                    style:
                        TextStyle(color: Colors.orangeAccent, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  Widget _buildErrorMessage(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF4444).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFFFF4444), fontSize: 13),
      ),
    );
  }

  Widget _buildInfoMessage(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.orangeAccent, fontSize: 13),
        textAlign: TextAlign.center,
      ),
    );
  }
}
