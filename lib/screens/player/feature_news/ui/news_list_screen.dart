import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:arena_chain_flutter/screens/player/feature_news/viewmodel/news_viewmodel.dart';
import 'package:arena_chain_flutter/core/models/news_model.dart';

class NewsListScreen extends StatefulWidget {
  const NewsListScreen({super.key});

  @override
  State<NewsListScreen> createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen> {
  String? _selectedGame;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NewsViewModel>().fetchNews(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C08),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('NEXUS NEWS', style: TextStyle(color: Color(0xFF00FF00), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00FF00)),
            onPressed: () => context.read<NewsViewModel>().fetchNews(game: _selectedGame, refresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(child: _buildNewsList()),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final games = ['ALL', 'LOL', 'VALORANT', 'CS2', 'DOTA2'];
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: games.length,
        itemBuilder: (context, index) {
          final game = games[index];
          final isSelected = (_selectedGame == null && game == 'ALL') || _selectedGame == game;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(game),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedGame = game == 'ALL' ? null : game;
                });
                context.read<NewsViewModel>().fetchNews(game: _selectedGame, refresh: true);
              },
              selectedColor: const Color(0xFF00FF00),
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              backgroundColor: const Color(0xFF151515),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNewsList() {
    return Consumer<NewsViewModel>(
      builder: (context, newsVM, child) {
        if (newsVM.isLoading && newsVM.newsResponse == null) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF00FF00)));
        }

        final news = newsVM.newsResponse?.news ?? [];
        if (news.isEmpty) {
          return const Center(child: Text('No transmissions found in segment.', style: TextStyle(color: Colors.white70)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: news.length,
          itemBuilder: (context, index) => _buildNewsCard(news[index]),
        );
      },
    );
  }

  Widget _buildNewsCard(NewsItem item) {
    final dateStr = DateFormat('MMM dd, yyyy HH:mm').format(item.publishedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                item.imageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(height: 180, color: Colors.grey.withOpacity(0.1)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF00FF00).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(item.game.toUpperCase(), style: const TextStyle(color: Color(0xFF00FF00), fontWeight: FontWeight.bold, fontSize: 10)),
                    ),
                    Text(dateStr, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(item.content, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (item.source != null)
                      Text('SOURCE: ${item.source!.toUpperCase()}', style: const TextStyle(color: Color(0xFF00FF00), fontSize: 10, letterSpacing: 1)),
                    TextButton(
                      onPressed: () => _launchURL(item.url),
                      child: const Text('FULL DEBRIEF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String? url) async {
    if (url == null) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
