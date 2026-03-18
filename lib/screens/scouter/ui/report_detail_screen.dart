import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/core/models/feature_scouter/scouter_models.dart';
import 'package:arena_chain_flutter/screens/scouter/ui/scouter_player_detail_screen.dart';

// ── Design tokens ──────────────────────────────────────────────
const _bgTop          = Color(0xFF040609);
const _bgBottom       = Color(0xFF0A0D14);
const _surface        = Color(0xFF111625);
const _card           = Color(0xFF111625);
const _cardElevated   = Color(0xFF161C2C);
const _border         = Color(0x0DFFFFFF); // Colors.white.withValues(alpha: 0.05)
const _accent         = Color(0xFF00FF00);
const _textSecondary  = Color(0xFF8B95A5);

/// Screen showing full details of a scouting report.
class ReportDetailScreen extends StatelessWidget {
  final ScoutingReport report;
  final String scouterId;
  final VoidCallback? onReportCreated;

  const ReportDetailScreen({
    super.key,
    required this.report,
    required this.scouterId,
    this.onReportCreated,
  });

  @override
  Widget build(BuildContext context) {
    final rating = report.rating;
    final ratingColor = rating >= 80
        ? const Color(0xFF00FF00)
        : rating >= 60
            ? const Color(0xFFFFAA00)
            : const Color(0xFFFF0055);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_bgTop, _bgBottom],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Report Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Player header card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _cardElevated.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: ratingColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ratingColor.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$rating',
                          style: TextStyle(
                            color: ratingColor,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.playerNickname,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (report.recommendedRole != null) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                report.recommendedRole!,
                                style: const TextStyle(
                                  color: _accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          if (report.createdAt != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _formatDate(report.createdAt!),
                              style: const TextStyle(
                                color: _textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (report.playerIdStr.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ScouterPlayerDetailScreen(
                                playerUserId: report.playerIdStr,
                                scouterId: scouterId,
                                onReportCreated: onReportCreated,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.person_outline,
                          color: _accent,
                          size: 18,
                        ),
                        label: const Text(
                          'View Player',
                          style: TextStyle(
                            color: _accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Strengths
              if (report.strengths != null && report.strengths!.isNotEmpty) ...[
                _sectionLabel('Strengths'),
                const SizedBox(height: 8),
                _contentBlock(report.strengths!),
                const SizedBox(height: 20),
              ],

              // Weaknesses
              if (report.weaknesses != null && report.weaknesses!.isNotEmpty) ...[
                _sectionLabel('Weaknesses'),
                const SizedBox(height: 8),
                _contentBlock(report.weaknesses!),
                const SizedBox(height: 20),
              ],

              // Notes
              if (report.notes != null && report.notes!.isNotEmpty) ...[
                _sectionLabel('Notes'),
                const SizedBox(height: 8),
                _contentBlock(report.notes!),
                const SizedBox(height: 20),
              ],

              // Match ID
              if (report.matchId != null && report.matchId!.isNotEmpty) ...[
                _sectionLabel('Match Reference'),
                const SizedBox(height: 8),
                _contentBlock(report.matchId!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: _textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _contentBlock(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardElevated.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso.length >= 10 ? iso.substring(0, 10) : iso;
    }
  }
}
