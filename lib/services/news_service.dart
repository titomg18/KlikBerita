import 'package:pocketbase/pocketbase.dart';
import '../models/news_model.dart';
import 'Auth.dart';

class NewsService {
  // PocketBase instance
  static PocketBase get _pb => AuthService.pb;
  static const String collectionName = 'berita';

  // Test koneksi ke PocketBase dengan cara yang lebih sederhana
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      print('🔄 Testing PocketBase connection...');
      print('📍 PocketBase URL: ${_pb.baseUrl}');
      
      // Test dengan mencoba fetch 1 record saja
      final resultList = await _pb.collection(collectionName).getList(
        page: 1,
        perPage: 1,
      );
      
      print('✅ PocketBase connection successful');
      print('📊 Found ${resultList.totalItems} total items in collection');
      
      return {
        'success': true,
        'message': 'Connection successful',
        'totalItems': resultList.totalItems,
        'hasData': resultList.items.isNotEmpty,
      };
    } catch (e) {
      print('❌ PocketBase connection failed: $e');
      return {
        'success': false,
        'message': 'Connection failed: $e',
        'error': e.toString(),
      };
    }
  }

  // Mendapatkan semua berita dari PocketBase (dengan debugging)
  static Future<List<NewsModel>> getAllNews({
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      print('🔄 Fetching news from PocketBase...');
      print('📍 URL: ${_pb.baseUrl}');
      print('📦 Collection: $collectionName');
      
      // Test koneksi dulu
      final connectionTest = await testConnection();
      if (!connectionTest['success']) {
        print('❌ Connection test failed, using mock data');
        print('🔍 Error details: ${connectionTest['message']}');
        return _getMockNews();
      }
      
      print('✅ Connection test passed, fetching data...');
      
      // Menggunakan getList dengan pagination
      final resultList = await _pb.collection(collectionName).getList(
        page: page,
        perPage: perPage,
        sort: '-created', // Urutkan berdasarkan terbaru
      );

      print('✅ Fetched ${resultList.items.length} news items from PocketBase');
      print('📊 Total items available: ${resultList.totalItems}');
      
      if (resultList.items.isEmpty) {
        print('⚠️ No data found in PocketBase, using mock data');
        return _getMockNews();
      }
      
      // Debug: Print first record structure
      if (resultList.items.isNotEmpty) {
        final firstRecord = resultList.items.first;
        print('📄 First record data:');
        print('  - ID: ${firstRecord.id}');
        print('  - news: ${firstRecord.getStringValue('news')}');
        print('  - news_detail: ${firstRecord.getStringValue('news_detail')}');
        print('  - category: ${firstRecord.getStringValue('category')}');
        print('  - Gambar: ${firstRecord.getStringValue('Gambar')}');
        print('  - created: ${firstRecord.getStringValue('created')}');
      }
      
      final newsItems = resultList.items.map((record) {
        try {
          return NewsModel.fromPocketBase(record);
        } catch (e) {
          print('❌ Error parsing record ${record.id}: $e');
          return null;
        }
      }).where((item) => item != null).cast<NewsModel>().toList();
      
      print('✅ Successfully parsed ${newsItems.length} news items');
      
      if (newsItems.isEmpty) {
        print('⚠️ No valid news items after parsing, using mock data');
        return _getMockNews();
      }
      
      return newsItems;
    } catch (e) {
      print('❌ Error fetching news from PocketBase: $e');
      print('📝 Error type: ${e.runtimeType}');
      if (e is ClientException) {
        print('🔍 ClientException details: ${e.response}');
      }
      print('🔄 Falling back to mock data');
      return _getMockNews();
    }
  }

  // Mendapatkan semua berita sekaligus (tanpa pagination)
  static Future<List<NewsModel>> getAllNewsComplete() async {
    try {
      print('🔄 Fetching all news from PocketBase...');
      
      // Menggunakan getFullList untuk mengambil semua data sekaligus
      final records = await _pb.collection(collectionName).getFullList(
        sort: '-created',
      );

      print('✅ Fetched all ${records.length} news items from PocketBase');
      return records.map((record) => NewsModel.fromPocketBase(record)).toList();
    } catch (e) {
      print('❌ Error fetching all news from PocketBase: $e');
      return _getMockNews();
    }
  }

  // Mendapatkan berita berdasarkan kategori
  static Future<List<NewsModel>> getNewsByCategory(String category) async {
    try {
      print('🔄 Fetching news by category: $category');
      
      final resultList = await _pb.collection(collectionName).getList(
        page: 1,
        perPage: 100,
        filter: 'category = "$category"',
        sort: '-created',
      );

      print('✅ Fetched ${resultList.items.length} news items for category: $category');
      return resultList.items.map((record) => NewsModel.fromPocketBase(record)).toList();
    } catch (e) {
      print('❌ Error fetching news by category from PocketBase: $e');
      // Fallback ke mock data dengan filter kategori
      final mockNews = _getMockNews();
      return mockNews.where((news) => 
        news.category.toLowerCase() == category.toLowerCase()
      ).toList();
    }
  }

  // Mencari berita berdasarkan keyword
  static Future<List<NewsModel>> searchNews(String keyword) async {
    try {
      print('🔍 Searching news with keyword: $keyword');
      
      final resultList = await _pb.collection(collectionName).getList(
        page: 1,
        perPage: 100,
        filter: 'news ~ "$keyword" || news_detail ~ "$keyword" || category ~ "$keyword"',
        sort: '-created',
      );

      print('✅ Found ${resultList.items.length} news items for keyword: $keyword');
      return resultList.items.map((record) => NewsModel.fromPocketBase(record)).toList();
    } catch (e) {
      print('❌ Error searching news in PocketBase: $e');
      final mockNews = _getMockNews();
      return mockNews.where((news) => 
        news.title.toLowerCase().contains(keyword.toLowerCase()) ||
        news.description.toLowerCase().contains(keyword.toLowerCase()) ||
        news.content.toLowerCase().contains(keyword.toLowerCase()) ||
        news.category.toLowerCase().contains(keyword.toLowerCase())
      ).toList();
    }
  }

  // Mendapatkan berita berdasarkan ID
  static Future<NewsModel?> getNewsById(String id) async {
    try {
      print('🔄 Fetching news by ID: $id');
      
      final record = await _pb.collection(collectionName).getOne(id);
      print('✅ Fetched news by ID: $id');
      return NewsModel.fromPocketBase(record);
    } catch (e) {
      print('❌ Error fetching news by ID from PocketBase: $e');
      try {
        return _getMockNews().firstWhere((news) => news.id == id);
      } catch (e) {
        return null;
      }
    }
  }

  // Mendapatkan berita terbaru
  static Future<NewsModel?> getLatestNews() async {
    try {
      print('🔄 Fetching latest news...');
      
      final resultList = await _pb.collection(collectionName).getList(
        page: 1,
        perPage: 1,
        sort: '-created',
      );
    
      if (resultList.items.isNotEmpty) {
        print('✅ Fetched latest news');
        return NewsModel.fromPocketBase(resultList.items.first);
      }
      return null;
    } catch (e) {
      print('❌ Error fetching latest news: $e');
      return null;
    }
  }

  // Mendapatkan kategori yang tersedia dari PocketBase
  static Future<List<String>> getCategories() async {
    try {
      print('🔄 Fetching categories from PocketBase...');
      
      // Ambil semua record untuk mendapatkan kategori unik
      final records = await _pb.collection(collectionName).getFullList();
      
      Set<String> categories = {'Semua'}; // Tambahkan "Semua" di awal
      
      for (var record in records) {
        final category = record.getStringValue('category');
        if (category.isNotEmpty) {
          categories.add(category);
        }
      }
      
      print('✅ Found ${categories.length - 1} unique categories: ${categories.toList()}');
      return categories.toList();
    } catch (e) {
      print('❌ Error fetching categories from PocketBase: $e');
      return getDefaultCategories();
    }
  }

  // Mendapatkan kategori default (untuk fallback)
  static List<String> getDefaultCategories() {
    return ['Semua', 'Teknologi', 'Olahraga', 'Ekonomi', 'Pendidikan', 'Wisata', 'Politik', 'Kesehatan', 'Hiburan'];
  }

  // Create new news (untuk admin)
  static Future<Map<String, dynamic>> createNews({
    required String title,
    required String content,
    required String category,
    required String author,
    required String source,
    String? imagePath,
  }) async {
    if (!AuthService.isLoggedIn) {
      return {
        'success': false,
        'message': 'User not authenticated',
      };
    }

    try {
      final Map<String, dynamic> data = {
        'news': '$title|$author|$source',
        'news_detail': content,
        'category': category,
      };

      final record = await _pb.collection(collectionName).create(body: data);
      
      print('✅ Created new news: ${record.id}');
      return {
        'success': true,
        'message': 'Berita berhasil dibuat',
        'data': NewsModel.fromPocketBase(record),
      };
    } on ClientException catch (e) {
      print('❌ PocketBase error creating news: ${e.response}');
      return {
        'success': false,
        'message': 'Gagal membuat berita: ${e.response['message'] ?? e.toString()}',
      };
    } catch (e) {
      print('❌ General error creating news: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Update news (untuk admin)
  static Future<Map<String, dynamic>> updateNews({
    required String id,
    required String title,
    required String content,
    required String category,
    required String author,
    required String source,
  }) async {
    if (!AuthService.isLoggedIn) {
      return {
        'success': false,
        'message': 'User not authenticated',
      };
    }

    try {
      final Map<String, dynamic> data = {
        'news': '$title|$author|$source',
        'news_detail': content,
        'category': category,
      };

      final record = await _pb.collection(collectionName).update(id, body: data);
      
      print('✅ Updated news: $id');
      return {
        'success': true,
        'message': 'Berita berhasil diupdate',
        'data': NewsModel.fromPocketBase(record),
      };
    } on ClientException catch (e) {
      print('❌ PocketBase error updating news: ${e.response}');
      return {
        'success': false,
        'message': 'Gagal update berita: ${e.response['message'] ?? e.toString()}',
      };
    } catch (e) {
      print('❌ General error updating news: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Delete news (untuk admin)
  static Future<Map<String, dynamic>> deleteNews(String id) async {
    if (!AuthService.isLoggedIn) {
      return {
        'success': false,
        'message': 'User not authenticated',
      };
    }

    try {
      await _pb.collection(collectionName).delete(id);
      
      print('✅ Deleted news: $id');
      return {
        'success': true,
        'message': 'Berita berhasil dihapus',
      };
    } on ClientException catch (e) {
      print('❌ PocketBase error deleting news: ${e.response}');
      return {
        'success': false,
        'message': 'Gagal hapus berita: ${e.response['message'] ?? e.toString()}',
      };
    } catch (e) {
      print('❌ General error deleting news: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Get news statistics
  static Future<Map<String, dynamic>> getNewsStats() async {
    try {
      final allNews = await _pb.collection(collectionName).getFullList();
      
      Map<String, int> categoryStats = {};
      for (var record in allNews) {
        final category = record.getStringValue('category');
        if (category.isNotEmpty) {
          categoryStats[category] = (categoryStats[category] ?? 0) + 1;
        }
      }
      
      print('✅ Generated stats for ${allNews.length} news items');
      return {
        'success': true,
        'data': {
          'total': allNews.length,
          'categories': categoryStats,
          'latest': allNews.isNotEmpty ? NewsModel.fromPocketBase(allNews.first) : null,
        },
      };
    } catch (e) {
      print('❌ Error getting news stats: $e');
      return {
        'success': false,
        'message': 'Gagal mengambil statistik: $e',
      };
    }
  }

  // Get trending categories
  static Future<List<Map<String, dynamic>>> getTrendingCategories() async {
    try {
      final stats = await getNewsStats();
      if (stats['success']) {
        final categoryStats = stats['data']['categories'] as Map<String, int>;
        
        var sortedCategories = categoryStats.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        return sortedCategories.take(5).map((entry) => {
          'category': entry.key,
          'count': entry.value,
        }).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error getting trending categories: $e');
      return [];
    }
  }

  // Get news by date range
  static Future<List<NewsModel>> getNewsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final startDateStr = startDate.toIso8601String();
      final endDateStr = endDate.toIso8601String();
      
      final resultList = await _pb.collection(collectionName).getList(
        page: 1,
        perPage: 100,
        filter: 'created >= "$startDateStr" && created <= "$endDateStr"',
        sort: '-created',
      );

      return resultList.items.map((record) => NewsModel.fromPocketBase(record)).toList();
    } catch (e) {
      print('❌ Error fetching news by date range: $e');
      return [];
    }
  }

  // Check if news exists
  static Future<bool> newsExists(String id) async {
    try {
      await _pb.collection(collectionName).getOne(id);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get random news
  static Future<List<NewsModel>> getRandomNews({int count = 5}) async {
    try {
      final allNews = await getAllNewsComplete();
      allNews.shuffle();
      return allNews.take(count).toList();
    } catch (e) {
      print('❌ Error getting random news: $e');
      return [];
    }
  }

  // Mock data sebagai fallback
  static List<NewsModel> _getMockNews() {
    print('📝 Using mock data as fallback');
    return [
      NewsModel(
        id: '1',
        title: 'Teknologi AI Terbaru Mengubah Dunia Digital',
        description: 'Perkembangan kecerdasan buatan yang pesat membawa perubahan besar dalam berbagai sektor industri.',
        content: 'Teknologi kecerdasan buatan (AI) terus berkembang pesat dan mengubah cara kita berinteraksi dengan dunia digital. Dari asisten virtual hingga sistem rekomendasi, AI telah menjadi bagian integral dari kehidupan sehari-hari. Para ahli memprediksi bahwa dalam 5 tahun ke depan, AI akan semakin canggih dan dapat membantu menyelesaikan berbagai masalah kompleks di berbagai bidang seperti kesehatan, pendidikan, dan transportasi.',
        imageUrl: 'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=800&h=400&fit=crop',
        category: 'Teknologi',
        author: 'Ahmad Rizki',
        publishedAt: DateTime.now().subtract(Duration(hours: 2)),
        source: 'TechNews Indonesia',
      ),
      NewsModel(
        id: '2',
        title: 'Olahraga Nasional Meraih Prestasi Gemilang',
        description: 'Tim nasional berhasil meraih medali emas dalam kompetisi internasional yang bergengsi.',
        content: 'Tim olahraga nasional Indonesia berhasil menorehkan prestasi membanggakan dengan meraih medali emas dalam kejuaraan internasional. Pencapaian ini merupakan hasil dari latihan keras dan dedikasi tinggi para atlet. Pelatih tim menyatakan bahwa kunci sukses adalah konsistensi latihan dan dukungan penuh dari berbagai pihak. Prestasi ini diharapkan dapat memotivasi generasi muda untuk lebih aktif berolahraga.',
        imageUrl: 'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=800&h=400&fit=crop',
        category: 'Olahraga',
        author: 'Sari Dewi',
        publishedAt: DateTime.now().subtract(Duration(hours: 5)),
        source: 'SportNews ID',
      ),
      NewsModel(
        id: '3',
        title: 'Ekonomi Digital Indonesia Tumbuh Pesat',
        description: 'Sektor ekonomi digital mengalami pertumbuhan signifikan di tengah transformasi digital.',
        content: 'Ekonomi digital Indonesia menunjukkan pertumbuhan yang sangat menggembirakan. Data terbaru menunjukkan bahwa sektor e-commerce, fintech, dan startup teknologi mengalami peningkatan yang signifikan. Pemerintah terus mendukung perkembangan ekonomi digital melalui berbagai kebijakan dan program. Para pelaku usaha digital optimis bahwa tren positif ini akan terus berlanjut dan memberikan dampak positif bagi perekonomian nasional.',
        imageUrl: 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=800&h=400&fit=crop',
        category: 'Ekonomi',
        author: 'Budi Santoso',
        publishedAt: DateTime.now().subtract(Duration(hours: 8)),
        source: 'EkonomiNews',
      ),
      NewsModel(
        id: '4',
        title: 'Pendidikan Online Semakin Diminati',
        description: 'Platform pembelajaran online mengalami peningkatan pengguna yang drastis.',
        content: 'Pandemi telah mengubah lanskap pendidikan secara fundamental. Platform pembelajaran online kini menjadi pilihan utama bagi banyak pelajar dan mahasiswa. Berbagai institusi pendidikan berlomba-lomba mengembangkan platform digital yang interaktif dan mudah digunakan. Metode pembelajaran hybrid yang menggabungkan online dan offline diprediksi akan menjadi standar baru dalam dunia pendidikan.',
        imageUrl: 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=800&h=400&fit=crop',
        category: 'Pendidikan',
        author: 'Maya Sari',
        publishedAt: DateTime.now().subtract(Duration(hours: 12)),
        source: 'EduNews Indonesia',
      ),
      NewsModel(
        id: '5',
        title: 'Wisata Lokal Bangkit Pasca Pandemi',
        description: 'Sektor pariwisata domestik menunjukkan tanda-tanda pemulihan yang menggembirakan.',
        content: 'Industri pariwisata Indonesia mulai menunjukkan tanda-tanda pemulihan yang positif. Wisata lokal menjadi pilihan utama masyarakat untuk berlibur. Berbagai destinasi wisata di seluruh nusantara mulai ramai dikunjungi wisatawan. Pemerintah daerah gencar mempromosikan potensi wisata lokal dengan protokol kesehatan yang ketat. Pelaku usaha pariwisata optimis bahwa sektor ini akan segera pulih sepenuhnya.',
        imageUrl: 'https://images.unsplash.com/photo-1539650116574-75c0c6d73f6e?w=800&h=400&fit=crop',
        category: 'Wisata',
        author: 'Andi Pratama',
        publishedAt: DateTime.now().subtract(Duration(days: 1)),
        source: 'WisataNews',
      ),
    ];
  }
}
