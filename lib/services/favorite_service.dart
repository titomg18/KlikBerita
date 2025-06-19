import 'package:pocketbase/pocketbase.dart';
import '../models/news_model.dart';
import 'Auth.dart';
import 'news_service.dart';

class FavoriteService {
  // PocketBase instance
  static PocketBase get _pb => AuthService.pb;
  static const String collectionName = 'favorites_berita'; // Your new collection name
  
  // Local cache untuk performa yang lebih baik
  static List<String> _favoriteNewsIds = [];
  static List<NewsModel> _favoriteNews = [];
  static bool _isInitialized = false;

  // Initialize favorites dari PocketBase
  static Future<void> initializeFavorites() async {
    if (!AuthService.isLoggedIn) {
      print('👤 User not logged in, clearing local favorites cache');
      _favoriteNewsIds.clear();
      _favoriteNews.clear();
      _isInitialized = false;
      return;
    }
    
    try {
      print('🔄 Loading favorites from PocketBase...');
      
      // Ambil semua favorites user dari PocketBase
      final resultList = await _pb.collection(collectionName).getList(
        filter: 'user = "${AuthService.currentUser!.id}"',
        sort: '-created', // Sort by newest first
        perPage: 100, // Ambil maksimal 100 favorites
      );
      
      print('✅ Found ${resultList.items.length} favorites in database');
      
      _favoriteNewsIds.clear();
      _favoriteNews.clear();
      
      // Load detail berita untuk setiap favorite
      for (var favoriteRecord in resultList.items) {
        final newsId = favoriteRecord.getStringValue('berita');
        _favoriteNewsIds.add(newsId);
        
        try {
          // Ambil detail berita dari NewsService
          final news = await NewsService.getNewsById(newsId);
          if (news != null) {
            _favoriteNews.add(news);
          }
        } catch (e) {
          print('⚠️ Error loading favorite news $newsId: $e');
          // Skip this favorite if news not found
        }
      }
      
      _isInitialized = true;
      print('✅ Favorites initialized: ${_favoriteNews.length} news loaded');
      
    } catch (e) {
      print('❌ Error initializing favorites: $e');
      _isInitialized = false;
      
      // Clear cache on error
      _favoriteNewsIds.clear();
      _favoriteNews.clear();
    }
  }

  // Menambah berita ke favorit
  static Future<void> addToFavorite(NewsModel news) async {
    if (!AuthService.isLoggedIn) {
      throw Exception('User must be logged in to add favorites');
    }

    try {
      print('❤️ Adding news to favorites: ${news.title}');
      
      // Cek apakah sudah ada di favorites
      final existingFavorites = await _pb.collection(collectionName).getList(
        filter: 'user = "${AuthService.currentUser!.id}" && berita = "${news.id}"',
      );
      
      if (existingFavorites.items.isNotEmpty) {
        print('⚠️ News already in favorites');
        return;
      }
      
      // Tambah ke PocketBase
      await _pb.collection(collectionName).create(body: {
        'user': AuthService.currentUser!.id,
        'berita': news.id,
      });
      
      // Update local cache
      if (!_favoriteNewsIds.contains(news.id)) {
        _favoriteNewsIds.add(news.id);
        _favoriteNews.add(news);
      }
      
      print('✅ News added to favorites successfully');
      
    } catch (e) {
      print('❌ Error adding to favorites: $e');
      throw Exception('Gagal menambahkan ke favorit: $e');
    }
  }

  // Menghapus berita dari favorit
  static Future<void> removeFromFavorite(String newsId) async {
    if (!AuthService.isLoggedIn) {
      throw Exception('User must be logged in to remove favorites');
    }

    try {
      print('💔 Removing news from favorites: $newsId');
      
      // Hapus dari PocketBase
      final existingFavorites = await _pb.collection(collectionName).getList(
        filter: 'user = "${AuthService.currentUser!.id}" && berita = "$newsId"',
      );
      
      for (var favorite in existingFavorites.items) {
        await _pb.collection(collectionName).delete(favorite.id);
      }
      
      // Update local cache
      _favoriteNewsIds.remove(newsId);
      _favoriteNews.removeWhere((news) => news.id == newsId);
      
      print('✅ News removed from favorites successfully');
      
    } catch (e) {
      print('❌ Error removing from favorites: $e');
      throw Exception('Gagal menghapus dari favorit: $e');
    }
  }

  // Mengecek apakah berita sudah difavoritkan
  static bool isFavorite(String newsId) {
    return _favoriteNewsIds.contains(newsId);
  }

