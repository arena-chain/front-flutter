import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/screens/player/feature_tournemets/view_model/tournaments_view_model.dart';
import 'package:arena_chain_flutter/core/models/feature_friends/friend_user_model.dart';

class CreateTournamentScreen extends StatefulWidget {
  const CreateTournamentScreen({super.key});

  @override
  State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _maxTeamsController = TextEditingController();
  final _prizePoolController = TextEditingController();
  
  String? _selectedGameId;
  String? _selectedFormat;
  DateTime? _startDate;
  DateTime? _endDate;
  Set<String> _selectedFriendIds = {};

  @override
  void initState() {
    super.initState();
    // Load games and friends when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<TournamentsViewModel>();
      viewModel.loadFriendsForInvite();
      viewModel.loadGames();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _maxTeamsController.dispose();
    _prizePoolController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00FF00),
              surface: Color(0xFF0F1221),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedGameId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a game'),
          backgroundColor: Color(0xFFFF0055),
        ),
      );
      return;
    }

    if (_selectedFormat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a tournament format'),
          backgroundColor: Color(0xFFFF0055),
        ),
      );
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select start and end dates'),
          backgroundColor: Color(0xFFFF0055),
        ),
      );
      return;
    }

    final viewModel = context.read<TournamentsViewModel>();
    final success = await viewModel.createTournament(
      name: _nameController.text.trim(),
      gameId: _selectedGameId!,
      format: _selectedFormat!,
      startDate: _startDate!,
      endDate: _endDate!,
      maxTeams: int.parse(_maxTeamsController.text.trim()),
      prizePool: _prizePoolController.text.trim().isNotEmpty
          ? _prizePoolController.text.trim()
          : null,
      invitedUserIds: _selectedFriendIds.isNotEmpty
          ? _selectedFriendIds.toList()
          : null,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tournament created successfully!'),
          backgroundColor: Color(0xFF00FF00),
        ),
      );
      Navigator.pop(context);
    } else if (mounted && viewModel.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${viewModel.error}'),
          backgroundColor: const Color(0xFFFF0055),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Create Tournament',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<TournamentsViewModel>(
        builder: (context, viewModel, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF00).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF00FF00).withOpacity(0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emoji_events, color: Color(0xFF00FF00), size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Ranked Tournament',
                          style: TextStyle(
                            color: Color(0xFF00FF00),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tournament Name
                  _buildTextField(
                    controller: _nameController,
                    label: 'Tournament Name',
                    icon: Icons.sports_esports,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter tournament name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Game Selection Dropdown
                  _buildGameDropdown(viewModel),
                  const SizedBox(height: 16),

                  // Format Selection Dropdown
                  _buildFormatDropdown(),
                  const SizedBox(height: 16),

                  // Date Selection
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateSelector(
                          label: 'Start Date',
                          date: _startDate,
                          onTap: () => _selectDate(context, true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDateSelector(
                          label: 'End Date',
                          date: _endDate,
                          onTap: () => _selectDate(context, false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Max Teams
                  _buildTextField(
                    controller: _maxTeamsController,
                    label: 'Max Teams',
                    icon: Icons.groups,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter max teams';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Prize Pool (Optional)
                  _buildTextField(
                    controller: _prizePoolController,
                    label: 'Prize Pool (Optional)',
                    icon: Icons.monetization_on,
                  ),
                  const SizedBox(height: 24),

                  // Friend Selection Section
                  _buildFriendSelection(viewModel),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: viewModel.isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00FF00),
                        foregroundColor: const Color(0xFF0A0E1A),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: viewModel.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF0A0E1A),
                                ),
                              ),
                            )
                          : const Text(
                              'Create Tournament',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF7A86AC)),
        prefixIcon: Icon(icon, color: const Color(0xFF7A86AC)),
        filled: true,
        fillColor: const Color(0xFF0F1221),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1A1F36)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1A1F36)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00FF00)),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildDateSelector({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1221),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1A1F36)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF7A86AC),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Color(0xFF00FF00), size: 16),
                const SizedBox(width: 8),
                Text(
                  date != null
                      ? '${date.day}/${date.month}/${date.year}'
                      : 'Select date',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameDropdown(TournamentsViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Game',
          style: TextStyle(
            color: Color(0xFF7A86AC),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1221),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _selectedGameId != null
                  ? const Color(0xFF00FF00)
                  : const Color(0xFF1A1F36),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedGameId,
              hint: Row(
                children: const [
                  Icon(Icons.videogame_asset, color: Color(0xFF7A86AC), size: 20),
                  SizedBox(width: 12),
                  Text(
                    'Choose a game',
                    style: TextStyle(color: Color(0xFF7A86AC)),
                  ),
                ],
              ),
              isExpanded: true,
              dropdownColor: const Color(0xFF0F1221),
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF00FF00)),
              items: viewModel.availableGames.isEmpty
                  ? [
                      DropdownMenuItem<String>(
                        value: null,
                        enabled: false,
                        child: Text(
                          viewModel.error != null && viewModel.error!.contains('games')
                              ? 'Error loading games'
                              : 'Loading games...',
                          style: TextStyle(
                            color: viewModel.error != null && viewModel.error!.contains('games')
                                ? const Color(0xFFFF0055)
                                : const Color(0xFF7A86AC),
                          ),
                        ),
                      ),
                    ]
                  : viewModel.availableGames.map((game) {
                      return DropdownMenuItem<String>(
                        value: game.id,
                        child: Row(
                          children: [
                            const Icon(Icons.videogame_asset,
                                color: Color(0xFF00FF00), size: 20),
                            const SizedBox(width: 12),
                            Text(
                              game.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedGameId = newValue;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormatDropdown() {
    const formats = [
      {'value': 'SINGLE_ELIMINATION', 'label': 'Single Elimination'},
      {'value': 'DOUBLE_ELIMINATION', 'label': 'Double Elimination'},
      {'value': 'SWISS', 'label': 'Swiss'},
      {'value': 'ROUND_ROBIN', 'label': 'Round Robin'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tournament Format',
          style: TextStyle(
            color: Color(0xFF7A86AC),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1221),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _selectedFormat != null
                  ? const Color(0xFF00FF00)
                  : const Color(0xFF1A1F36),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedFormat,
              hint: const Row(
                children: [
                  Icon(Icons.category, color: Color(0xFF7A86AC), size: 20),
                  SizedBox(width: 12),
                  Text(
                    'Choose format',
                    style: TextStyle(color: Color(0xFF7A86AC)),
                  ),
                ],
              ),
              isExpanded: true,
              dropdownColor: const Color(0xFF0F1221),
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF00FF00)),
              items: formats.map((format) {
                return DropdownMenuItem<String>(
                  value: format['value'],
                  child: Row(
                    children: [
                      const Icon(Icons.category,
                          color: Color(0xFF00FF00), size: 20),
                      const SizedBox(width: 12),
                      Text(
                        format['label']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedFormat = newValue;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFriendSelection(TournamentsViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Invite Friends (Optional)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Select friends to invite to your tournament',
          style: TextStyle(
            color: Color(0xFF7A86AC),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        if (viewModel.availableFriends.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1221),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1A1F36)),
            ),
            child: const Text(
              'No friends available to invite',
              style: TextStyle(color: Color(0xFF7A86AC)),
            ),
          )
        else
          ...viewModel.availableFriends.map((friend) {
            final isSelected = _selectedFriendIds.contains(friend.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CheckboxListTile(
                value: isSelected,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedFriendIds.add(friend.id);
                    } else {
                      _selectedFriendIds.remove(friend.id);
                    }
                  });
                },
                title: Text(
                  friend.nickname,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  friend.email,
                  style: const TextStyle(color: Color(0xFF7A86AC)),
                ),
                activeColor: const Color(0xFF00FF00),
                checkColor: const Color(0xFF0A0E1A),
                tileColor: const Color(0xFF0F1221),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF00FF00)
                        : const Color(0xFF1A1F36),
                  ),
                ),
              ),
            );
          }).toList(),
      ],
    );
  }
}
