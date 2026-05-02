String _canonicalRole(String role) {
  return role.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

bool isAdminRole(String role) => _canonicalRole(role) == 'admin';

bool isScouterRole(String role) => _canonicalRole(role) == 'scouter';

bool isTeamManagerRole(String role) {
  final normalized = _canonicalRole(role);
  return normalized == 'teammanager' ||
      normalized == 'roleteammanager' ||
      (normalized.contains('team') && normalized.contains('manager'));
}

bool isCheckInAgentRole(String role) {
  final normalized = _canonicalRole(role);
  // Handles: check_in_agent, check-in-agent, checkinagent, ROLE_CHECK_IN_AGENT, etc.
  return normalized == 'checkinagent' ||
      normalized == 'rolecheckinagent' ||
      (normalized.contains('checkin') && normalized.contains('agent'));
}