  // Mendapatkan semua berita favorit
  static Future<List<NewsModel>> getFavoriteNews() async {
    if (!AuthService.isLoggedIn) {
      return [];
    }
    
    // Initialize jika belum
    if (!_isInitialized) {
      await initializeFavorites();
    }
    
    return List.from(_favoriteNews);
  }

  // Mendapatkan jumlah berita favorit
  static int getFavoriteCount() {
    return _favoriteNews.length;
  }

  // Toggle status favorit (add jika belum ada, remove jika sudah ada)
  static Future<bool> toggleFavorite(NewsModel news) async {
    if (!AuthService.isLoggedIn) {
      throw Exception('User must be logged in to manage favorites');
    }
    
    if (isFavorite(news.id)) {
      await removeFromFavorite(news.id);
      return false; // Tidak lagi favorit
    } else {
      await addToFavorite(news);
      return true; // Sekarang favorit
    }
  }

  // Clear semua favorit user
  static Future<void> clearAllFavorites() async {
    if (!AuthService.isLoggedIn) {
      throw Exception('User must be logged in to clear favorites');
    }

    try {
      print('🗑️ Clearing all favorites...');
      
      // Hapus semua favorites user dari PocketBase
      final allFavorites = await _pb.collection(collectionName).getList(
        filter: 'user = "${AuthService.currentUser!.id}"',
        perPage: 500, // Ambil semua
      );
      
      for (var favorite in allFavorites.items) {
        await _pb.collection(collectionName).delete(favorite.id);
      }
      
      // Clear local cache
      _favoriteNewsIds.clear();
      _favoriteNews.clear();
      
      print('✅ All favorites cleared successfully');
      
    } catch (e) {
      print('❌ Error clearing favorites: $e');
      throw Exception('Gagal menghapus semua favorit: $e');
    }
  }

  // Sync favorites ketika user login
  static Future<void> syncFavoritesOnLogin() async {
    if (AuthService.isLoggedIn) {
      await initializeFavorites();
    }
  }

  // Refresh favorites dari server
  static Future<void> refreshFavorites() async {
    _isInitialized = false;
    await initializeFavorites();
  }

  // Get favorite statistics
  static Future<Map<String, dynamic>> getFavoriteStats() async {
    if (!AuthService.isLoggedIn) {
      return {
        'success': false,
        'message': 'User not authenticated',
      };
    }

    try {
      final favorites = await getFavoriteNews();
      
      // Hitung statistik per kategori
      Map<String, int> categoryStats = {};
      for (var news in favorites) {
        categoryStats[news.category] = (categoryStats[news.category] ?? 0) + 1;
      }
      
      // Hitung favorites per bulan (3 bulan terakhir)
      Map<String, int> monthlyStats = {};
      final now = DateTime.now();
      
      for (var news in favorites) {
        final monthKey = '${news.publishedAt.year}-${news.publishedAt.month.toString().padLeft(2, '0')}';
        monthlyStats[monthKey] = (monthlyStats[monthKey] ?? 0) + 1;
      }
      
      return {
        'success': true,
        'data': {
          'total': favorites.length,
          'categories': categoryStats,
          'monthly': monthlyStats,
          'recent': favorites.isNotEmpty ? favorites.first : null,
          'mostFavoriteCategory': categoryStats.isNotEmpty 
              ? categoryStats.entries.reduce((a, b) => a.value > b.value ? a : b).key
              : null,
        },
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal mengambil statistik favorit: $e',
      };
    }
  }

  // Check if favorites need sync (untuk optimasi)
  static Future<bool> needsSync() async {
    if (!AuthService.isLoggedIn || !_isInitialized) {
      return true;
    }
    
    try {
      // Cek jumlah favorites di server vs local
      final serverCount = await _pb.collection(collectionName).getList(
        filter: 'user = "${AuthService.currentUser!.id}"',
        perPage: 1,
      );
      
      return serverCount.totalItems != _favoriteNews.length;
    } catch (e) {
      return true; // Sync jika ada error
    }
  }

  // Get favorites by category
  static Future<List<NewsModel>> getFavoritesByCategory(String category) async {
    final allFavorites = await getFavoriteNews();
    return allFavorites.where((news) => 
      news.category.toLowerCase() == category.toLowerCase()
    ).toList();
  }

  // Search in favorites
  static Future<List<NewsModel>> searchFavorites(String query) async {
    final allFavorites = await getFavoriteNews();
    return allFavorites.where((news) =>
      news.title.toLowerCase().contains(query.toLowerCase()) ||
      news.description.toLowerCase().contains(query.toLowerCase()) ||
      news.content.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
}
