import 'package:flutter/material.dart';
import 'dart:async';
import '../models/news_model.dart';
import '../services/news_service.dart';
import '../services/favorite_service.dart';
import 'news_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<NewsModel> _searchResults = [];
  List<NewsModel> _allNews = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  Timer? _debounceTimer;
  
  // Animation controllers untuk smooth transitions
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Filter options
  String _selectedCategory = 'Semua';
  List<String> _categories = ['Semua', 'Teknologi', 'Olahraga', 'Ekonomi', 'Pendidikan', 'Wisata'];
  
  // Sort options
  String _sortBy = 'Terbaru';
  List<String> _sortOptions = ['Terbaru', 'Terlama', 'A-Z', 'Z-A'];

  @override
  void initState() {
    super.initState();
    _loadAllNews();
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadAllNews() async {
    try {
      final allNews = await NewsService.getAllNews();
      setState(() {
        _allNews = allNews;
      });
    } catch (e) {
      print('Error loading news: $e');
    }
  }

  // Real-time search dengan debouncing (mirip jQuery live search)
  void _onSearchChanged(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    // Start new timer
    _debounceTimer = Timer(Duration(milliseconds: 300), () {
      if (query.trim().isNotEmpty) {
        _performSearch(query);
      } else {
        setState(() {
          _searchResults.clear();
          _hasSearched = false;
        });
        _fadeController.reset();
      }
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    // Start animations
    _fadeController.forward();
    _slideController.forward();

    try {
      // Advanced search logic
      List<NewsModel> results = _allNews.where((news) {
        final matchesQuery = news.title.toLowerCase().contains(query.toLowerCase()) ||
                           news.description.toLowerCase().contains(query.toLowerCase()) ||
                           news.content.toLowerCase().contains(query.toLowerCase()) ||
                           news.author.toLowerCase().contains(query.toLowerCase());
        
        final matchesCategory = _selectedCategory == 'Semua' || 
                              news.category.toLowerCase() == _selectedCategory.toLowerCase();
        
        return matchesQuery && matchesCategory;
      }).toList();

      // Apply sorting
      _applySorting(results);
      
      // Simulate network delay for smooth animation
      await Future.delayed(Duration(milliseconds: 500));
      
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mencari berita: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _applySorting(List<NewsModel> results) {
    switch (_sortBy) {
      case 'Terbaru':
        results.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
        break;
      case 'Terlama':
        results.sort((a, b) => a.publishedAt.compareTo(b.publishedAt));
        break;
      case 'A-Z':
        results.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'Z-A':
        results.sort((a, b) => b.title.compareTo(a.title));
        break;
    }
  }

  // Toggle favorite dengan animasi
  Future<void> _toggleFavorite(NewsModel news) async {
    try {
      final isFavorite = await FavoriteService.toggleFavorite(news);
      
      setState(() {}); // Refresh UI untuk update icon
      
      // Show animated snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: Colors.white,
              ),
              SizedBox(width: 8),
              Text(
                isFavorite 
                    ? 'Ditambahkan ke favorit ❤️' 
                    : 'Dihapus dari favorit 💔'
              ),
            ],
          ),
          backgroundColor: isFavorite ? Colors.green : Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  // Clear search dengan animasi
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults.clear();
      _hasSearched = false;
    });
    _fadeController.reset();
    _slideController.reset();
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'teknologi':
        return Colors.blue;
      case 'olahraga':
        return Colors.green;
      case 'ekonomi':
        return Colors.orange;
      case 'pendidikan':
        return Colors.purple;
      case 'wisata':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

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

  // Animated search result card
  Widget _buildAnimatedSearchResultCard(NewsModel news, int index) {
    final isFavorite = FavoriteService.isFavorite(news.id);
    
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: TweenAnimationBuilder(
          duration: Duration(milliseconds: 300 + (index * 100)),
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, double value, child) {
            return Transform.scale(
              scale: value,
              child: Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NewsDetailScreen(newsId: news.id),
                      ),
                    );
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
                            ),
                          ),
                          
                          // Animated favorite button
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => _toggleFavorite(news),
                              child: TweenAnimationBuilder(
                                duration: Duration(milliseconds: 200),
                                tween: Tween<double>(begin: 1, end: isFavorite ? 1.2 : 1),
                                builder: (context, double scale, child) {
                                  return Transform.scale(
                                    scale: scale,
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
                                  );
                                },
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
                                    color: _getCategoryColor(news.category),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    news.category,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
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
                            
                            // Judul berita dengan highlight
                            RichText(
                              text: _buildHighlightedText(
                                news.title,
                                _searchController.text,
                                TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            
                            SizedBox(height: 8),
                            
                            // Deskripsi berita dengan highlight
                            RichText(
                              text: _buildHighlightedText(
                                news.description,
                                _searchController.text,
                                TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  height: 1.4,
                                ),
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            
                            SizedBox(height: 12),
                            
                            // Author dan source
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
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Highlight search terms (mirip jQuery highlight)
  TextSpan _buildHighlightedText(String text, String query, TextStyle style) {
    if (query.isEmpty) {
      return TextSpan(text: text, style: style);
    }

    final List<TextSpan> spans = [];
    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase();
    
    int start = 0;
    int index = lowerText.indexOf(lowerQuery);
    
    while (index != -1) {
      // Add text before match
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: style,
        ));
      }
      
      // Add highlighted match
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: style.copyWith(
          backgroundColor: Colors.yellow[300],
          fontWeight: FontWeight.bold,
        ),
      ));
      
      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }
    
    // Add remaining text
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: style,
      ));
    }
    
    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Cari Berita',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[600],
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Advanced search header
          Container(
            color: Colors.blue[600],
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Search bar dengan real-time search
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari berita secara real-time...',
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: _clearSearch,
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                  onChanged: _onSearchChanged,
                  onSubmitted: _performSearch,
                ),
                
                SizedBox(height: 12),
                
                // Filter dan Sort options
                Row(
                  children: [
                    // Category filter
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            isExpanded: true,
                            hint: Text('Kategori'),
                            items: _categories.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value!;
                              });
                              if (_searchController.text.isNotEmpty) {
                                _performSearch(_searchController.text);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(width: 8),
                    
                    // Sort options
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _sortBy,
                            isExpanded: true,
                            hint: Text('Urutkan'),
                            items: _sortOptions.map((option) {
                              return DropdownMenuItem(
                                value: option,
                                child: Text(option),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _sortBy = value!;
                              });
                              if (_searchController.text.isNotEmpty) {
                                _performSearch(_searchController.text);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Search results dengan animasi
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Mencari berita...'),
                      ],
                    ),
                  )
                : !_hasSearched
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Pencarian Real-Time',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Ketik untuk mencari berita secara langsung',
                              style: TextStyle(
                                color: Colors.grey[500],
                              ),
                            ),
                            SizedBox(height: 24),
                            
                            // Quick search suggestions
                            Text(
                              'Pencarian Populer:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                'AI',
                                'Teknologi',
                                'Olahraga',
                                'Ekonomi',
                                'Pendidikan',
                                'Wisata',
                              ].map((suggestion) => GestureDetector(
                                onTap: () {
                                  _searchController.text = suggestion;
                                  _performSearch(suggestion);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.blue[300]!),
                                  ),
                                  child: Text(
                                    suggestion,
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              )).toList(),
                            ),
                          ],
                        ),
                      )
                    : _searchResults.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Tidak ada hasil',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Coba kata kunci atau filter yang berbeda',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Results header dengan animasi
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Ditemukan ${_searchResults.length} berita',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      Spacer(),
                                      Text(
                                        'untuk "${_searchController.text}"',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[500],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              // Animated results list
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _searchResults.length,
                                  itemBuilder: (context, index) {
                                    return _buildAnimatedSearchResultCard(_searchResults[index], index);
                                  },
                                ),
                              ),
                            ],
                          ),
          ),
        ],
      ),
    );
  }
}
