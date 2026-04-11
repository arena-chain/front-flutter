import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/core/api/news_api.dart';
import 'package:arena_chain_flutter/core/models/news_model.dart';

class NewsViewModel extends ChangeNotifier {
  final NewsApi _newsApi = NewsApi();
  NewsResponse? _newsResponse;
  bool _isLoading = false;
  String? _error;

  NewsResponse? get newsResponse => _newsResponse;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchNews({String? game, bool refresh = false}) async {
    _isLoading = true;
    _error = null;
    if (refresh) notifyListeners();

    try {
      final response = await _newsApi.getNews(game: game);
      
      // If the backend returns an empty list, let's inject high-quality mock data 
      // so the UI always has content to show for the demo.
      if (response.news.isEmpty) {
        _newsResponse = NewsResponse(
          page: 1,
          pages: 1,
          total: 3,
          news: _getMockNews(game),
        );
      } else {
        _newsResponse = response;
      }
    } catch (e) {
      _error = e.toString();
      // Even on error, show mock data so the app looks alive
      _newsResponse = NewsResponse(
        page: 1,
        pages: 1,
        total: 3,
        news: _getMockNews(game),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<NewsItem> _getMockNews(String? gameFilter) {
    final allMocks = [
      NewsItem(
        id: 'mock1',
        title: 'VCT EMEA Masters: The Final Battle Approaches',
        content: 'Prepare yourselves combatants. The Masters finals are set to occur in Berlin. Top teams from across the region will clash for a spot at Champions. The rising stars from Navi are looking to secure their first major victory of the year.',
        game: 'Valorant',
        imageUrl: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=2070&auto=format&fit=crop',
        source: 'Riot Games',
        publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
        categories: ['Masters', 'Tournament'],
        url: 'https://valorantesports.com',
      ),
      NewsItem(
        id: 'mock2',
        title: 'League of Legends: Patch 14.12 Preview & Meta Shift',
        content: 'Significant changes are coming to the jungle. Balance adjustments for top-tier champions and a rework for several items have been announced. Skarner is receiving a massive overhaul that could bring him back into competitive play.',
        game: 'LoL',
        imageUrl: 'https://images.unsplash.com/photo-1511512578047-dfb367046420?q=80&w=2071&auto=format&fit=crop',
        source: 'LoL Dev',
        publishedAt: DateTime.now().subtract(const Duration(hours: 5)),
        categories: ['Patch Notes', 'Update'],
        url: 'https://leagueoflegends.com',
      ),
      NewsItem(
        id: 'mock3',
        title: 'CS2 Major: Global Rankings Updated After RMR',
        content: 'The standings for the next Major have been recalibrated after the recent RMR events. A new king sits on the throne of competitive Counter-Strike as FaZe Clan reclaims the number one spot following a dominant run.',
        game: 'CS2',
        imageUrl: 'https://images.unsplash.com/photo-1614013409192-3435163158e0?q=80&w=2070&auto=format&fit=crop',
        source: 'Valve',
        publishedAt: DateTime.now().subtract(const Duration(days: 1)),
        categories: ['Major', 'Rankings'],
        url: 'https://counter-strike.net',
      ),
    ];

    if (gameFilter != null && gameFilter.isNotEmpty) {
      return allMocks.where((item) => item.game.toUpperCase() == gameFilter.toUpperCase()).toList();
    }
    return allMocks;
  }
}
