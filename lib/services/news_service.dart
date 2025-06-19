import 'package:pocketbase/pocketbase.dart';
import '../models/news_model.dart';
import 'Auth.dart';

class NewsService {
  // PocketBase instance
  static PocketBase get _pb => AuthService.pb;
  static const String collectionName = 'berita'; // Sesuai dengan collection di PocketBase
  
  // Default categories untuk fallback
  static List<String> getDefaultCategories() {
    return [
      'Semua',
      'Teknologi',
      'Olahraga', 
      'Ekonomi',
      'Pendidikan',
      'Wisata',
      'Politik',
      'Kesehatan',
      'Hiburan'
    ];
  }

  // Test koneksi PocketBase dengan method yang lebih sederhana
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      print('🔄 Testing PocketBase connection to berita collection...');
      print('📍 URL: ${_pb.baseUrl}');
      
      // Test dengan mengambil 1 record dari collection berita tanpa filter
      final result = await _pb.collection(collectionName).getList(
        page: 1,
        perPage: 1,
      );
      
      print('✅ Connection successful, found ${result.totalItems} news items');
      return {
        'success': true,
        'message': 'Connection successful',
        'totalItems': result.totalItems,
      };
    } catch (e) {
      print('❌ Connection failed: $e');
      print('🔍 Error details: ${e.toString()}');
      
      // Check specific error types
      if (e.toString().contains('404')) {
        return {
          'success': false,
          'message': 'Collection "berita" not found',
          'error': 'COLLECTION_NOT_FOUND',
        };
      } else if (e.toString().contains('403') || e.toString().contains('401')) {
        return {
          'success': false,
          'message': 'Permission denied - check collection rules',
          'error': 'PERMISSION_DENIED',
        };
      } else if (e.toString().contains('Failed host lookup') || e.toString().contains('Connection refused')) {
        return {
          'success': false,
          'message': 'Cannot connect to PocketBase server',
          'error': 'CONNECTION_ERROR',
        };
      } else {
        return {
          'success': false,
          'message': 'Connection failed: $e',
          'error': 'UNKNOWN_ERROR',
        };
      }
    }
  }

  // Debug PocketBase connection dengan informasi lebih detail
  static Future<void> debugPocketBase() async {
    print('🔧 === PocketBase Debug Info ===');
    print('📍 Base URL: ${_pb.baseUrl}');
    print('👤 User logged in: ${AuthService.isLoggedIn}');
    if (AuthService.isLoggedIn) {
      print('👤 User: ${AuthService.currentUser?.getStringValue('name')}');
      print('🔑 Auth token: ${AuthService.authToken?.substring(0, 20)}...');
    }
    
    // Test basic connection
    print('🔗 Testing basic connection...');
    try {
      final healthCheck = await _pb.health.check();
      print('✅ PocketBase server is healthy: ${healthCheck.message}');
    } catch (e) {
      print('❌ PocketBase server health check failed: $e');
      return;
    }
    
    // Test collection access
    final connectionTest = await testConnection();
    print('🔗 Collection access test: ${connectionTest['success'] ? 'SUCCESS' : 'FAILED'}');
    if (!connectionTest['success']) {
      print('❌ Error: ${connectionTest['message']}');
      print('💡 Error type: ${connectionTest['error']}');
    }
    
    // Try to list collections (admin only)
    try {
      final collections = await _pb.collections.getList();
      print('📦 Available collections: ${collections.items.map((c) => c.name).toList()}');
    } catch (e) {
      print('❌ Cannot list collections (normal for non-admin users): $e');
    }
    
    print('🔧 === End Debug Info ===');
  }

  // Check database data dengan error handling yang lebih baik
  static Future<void> checkDatabaseData() async {
    try {
      print('📊 Checking database data...');
      
      // Coba ambil data tanpa filter dulu
      final result = await _pb.collection(collectionName).getList(
        page: 1,
        perPage: 5,
        sort: '-created', // Sort by newest first
      );
      
      print('📊 Total news in database: ${result.totalItems}');
      print('📊 Current page items: ${result.items.length}');
      
      if (result.items.isNotEmpty) {
        final firstNews = result.items.first;
        print('📰 Sample news:');
        print('   - ID: ${firstNews.id}');
        print('   - Title: ${firstNews.getStringValue('berita')}');
        print('   - Category: ${firstNews.getStringValue('category')}');
        print('   - Has Image: ${firstNews.getStringValue('Gambar').isNotEmpty}');
        print('   - Created: ${firstNews.getStringValue('created')}');
      } else {
        print('📰 No news found in database');
      }
    } catch (e) {
      print('❌ Error checking database: $e');
      print('💡 This might be due to collection rules or connection issues');
    }
  }

  // Get all news dengan handling yang lebih robust
  static Future<List<NewsModel>> getAllNews() async {
    try {
      print('📰 Loading all news...');
      
      // Jika user belum login, return mock data
      if (!AuthService.isLoggedIn) {
        print('👤 User not logged in, returning mock data');
        return _getMockNews();
      }
      
      // Test connection first
      final connectionTest = await testConnection();
      if (!connectionTest['success']) {
        print('⚠️ Connection failed: ${connectionTest['message']}');
        print('📰 Returning mock data as fallback');
        return _getMockNews();
      }
      
      // Fetch data dari PocketBase
      final result = await _pb.collection(collectionName).getList(
        page: 1,
        perPage: 50,
        sort: '-created', // Sort by newest first
      );
      
      print('✅ Loaded ${result.items.length} news from PocketBase');
      
      if (result.items.isEmpty) {
        print('📰 No news found in database, returning mock data');
        return _getMockNews();
      }
      
      // Convert PocketBase records to NewsModel
      List<NewsModel> newsList = [];
      for (var record in result.items) {
        try {
          final news = NewsModel.fromPocketBase(record);
          newsList.add(news);
        } catch (e) {
          print('⚠️ Error parsing news record ${record.id}: $e');
          // Skip this record and continue
        }
      }
      
      return newsList.isNotEmpty ? newsList : _getMockNews();
      
    } catch (e) {
      print('❌ Error loading news: $e');
      print('📰 Falling back to mock data');
      return _getMockNews();
    }
  }

  // Get news by category
  static Future<List<NewsModel>> getNewsByCategory(String category) async {
    try {
      print('📰 Loading news for category: $category');
      
      // Jika user belum login, return filtered mock data
      if (!AuthService.isLoggedIn) {
        final mockNews = _getMockNews();
        return mockNews.where((news) => 
          news.category.toLowerCase() == category.toLowerCase()
        ).toList();
      }
      
      // Fetch from PocketBase with category filter
      final result = await _pb.collection(collectionName).getList(
        page: 1,
        perPage: 50,
        filter: 'category = "$category"',
        sort: '-created',
      );
      
      print('✅ Loaded ${result.items.length} news for category $category');
      
      List<NewsModel> newsList = [];
      for (var record in result.items) {
        try {
          final news = NewsModel.fromPocketBase(record);
          newsList.add(news);
        } catch (e) {
          print('⚠️ Error parsing news record ${record.id}: $e');
        }
      }
      
      // If no results from database, return filtered mock data
      if (newsList.isEmpty) {
        final mockNews = _getMockNews();
        return mockNews.where((news) => 
          news.category.toLowerCase() == category.toLowerCase()
        ).toList();
      }
      
      return newsList;
      
    } catch (e) {
      print('❌ Error loading news by category: $e');
      // Return filtered mock data as fallback
      final mockNews = _getMockNews();
      return mockNews.where((news) => 
        news.category.toLowerCase() == category.toLowerCase()
      ).toList();
    }
  }

  // Get news by ID
  static Future<NewsModel?> getNewsById(String id) async {
    try {
      print('📰 Loading news with ID: $id');
      
      // Check if it's mock data ID
      if (['1', '2', '3', '4', '5'].contains(id)) {
        final mockNews = _getMockNews();
        return mockNews.firstWhere((news) => news.id == id);
      }
      
      // Jika user belum login dan bukan mock data, return null
      if (!AuthService.isLoggedIn) {
        print('👤 User not logged in, cannot access real news');
        return null;
      }
      
      final record = await _pb.collection(collectionName).getOne(id);
      print('✅ Loaded news: ${record.getStringValue('berita')}');
      
      return NewsModel.fromPocketBase(record);
    } catch (e) {
      print('❌ Error loading news by ID: $e');
      return null;
    }
  }

  // Get categories dari database atau default
  static Future<List<String>> getCategories() async {
    try {
      print('📂 Loading categories...');
      
      // Jika user belum login, return default categories
      if (!AuthService.isLoggedIn) {
        print('👤 User not logged in, returning default categories');
        return getDefaultCategories();
      }
      
      // Get unique categories from database
      final result = await _pb.collection(collectionName).getList(
        page: 1,
        perPage: 500, // Get more records to find all categories
        sort: '-created',
      );
      
      Set<String> categories = {'Semua'}; // Always include 'Semua'
      
      for (var record in result.items) {
        final category = record.getStringValue('category');
        if (category.isNotEmpty) {
          categories.add(category);
        }
      }
      
      final categoryList = categories.toList();
      print('✅ Loaded categories from database: $categoryList');
      
      // If no categories found, return default
      return categoryList.length > 1 ? categoryList : getDefaultCategories();
      
    } catch (e) {
      print('❌ Error loading categories: $e');
      return getDefaultCategories();
    }
  }

  // Search news - IMPROVED VERSION
  static Future<List<NewsModel>> searchNews(String query) async {
    try {
      print('🔍 Searching news with query: "$query"');
      
      if (query.trim().isEmpty) {
        print('⚠️ Empty search query');
        return [];
      }
      
      final cleanQuery = query.trim();
      
      // Jika user belum login, search in mock data
      if (!AuthService.isLoggedIn) {
        print('👤 User not logged in, searching in mock data');
        final mockNews = _getMockNews();
        final results = mockNews.where((news) =>
          news.title.toLowerCase().contains(cleanQuery.toLowerCase()) ||
          news.description.toLowerCase().contains(cleanQuery.toLowerCase()) ||
          news.content.toLowerCase().contains(cleanQuery.toLowerCase()) ||
          news.category.toLowerCase().contains(cleanQuery.toLowerCase()) ||
          news.author.toLowerCase().contains(cleanQuery.toLowerCase()) ||
          news.source.toLowerCase().contains(cleanQuery.toLowerCase())
        ).toList();
        
        print('✅ Found ${results.length} results in mock data');
        return results;
      }
      
      // Test connection first
      final connectionTest = await testConnection();
      if (!connectionTest['success']) {
        print('⚠️ Connection failed, searching in mock data');
        final mockNews = _getMockNews();
        return mockNews.where((news) =>
          news.title.toLowerCase().contains(cleanQuery.toLowerCase()) ||
          news.description.toLowerCase().contains(cleanQuery.toLowerCase()) ||
          news.content.toLowerCase().contains(cleanQuery.toLowerCase())
        ).toList();
      }
      
      // Search in database using multiple approaches
      List<NewsModel> allResults = [];
      
      // Approach 1: Search in title (berita field)
      try {
        print('🔍 Searching in title field...');
        final titleResults = await _pb.collection(collectionName).getList(
          page: 1,
          perPage: 50,
          filter: 'berita ~ "$cleanQuery"',
          sort: '-created',
        );
        
        print('📝 Found ${titleResults.items.length} results in title');
        
        for (var record in titleResults.items) {
          try {
            final news = NewsModel.fromPocketBase(record);
            if (!allResults.any((existing) => existing.id == news.id)) {
              allResults.add(news);
            }
          } catch (e) {
            print('⚠️ Error parsing title search result ${record.id}: $e');
          }
        }
      } catch (e) {
        print('⚠️ Error searching in title: $e');
      }
      
      // Approach 2: Search in content (detail_berita field)
      try {
        print('🔍 Searching in content field...');
        final contentResults = await _pb.collection(collectionName).getList(
          page: 1,
          perPage: 50,
          filter: 'detail_berita ~ "$cleanQuery"',
          sort: '-created',
        );
        
        print('📝 Found ${contentResults.items.length} results in content');
        
        for (var record in contentResults.items) {
          try {
            final news = NewsModel.fromPocketBase(record);
            if (!allResults.any((existing) => existing.id == news.id)) {
              allResults.add(news);
            }
          } catch (e) {
            print('⚠️ Error parsing content search result ${record.id}: $e');
          }
        }
      } catch (e) {
        print('⚠️ Error searching in content: $e');
      }
      
      // Approach 3: Search in category
      try {
        print('🔍 Searching in category field...');
        final categoryResults = await _pb.collection(collectionName).getList(
          page: 1,
          perPage: 50,
          filter: 'category ~ "$cleanQuery"',
          sort: '-created',
        );
        
        print('📝 Found ${categoryResults.items.length} results in category');
        
        for (var record in categoryResults.items) {
          try {
            final news = NewsModel.fromPocketBase(record);
            if (!allResults.any((existing) => existing.id == news.id)) {
              allResults.add(news);
            }
          } catch (e) {
            print('⚠️ Error parsing category search result ${record.id}: $e');
          }
        }
      } catch (e) {
        print('⚠️ Error searching in category: $e');
      }
      
      // Approach 4: Try combined search if individual searches worked
      if (allResults.isEmpty) {
        try {
          print('🔍 Trying combined search...');
          final combinedResults = await _pb.collection(collectionName).getList(
            page: 1,
            perPage: 50,
            filter: 'berita ~ "$cleanQuery" || detail_berita ~ "$cleanQuery" || category ~ "$cleanQuery"',
            sort: '-created',
          );
          
          print('📝 Found ${combinedResults.items.length} results in combined search');
          
          for (var record in combinedResults.items) {
            try {
              final news = NewsModel.fromPocketBase(record);
              allResults.add(news);
            } catch (e) {
              print('⚠️ Error parsing combined search result ${record.id}: $e');
            }
          }
        } catch (e) {
          print('⚠️ Error in combined search: $e');
        }
      }
      
      // Sort results by relevance (title matches first, then content, then category)
      allResults.sort((a, b) {
        final aTitle = a.title.toLowerCase().contains(cleanQuery.toLowerCase());
        final bTitle = b.title.toLowerCase().contains(cleanQuery.toLowerCase());
        
        if (aTitle && !bTitle) return -1;
        if (!aTitle && bTitle) return 1;
        
        // If both or neither match title, sort by date
        return b.publishedAt.compareTo(a.publishedAt);
      });
      
      print('✅ Total unique search results: ${allResults.length}');
      
      // If no results from database, try mock data as fallback
      if (allResults.isEmpty) {
        print('📰 No results from database, searching mock data');
        final mockNews = _getMockNews();
        return mockNews.where((news) =>
          news.title.toLowerCase().contains(cleanQuery.toLowerCase()) ||
          news.description.toLowerCase().contains(cleanQuery.toLowerCase()) ||
          news.content.toLowerCase().contains(cleanQuery.toLowerCase()) ||
          news.category.toLowerCase().contains(cleanQuery.toLowerCase()) ||
          news.author.toLowerCase().contains(cleanQuery.toLowerCase()) ||
          news.source.toLowerCase().contains(cleanQuery.toLowerCase())
        ).toList();
      }
      
      return allResults;
      
    } catch (e) {
      print('❌ Error searching news: $e');
      print('❌ Error type: ${e.runtimeType}');
      if (e is ClientException) {
        print('❌ ClientException response: ${e.response}');
      }
      
      // Fallback to mock data search
      print('📰 Falling back to mock data search');
      final mockNews = _getMockNews();
      return mockNews.where((news) =>
        news.title.toLowerCase().contains(query.toLowerCase()) ||
        news.description.toLowerCase().contains(query.toLowerCase()) ||
        news.content.toLowerCase().contains(query.toLowerCase()) ||
        news.category.toLowerCase().contains(query.toLowerCase()) ||
        news.author.toLowerCase().contains(query.toLowerCase()) ||
        news.source.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }
  }

  // Create news (admin only) - untuk referensi saja
  static Future<Map<String, dynamic>> createNews({
    required String title,
    required String content,
    required String category,
    String? imageFile,
  }) async {
    if (!AuthService.isLoggedIn) {
      return {
        'success': false,
        'message': 'User not authenticated',
      };
    }

    try {
      final Map<String, dynamic> data = {
        'berita': title,
        'detail_berita': content,
        'category': category,
      };

      // Add image if provided
      if (imageFile != null) {
        // Handle file upload here
        // data['Gambar'] = imageFile;
      }

      final record = await _pb.collection(collectionName).create(body: data);
      
      return {
        'success': true,
        'message': 'News created successfully',
        'data': NewsModel.fromPocketBase(record),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to create news: $e',
      };
    }
  }

  // Mock data untuk demo (ketika user belum login atau ada error)
  static List<NewsModel> _getMockNews() {
    return [
      NewsModel(
        id: '1',
        title: 'Teknologi AI Terbaru Mengubah Dunia Digital',
        description: 'Perkembangan kecerdasan buatan yang pesat membawa perubahan signifikan dalam berbagai sektor industri dan kehidupan sehari-hari.',
        content: '''
Kecerdasan Buatan (AI) telah menjadi salah satu teknologi paling revolusioner di era digital ini. Dengan kemampuannya untuk memproses data dalam jumlah besar dan melakukan pembelajaran otomatis, AI telah mengubah cara kita bekerja, berkomunikasi, dan menjalani kehidupan sehari-hari.

## Dampak AI di Berbagai Sektor

### 1. Sektor Kesehatan
AI telah membantu dokter dalam mendiagnosis penyakit dengan lebih akurat dan cepat. Sistem AI dapat menganalisis hasil rontgen, MRI, dan CT scan dengan tingkat akurasi yang sangat tinggi.

### 2. Sektor Pendidikan
Platform pembelajaran online yang didukung AI dapat memberikan pengalaman belajar yang dipersonalisasi untuk setiap siswa, menyesuaikan dengan gaya belajar dan kemampuan masing-masing.

### 3. Sektor Transportasi
Mobil otonom yang menggunakan teknologi AI telah mulai diuji coba di berbagai negara, menjanjikan transportasi yang lebih aman dan efisien.

## Tantangan dan Peluang

Meskipun AI membawa banyak manfaat, ada juga tantangan yang perlu dihadapi, seperti:
- Keamanan data dan privasi
- Dampak terhadap lapangan kerja
- Etika dalam penggunaan AI

Namun, dengan regulasi yang tepat dan pengembangan yang bertanggung jawab, AI memiliki potensi besar untuk meningkatkan kualitas hidup manusia.

## Kesimpulan

Teknologi AI akan terus berkembang dan menjadi bagian integral dari kehidupan kita. Penting bagi kita untuk memahami dan beradaptasi dengan perubahan ini agar dapat memanfaatkan teknologi AI secara optimal.
        ''',
        imageUrl: 'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=800&h=400&fit=crop',
        category: 'Teknologi',
        author: 'Dr. Ahmad Teknologi',
        publishedAt: DateTime.now().subtract(Duration(hours: 2)),
        source: 'KlikBerita Tech',
      ),
      NewsModel(
        id: '2',
        title: 'Timnas Indonesia Raih Kemenangan Gemilang di Piala AFF',
        description: 'Tim nasional sepak bola Indonesia berhasil meraih kemenangan dengan skor 3-1 melawan tim tamu dalam pertandingan yang berlangsung sengit.',
        content: '''
Stadion Gelora Bung Karno menjadi saksi kemenangan gemilang Timnas Indonesia dalam laga penting Piala AFF kemarin malam. Dengan dukungan lebih dari 80.000 penonton yang memadati stadion, Garuda Muda berhasil mengalahkan tim lawan dengan skor telak 3-1.

## Jalannya Pertandingan

### Babak Pertama
Pertandingan dimulai dengan tempo tinggi dari kedua tim. Indonesia berhasil unggul lebih dulu melalui gol spektakuler dari Egy Maulana Vikri di menit ke-23. Gol tersebut tercipta dari umpan silang sempurna yang berhasil diselesaikan dengan tendangan voli yang indah.

### Babak Kedua
Memasuki babak kedua, tim lawan berusaha menyamakan kedudukan dan berhasil mencetak gol di menit ke-58. Namun, Indonesia tidak tinggal diam dan langsung membalas dengan dua gol beruntun di menit ke-67 dan ke-84.

## Performa Pemain

Beberapa pemain yang tampil impresif dalam pertandingan ini:

**Egy Maulana Vikri** - Mencetak 2 gol dan memberikan 1 assist
**Witan Sulaeman** - Kontrol permainan yang sangat baik di lini tengah  
**Pratama Arhan** - Solid di lini belakang dan aktif menyerang

## Reaksi Pelatih

Pelatih Timnas Indonesia, Shin Tae-yong, menyatakan kepuasannya terhadap performa tim. "Anak-anak bermain dengan sangat baik hari ini. Mereka menunjukkan mental juara dan kerja sama tim yang luar biasa," ujarnya dalam konferensi pers pasca pertandingan.

## Dampak Kemenangan

Kemenangan ini membawa Indonesia ke posisi puncak klasemen sementara Grup B dengan 7 poin dari 3 pertandingan. Peluang lolos ke semifinal semakin terbuka lebar.

## Pertandingan Selanjutnya

Timnas Indonesia akan menghadapi tantangan berikutnya melawan Malaysia pada Minggu depan di Stadion Bukit Jalil, Kuala Lumpur. Pertandingan tersebut akan menjadi penentu nasib Indonesia di fase grup.

Dukungan suporter diharapkan terus mengalir untuk memberikan motivasi tambahan bagi para pemain dalam meraih prestasi terbaik di turnamen bergengsi ini.
        ''',
        imageUrl: 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800&h=400&fit=crop',
        category: 'Olahraga',
        author: 'Budi Olahraga',
        publishedAt: DateTime.now().subtract(Duration(hours: 5)),
        source: 'KlikBerita Sports',
      ),
      NewsModel(
        id: '3',
        title: 'Ekonomi Indonesia Tumbuh 5.2% di Kuartal Ketiga',
        description: 'Badan Pusat Statistik melaporkan pertumbuhan ekonomi Indonesia mencapai 5.2% year-on-year, didorong oleh konsumsi domestik yang kuat.',
        content: '''
Badan Pusat Statistik (BPS) hari ini mengumumkan bahwa ekonomi Indonesia tumbuh 5.2% secara year-on-year di kuartal ketiga tahun ini. Angka ini sedikit di atas ekspektasi para ekonom yang memperkirakan pertumbuhan sekitar 5.0%.

## Faktor Pendorong Pertumbuhan

### 1. Konsumsi Rumah Tangga
Konsumsi rumah tangga menjadi kontributor utama pertumbuhan dengan kontribusi 3.1 poin persentase. Hal ini didorong oleh:
- Peningkatan daya beli masyarakat
- Program bantuan sosial pemerintah
- Stabilitas harga kebutuhan pokok

### 2. Investasi Swasta
Investasi atau Pembentukan Modal Tetap Bruto (PMTB) tumbuh 4.8%, didorong oleh:
- Investasi infrastruktur
- Ekspansi sektor manufaktur
- Investasi teknologi digital

### 3. Ekspor Neto
Meskipun menghadapi tantangan global, ekspor Indonesia masih menunjukkan resiliensi dengan pertumbuhan 2.3%.

## Analisis Sektoral

**Sektor Manufaktur** tumbuh 4.9%, menjadi penyumbang terbesar PDB dengan kontribusi 20.1%.

**Sektor Perdagangan** tumbuh 5.8%, mencerminkan aktivitas ekonomi domestik yang solid.

**Sektor Konstruksi** tumbuh 3.2%, didukung oleh proyek infrastruktur pemerintah.

## Tantangan ke Depan

Meskipun menunjukkan tren positif, ekonomi Indonesia masih menghadapi beberapa tantangan:

### Eksternal
- Ketidakpastian ekonomi global
- Fluktuasi harga komoditas
- Kebijakan moneter negara maju

### Internal  
- Inflasi yang perlu dijaga
- Defisit neraca perdagangan
- Kebutuhan reformasi struktural

## Proyeksi Ekonomi

Bank Indonesia memproyeksikan pertumbuhan ekonomi tahun ini akan berada di kisaran 4.9-5.2%. Sementara itu, pemerintah menargetkan pertumbuhan 5.3% untuk tahun depan.

## Kebijakan Pemerintah

Menteri Keuangan menyatakan bahwa pemerintah akan terus fokus pada:
- Penguatan konsumsi domestik
- Peningkatan investasi infrastruktur
- Reformasi regulasi untuk menarik investasi
- Pengembangan ekonomi digital

## Respons Pasar

Bursa Efek Indonesia merespons positif data ini dengan penguatan IHSG sebesar 1.2% pada sesi pagi. Rupiah juga menguat tipis terhadap dolar AS.

Para analis optimis bahwa momentum pertumbuhan ini dapat dipertahankan hingga akhir tahun, asalkan kondisi global tetap kondusif dan kebijakan domestik tetap suportif.
        ''',
        imageUrl: 'https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?w=800&h=400&fit=crop',
        category: 'Ekonomi',
        author: 'Sari Ekonomi',
        publishedAt: DateTime.now().subtract(Duration(hours: 8)),
        source: 'KlikBerita Finance',
      ),
      NewsModel(
        id: '4',
        title: 'Pendidikan Digital Transformasi Pembelajaran Modern',
        description: 'Revolusi digital dalam pendidikan membawa perubahan fundamental dalam cara siswa belajar dan guru mengajar di era modern.',
        content: '''
Transformasi digital dalam dunia pendidikan telah mengubah paradigma pembelajaran tradisional. Teknologi digital tidak hanya menjadi alat bantu, tetapi telah menjadi bagian integral dari proses pendidikan modern.

## Platform Pembelajaran Digital

### E-Learning Interaktif
Platform pembelajaran online kini menawarkan pengalaman belajar yang lebih interaktif dengan fitur:
- Video pembelajaran berkualitas tinggi
- Simulasi dan laboratorium virtual
- Gamifikasi untuk meningkatkan engagement
- Assessment otomatis dengan feedback real-time

### Artificial Intelligence dalam Pendidikan
AI memungkinkan personalisasi pembelajaran yang disesuaikan dengan:
- Gaya belajar individual siswa
- Kecepatan pemahaman masing-masing
- Identifikasi area yang perlu diperkuat
- Rekomendasi materi pembelajaran

## Dampak Positif

### Aksesibilitas
- Pembelajaran dapat diakses kapan saja, di mana saja
- Mengatasi keterbatasan geografis
- Biaya pendidikan yang lebih terjangkau
- Inklusivitas untuk siswa berkebutuhan khusus

### Efektivitas
- Pembelajaran yang lebih engaging
- Tracking progress yang akurat
- Kolaborasi global antar siswa
- Update materi yang real-time

## Tantangan Implementasi

### Infrastruktur
- Ketersediaan internet yang stabil
- Perangkat teknologi yang memadai
- Literasi digital guru dan siswa
- Dukungan teknis yang berkelanjutan

### Aspek Sosial
- Interaksi sosial yang terbatas
- Digital divide antar daerah
- Ketergantungan pada teknologi
- Keamanan data dan privasi

## Masa Depan Pendidikan

Pendidikan digital akan terus berkembang dengan:
- Virtual Reality untuk pengalaman immersive
- Blockchain untuk verifikasi kredensial
- IoT untuk smart classroom
- Big Data untuk analisis pembelajaran

## Kesimpulan

Transformasi digital dalam pendidikan adalah keniscayaan yang harus diadaptasi dengan bijak. Kombinasi antara teknologi dan pendekatan humanis akan menciptakan ekosistem pembelajaran yang optimal untuk generasi masa depan.
        ''',
        imageUrl: 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=800&h=400&fit=crop',
        category: 'Pendidikan',
        author: 'Prof. Siti Pendidikan',
        publishedAt: DateTime.now().subtract(Duration(hours: 12)),
        source: 'KlikBerita Edu',
      ),
      NewsModel(
        id: '5',
        title: 'Wisata Berkelanjutan Menjadi Tren Global',
        description: 'Konsep sustainable tourism semakin populer sebagai respons terhadap dampak lingkungan dari industri pariwisata konvensional.',
        content: '''
Industri pariwisata global sedang mengalami transformasi menuju praktik yang lebih berkelanjutan. Sustainable tourism atau wisata berkelanjutan kini menjadi prioritas utama dalam pengembangan destinasi wisata di seluruh dunia.

## Konsep Wisata Berkelanjutan

### Prinsip Dasar
Wisata berkelanjutan berfokus pada:
- Pelestarian lingkungan alam
- Pemberdayaan masyarakat lokal
- Viabilitas ekonomi jangka panjang
- Pengalaman autentik bagi wisatawan

### Implementasi Praktis
- Penggunaan energi terbarukan
- Pengelolaan limbah yang bertanggung jawab
- Konservasi air dan sumber daya alam
- Promosi budaya lokal

## Destinasi Berkelanjutan di Indonesia

### Raja Ampat, Papua Barat
- Program konservasi terumbu karang
- Pembatasan jumlah wisatawan
- Keterlibatan masyarakat dalam pengelolaan
- Edukasi lingkungan untuk pengunjung

### Taman Nasional Komodo
- Perlindungan habitat komodo
- Eco-lodge dengan standar internasional
- Program penelitian dan konservasi
- Sustainable diving practices

### Desa Wisata Penglipuran, Bali
- Preservasi arsitektur tradisional
- Zero waste village concept
- Organic farming practices
- Cultural immersion programs

## Manfaat Ekonomi

### Untuk Masyarakat Lokal
- Penciptaan lapangan kerja
- Peningkatan pendapatan
- Pengembangan UMKM
- Transfer skill dan knowledge

### Untuk Negara
- Diversifikasi ekonomi
- Peningkatan devisa
- Branding positif internasional
- Investasi infrastruktur berkelanjutan

## Tantangan dan Solusi

### Tantangan
- Biaya implementasi yang tinggi
- Resistensi terhadap perubahan
- Kurangnya awareness wisatawan
- Koordinasi antar stakeholder

### Solusi
- Insentif pemerintah untuk praktik berkelanjutan
- Edukasi dan kampanye awareness
- Sertifikasi dan standar internasional
- Kemitraan public-private

## Teknologi Pendukung

### Digital Innovation
- Smart destination management
- Carbon footprint tracking
- Virtual reality untuk pre-visit experience
- Mobile apps untuk sustainable travel

### Green Technology
- Solar power untuk akomodasi
- Electric vehicle untuk transportasi
- Water treatment systems
- Waste-to-energy solutions

## Tren Masa Depan

Wisata berkelanjutan akan berkembang dengan:
- Regenerative tourism concept
- Climate-positive destinations
- Hyper-local experiences
- Wellness dan mindful travel

## Peran Wisatawan

Wisatawan dapat berkontribusi dengan:
- Memilih akomodasi ramah lingkungan
- Menghormati budaya lokal
- Mengurangi jejak karbon
- Mendukung ekonomi lokal

## Kesimpulan

Wisata berkelanjutan bukan hanya tren, tetapi kebutuhan mendesak untuk menjaga planet ini untuk generasi mendatang. Kolaborasi semua pihak diperlukan untuk mewujudkan industri pariwisata yang bertanggung jawab dan berkelanjutan.
        ''',
        imageUrl: 'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=800&h=400&fit=crop',
        category: 'Wisata',
        author: 'Andi Wisata',
        publishedAt: DateTime.now().subtract(Duration(hours: 18)),
        source: 'KlikBerita Travel',
      ),
    ];
  }
}
