import 'package:pocketbase/pocketbase.dart';
import '../models/news_model.dart';
import 'Auth.dart';

class FavoriteService {
  // PocketBase instance
  static PocketBase get _pb => AuthService.pb;
  static const String collectionName = 'favorites'; // Collection untuk menyimpan favorit user
  
  // Simulasi penyimpanan lokal untuk sementara (jika belum ada collection favorites)
  static List<String> _favoriteNewsIds = [];
  static List<NewsModel> _favoriteNews = [];

  // Initialize favorites dari PocketBase (jika user login)
  static Future<void> initializeFavorites() async {
    if (!AuthService.isLoggedIn) return;
    
    try {
      // Coba ambil favorites dari PocketBase
      final resultList = await _pb.collection(collectionName).getList(
        filter: 'user = "${AuthService.currentUser!.id}"',
        expand: 'news', // Expand relation ke berita
      );
      
      _favoriteNewsIds.clear();
      _favoriteNews.clear();
      
      for (var record in resultList.items) {
        final newsId = record.getStringValue('news');
        _favoriteNewsIds.add(newsId);
        
        // Ambil data berita lengkap
        try {
          final newsRecord = await _pb.collection('berita').getOne(newsId);
          _favoriteNews.add(NewsModel.fromPocketBase(newsRecord));
        } catch (e) {
          print('Error loading favorite news: $e');
        }
      }
    } catch (e) {
      print('Favorites collection not found or error: $e');
      // Collection favorites belum ada, gunakan local storage
    }
  }

  // Menambah berita ke favorit
  static Future<void> addToFavorite(NewsModel news) async {
    // Simulasi delay untuk operasi database
    await Future.delayed(Duration(milliseconds: 200));
    
    if (!_favoriteNewsIds.contains(news.id)) {
      _favoriteNewsIds.add(news.id);
      _favoriteNews.add(news);
      
      // Jika user login, simpan ke PocketBase
      if (AuthService.isLoggedIn) {
        try {
          await _pb.collection(collectionName).create(body: {
            'user': AuthService.currentUser!.id,
            'news': news.id,
            'title': news.title, // Simpan title untuk referensi
          });
        } catch (e) {
          print('Error saving favorite to PocketBase: $e');
          // Tetap simpan di local jika gagal ke PocketBase
        }
      }
    }
  }

  // Menghapus berita dari favorit
  static Future<void> removeFromFavorite(String newsId) async {
    // Simulasi delay untuk operasi database
    await Future.delayed(Duration(milliseconds: 200));
    
    _favoriteNewsIds.remove(newsId);
    _favoriteNews.removeWhere((news) => news.id == newsId);
    
    // Jika user login, hapus dari PocketBase
    if (AuthService.isLoggedIn) {
      try {
        final records = await _pb.collection(collectionName).getList(
          filter: 'user = "${AuthService.currentUser!.id}" && news = "$newsId"',
        );
        
        for (var record in records.items) {
          await _pb.collection(collectionName).delete(record.id);
        }
      } catch (e) {
        print('Error removing favorite from PocketBase: $e');
      }
    }
  }

  // Mengecek apakah berita sudah difavoritkan
  static bool isFavorite(String newsId) {
    return _favoriteNewsIds.contains(newsId);
  }

  // Mendapatkan semua berita favorit
  static Future<List<NewsModel>> getFavoriteNews() async {
    // Simulasi delay untuk operasi database
    await Future.delayed(Duration(milliseconds: 200));
    
    // Jika user login, sync dengan PocketBase
    if (AuthService.isLoggedIn) {
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
    if (isFavorite(news.id)) {
      await removeFromFavorite(news.id);
      return false; // Tidak lagi favorit
    } else {
      await addToFavorite(news);
      return true; // Sekarang favorit
    }
  }

  // Clear semua favorit (untuk testing atau reset)
  static Future<void> clearAllFavorites() async {
    await Future.delayed(Duration(milliseconds: 200));
    
    // Jika user login, hapus dari PocketBase
    if (AuthService.isLoggedIn) {
      try {
        final records = await _pb.collection(collectionName).getList(
          filter: 'user = "${AuthService.currentUser!.id}"',
        );
        
        for (var record in records.items) {
          await _pb.collection(collectionName).delete(record.id);
        }
      } catch (e) {
        print('Error clearing favorites from PocketBase: $e');
      }
    }
    
    _favoriteNewsIds.clear();
    _favoriteNews.clear();
  }

  // Sync favorites ketika user login
  static Future<void> syncFavoritesOnLogin() async {
    if (AuthService.isLoggedIn) {
      await initializeFavorites();
    }
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
      
      return {
        'success': true,
        'data': {
          'total': favorites.length,
          'categories': categoryStats,
          'recent': favorites.isNotEmpty ? favorites.first : null,
        },
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal mengambil statistik favorit: $e',
      };
    }
  }
}
