import 'package:flutter/material.dart';

/// Player DMs / threads — UI shell until a messages API is wired.
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({
    super.key,
    this.embeddedInPlayerShell = false,
  });

  /// Inside [PlayerHomeScreen] tabs: menu opens drawer; no inner [Scaffold] so parent nav stays correct.
  final bool embeddedInPlayerShell;

  static const Color _background = Color(0xFF000000);
  static const Color _surface = Color(0xFF0A0A0A);
  static const Color _card = Color(0xFF1A1C23);
  static const Color _neon = Color(0xFF39FF14);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(context),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
            children: [
              Text(
                'Direct messages and team threads will appear here.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.48),
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              _threadTile(
                title: 'Team chat',
                preview: 'Match tonight at 9 — confirm roster',
                time: '2h',
                unread: true,
              ),
              const SizedBox(height: 10),
              _threadTile(
                title: 'Arena-Chain Support',
                preview: 'Thanks for your feedback!',
                time: '1d',
                unread: false,
              ),
            ],
          ),
        ),
      ],
    );

    if (embeddedInPlayerShell) {
      return ColoredBox(color: _background, child: body);
    }

    return Scaffold(
      backgroundColor: _background,
      body: body,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: _background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 8, 10),
          child: Row(
            children: [
              _buildLeading(context),
              Expanded(
                child: Text(
                  'Messages',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    shadows: [
                      Shadow(color: _neon.withValues(alpha: 0.2), blurRadius: 10),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeading(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        shape: BoxShape.circle,
        border: Border.all(color: _neon.withValues(alpha: 0.22)),
      ),
      child: IconButton(
        icon: Icon(
          embeddedInPlayerShell ? Icons.menu_rounded : Icons.arrow_back_rounded,
          color: _neon.withValues(alpha: 0.92),
        ),
        onPressed: () {
          if (embeddedInPlayerShell) {
            Scaffold.maybeOf(context)?.openDrawer();
          } else {
            Navigator.maybePop(context);
          }
        },
      ),
    );
  }

  Widget _threadTile({
    required String title,
    required String preview,
    required String time,
    required bool unread,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: unread ? _neon.withValues(alpha: 0.4) : _neon.withValues(alpha: 0.14),
            ),
            boxShadow: unread
                ? [
                    BoxShadow(
                      color: _neon.withValues(alpha: 0.06),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: _neon.withValues(alpha: 0.3)),
                ),
                child: Icon(
                  Icons.forum_rounded,
                  color: _neon.withValues(alpha: 0.85),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          time,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: unread ? 0.55 : 0.42),
                        fontSize: 13,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              if (unread) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _neon,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _neon.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
