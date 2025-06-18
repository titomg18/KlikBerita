import 'package:flutter/material.dart';
import '../models/news_model.dart';
import '../services/news_service.dart';
import '../services/favorite_service.dart';
import 'news_detail_screen.dart';
import 'search_screen.dart';
import 'favorite_screen.dart';
import 'profile_screen.dart';
import '../services/Auth.dart';
import '../screens/Auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<NewsModel> _news = [];
  List<String> _categories = [];
  String _selectedCategory = 'Semua';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Memuat data berita dan kategori
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load categories dari PocketBase
      final categories = await NewsService.getCategories();
      final news = await NewsService.getAllNews();
      
      setState(() {
        _categories = categories;
        _news = news;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        // Fallback ke kategori default jika gagal
        _categories = NewsService.getDefaultCategories();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat berita: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Filter berita berdasarkan kategori
  Future<void> _filterByCategory(String category) async {
    setState(() {
      _selectedCategory = category;
      _isLoading = true;
    });

    try {
      List<NewsModel> filteredNews;
      if (category == 'Semua') {
        filteredNews = await NewsService.getAllNews();
      } else {
        filteredNews = await NewsService.getNewsByCategory(category);
      }
      
      setState(() {
        _news = filteredNews;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat berita: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Toggle favorite status
  Future<void> _toggleFavorite(NewsModel news) async {
    try {
      final isFavorite = await FavoriteService.toggleFavorite(news);
      
      setState(() {}); // Refresh UI untuk update icon
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFavorite 
                ? 'Berita ditambahkan ke favorit ❤️' 
                : 'Berita dihapus dari favorit 💔'
          ),
          backgroundColor: isFavorite ? Colors.green : Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan favorit: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Fungsi untuk mendapatkan warna berdasarkan kategori (menggunakan method dari NewsModel)
  Color _getCategoryColor(String category) {
    // Create temporary NewsModel to use the method
    final tempNews = NewsModel(
      id: '', title: '', description: '', content: '', imageUrl: '', 
      category: category, author: '', publishedAt: DateTime.now(), source: ''
    );
    return tempNews.getCategoryColor();
  }

  // Fungsi untuk mendapatkan icon berdasarkan kategori (menggunakan method dari NewsModel)
  IconData _getCategoryIcon(String category) {
    // Create temporary NewsModel to use the method
    final tempNews = NewsModel(
      id: '', title: '', description: '', content: '', imageUrl: '', 
      category: category, author: '', publishedAt: DateTime.now(), source: ''
    );
    return tempNews.getCategoryIcon();
  }

  // Fungsi untuk format waktu
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else {
      return '${difference.inDays} hari lalu';
    }
  }

  // Widget untuk menampilkan card berita dengan tombol favorite
  Widget _buildNewsCard(NewsModel news) {
    final isFavorite = FavoriteService.isFavorite(news.id);
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navigasi ke halaman detail berita
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsDetailScreen(newsId: news.id),
            ),
          ).then((_) {
            // Refresh UI ketika kembali dari detail screen
            setState(() {});
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar berita dengan tombol favorite
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    news.imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Colors.grey[600],
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Tombol favorite di pojok kanan atas gambar
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _toggleFavorite(news),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey[600],
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kategori dan waktu
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: news.getCategoryColor(), // Gunakan method dari NewsModel
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              news.getCategoryIcon(), // Gunakan method dari NewsModel
                              color: Colors.white,
                              size: 12,
                            ),
                            SizedBox(width: 4),
                            Text(
                              news.category,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Spacer(),
                      Text(
                        _formatTime(news.publishedAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 12),
                  
                  // Judul berita
                  Text(
                    news.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  SizedBox(height: 8),
                  
                  // Deskripsi berita
                  Text(
                    news.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  SizedBox(height: 12),
                  
                  // Author, source, dan tombol favorite
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 4),
                      Text(
                        news.author,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(width: 16),
                      Icon(
                        Icons.source,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          news.source,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      // Tombol favorite kecil di bawah
                      GestureDetector(
                        onTap: () => _toggleFavorite(news),
                        child: Container(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.grey[400],
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'KlikBerita',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[600],
        elevation: 0,
        actions: [
          // Profile button (only show if logged in)
          if (AuthService.isLoggedIn)
            Stack(
              children: [
                IconButton(
                  icon: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      color: Colors.blue[600],
                      size: 20,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfileScreen()),
                    ).then((_) {
                      // Refresh UI ketika kembali dari profile screen
                      setState(() {});
                    });
                  },
                  tooltip: 'Profil',
                ),
              ],
            ),
          
          // Tombol favorit dengan badge counter
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.favorite, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => FavoriteScreen()),
                  ).then((_) {
                    // Refresh UI ketika kembali dari favorite screen
                    setState(() {});
                  });
                },
              ),
              if (FavoriteService.getFavoriteCount() > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${FavoriteService.getFavoriteCount()}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header dengan kategori
          Container(
            color: Colors.blue[600],
            child: Column(
              children: [
                // Login prompt jika belum login
                if (!AuthService.isLoggedIn)
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Login untuk fitur lengkap',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => LoginScreen()),
                            ).then((_) {
                              setState(() {});
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                          child: Text('Login', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    AuthService.isLoggedIn 
                        ? 'Selamat datang, ${AuthService.currentUser?.getStringValue('name') ?? 'User'}!'
                        : 'Berita Terkini Indonesia',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
                
                // Dropdown filter kategori
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[300]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down, color: Colors.blue[600]),
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        hint: Text(
                          'Pilih Kategori',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        items: _categories.map((String category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Row(
                              children: [
                                Icon(
                                  _getCategoryIcon(category),
                                  color: _getCategoryColor(category),
                                  size: 20,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  category,
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: category == _selectedCategory 
                                        ? FontWeight.bold 
                                        : FontWeight.normal,
                                  ),
                                ),
                                if (category == _selectedCategory) ...[
                                  Spacer(),
                                  Icon(
                                    Icons.check,
                                    color: Colors.green,
                                    size: 18,
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null && newValue != _selectedCategory) {
                            _filterByCategory(newValue);
                          }
                        },
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: 8),
              ],
            ),
          ),
          
          // Konten berita
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Memuat berita...'),
                      ],
                    ),
                  )
                : _news.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.article_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Tidak ada berita tersedia',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Coba refresh atau pilih kategori lain',
                              style: TextStyle(
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          itemCount: _news.length,
                          itemBuilder: (context, index) {
                            return _buildNewsCard(_news[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
