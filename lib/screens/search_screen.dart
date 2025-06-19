import 'package:flutter/material.dart';
import 'dart:async';
import '../models/news_model.dart';
import '../services/news_service.dart';
import '../services/Auth.dart';
import 'news_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  
  List<NewsModel> _searchResults = [];
  List<NewsModel> _allNews = [];
  List<String> _suggestions = [];
  
  bool _isLoading = false;
  bool _hasSearched = false;
  bool _showSuggestions = false;
  String _currentQuery = '';
  
  Timer? _debounceTimer;
  AnimationController? _fadeController;
  AnimationController? _slideController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAllNews();
    _setupSearchListener();
    _setupFocusListener();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController!,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController!,
      curve: Curves.easeOutCubic,
    ));
  }

  void _setupSearchListener() {
    _searchController.addListener(() {
      final query = _searchController.text;
      
      // Cancel previous timer
      _debounceTimer?.cancel();
      
      // Real-time search dengan debounce (seperti jQuery)
      _debounceTimer = Timer(Duration(milliseconds: 300), () {
        if (query.isNotEmpty) {
          _performRealTimeSearch(query);
          _generateSuggestions(query);
        } else {
          _clearResults();
        }
      });
      
      setState(() {
        _showSuggestions = query.isNotEmpty && _focusNode.hasFocus;
      });
    });
  }

  void _setupFocusListener() {
    _focusNode.addListener(() {
      setState(() {
        _showSuggestions = _searchController.text.isNotEmpty && _focusNode.hasFocus;
      });
    });
  }

  Future<void> _loadAllNews() async {
    try {
      final news = await NewsService.getAllNews();
      setState(() {
        _allNews = news;
      });
    } catch (e) {
      print('Error loading news: $e');
    }
  }

  // Real-time search seperti jQuery autocomplete
  void _performRealTimeSearch(String query) {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _currentQuery = query.trim();
    });

    // Simulate jQuery-like instant search
    final results = _filterNews(query.trim());
    
    setState(() {
      _searchResults = results;
      _hasSearched = true;
      _isLoading = false;
    });

    // Animate results
    _fadeController?.forward();
    _slideController?.forward();
  }

  // Filter news seperti jQuery filter function
  List<NewsModel> _filterNews(String query) {
    final lowerQuery = query.toLowerCase();
    
    return _allNews.where((news) {
      return news.title.toLowerCase().contains(lowerQuery) ||
             news.description.toLowerCase().contains(lowerQuery) ||
             news.content.toLowerCase().contains(lowerQuery) ||
             news.category.toLowerCase().contains(lowerQuery) ||
             news.author.toLowerCase().contains(lowerQuery) ||
             news.source.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Generate suggestions seperti jQuery autocomplete
  void _generateSuggestions(String query) {
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    final lowerQuery = query.toLowerCase();
    Set<String> suggestionSet = {};

    // Extract suggestions from news data
    for (var news in _allNews) {
      // Title suggestions
      final titleWords = news.title.toLowerCase().split(' ');
      for (var word in titleWords) {
        if (word.contains(lowerQuery) && word.length > 2) {
          suggestionSet.add(word);
        }
      }
      
      // Category suggestions
      if (news.category.toLowerCase().contains(lowerQuery)) {
        suggestionSet.add(news.category);
      }
      
      // Author suggestions
      if (news.author.toLowerCase().contains(lowerQuery)) {
        suggestionSet.add(news.author);
      }
    }

    // Add predefined suggestions
    final predefined = [
      'teknologi', 'indonesia', 'ekonomi', 'olahraga', 
      'pendidikan', 'wisata', 'politik', 'kesehatan'
    ];
    
    for (var suggestion in predefined) {
      if (suggestion.contains(lowerQuery)) {
        suggestionSet.add(suggestion);
      }
    }

    setState(() {
      _suggestions = suggestionSet.take(5).toList();
    });
  }

  void _clearResults() {
    setState(() {
      _searchResults = [];
      _hasSearched = false;
      _suggestions = [];
      _currentQuery = '';
    });
    _fadeController?.reset();
    _slideController?.reset();
  }

  void _selectSuggestion(String suggestion) {
    _searchController.text = suggestion;
    _focusNode.unfocus();
    _performRealTimeSearch(suggestion);
    setState(() {
      _showSuggestions = false;
    });
  }

  // jQuery-like highlight function
  Widget _highlightText(String text, String query, TextStyle style) {
    if (query.isEmpty) {
      return Text(text, style: style);
    }

    final List<TextSpan> spans = [];
    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase();
    
    int start = 0;
    int index = lowerText.indexOf(lowerQuery);
    
    while (index != -1) {
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: style,
        ));
      }
      
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
    
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: style,
      ));
    }
    
    return RichText(
      text: TextSpan(children: spans),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  // jQuery-like fade in animation for results
  Widget _buildAnimatedResultCard(NewsModel news, int index) {
    return AnimatedBuilder(
      animation: _fadeAnimation!,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation!,
          child: SlideTransition(
            position: _slideAnimation!,
            child: _buildResultCard(news, index),
          ),
        );
      },
    );
  }

  Widget _buildResultCard(NewsModel news, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              elevation: 2,
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
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image with loading animation
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 80,
                          height: 80,
                          child: Image.network(
                            news.imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey[600],
                                  size: 30,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      
                      SizedBox(width: 12),
                      
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category badge
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: news.getCategoryColor(),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                news.category,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            
                            SizedBox(height: 8),
                            
                            // Title with highlighting
                            _highlightText(
                              news.title,
                              _currentQuery,
                              TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            
                            SizedBox(height: 6),
                            
                            // Description with highlighting
                            _highlightText(
                              news.description,
                              _currentQuery,
                              TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700]!,
                                height: 1.3,
                              ),
                            ),
                            
                            SizedBox(height: 8),
                            
                            // Meta info
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                                SizedBox(width: 4),
                                Text(
                                  _formatTime(news.publishedAt),
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                                SizedBox(width: 12),
                                Icon(Icons.person, size: 14, color: Colors.grey[600]),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    news.author,
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
            ),
          ),
        );
      },
    );
  }

  // jQuery-like suggestions dropdown
  Widget _buildSuggestionsDropdown() {
    if (!_showSuggestions || _suggestions.isEmpty) {
      return SizedBox.shrink();
    }

    return Positioned(
      top: 60,
      left: 16,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = _suggestions[index];
              return InkWell(
                onTap: () => _selectSuggestion(suggestion),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: index < _suggestions.length - 1
                        ? Border(bottom: BorderSide(color: Colors.grey[200]!))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 12),
                      Expanded(
                        child: _highlightText(
                          suggestion,
                          _currentQuery,
                          TextStyle(fontSize: 14, color: Colors.grey[800]!),
                        ),
                      ),
                      Icon(Icons.north_west, size: 14, color: Colors.grey[400]),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
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

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    _fadeController?.dispose();
    _slideController?.dispose();
    super.dispose();
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
        actions: [
          // Debug info button
          if (!AuthService.isLoggedIn)
            IconButton(
              icon: Icon(Icons.info_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Info Pencarian'),
                    content: Text(
                      'Anda sedang mencari di data demo.\n\n'
                      'Login untuk mengakses pencarian di database lengkap dengan lebih banyak berita.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              tooltip: 'Info pencarian',
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar dengan suggestions dropdown
          Container(
            color: Colors.blue[600],
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Ketik untuk mencari secara real-time...',
                      prefixIcon: _isLoading
                          ? Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.blue[600],
                                ),
                              ),
                            )
                          : Icon(Icons.search, color: Colors.blue[600]),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey[600]),
                              onPressed: () {
                                _searchController.clear();
                                _clearResults();
                                _focusNode.unfocus();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (query) {
                      _focusNode.unfocus();
                      _performRealTimeSearch(query);
                    },
                  ),
                ),
                _buildSuggestionsDropdown(),
              ],
            ),
          ),
          
          // Results dengan animasi
          Expanded(
            child: !_hasSearched
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 800),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: 0.8 + (0.2 * value),
                              child: Opacity(
                                opacity: value,
                                child: Icon(
                                  Icons.search,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Pencarian Real-time',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Mulai ketik untuk melihat hasil secara langsung',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.flash_on, color: Colors.orange, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Fitur jQuery-like:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                '• Real-time search saat mengetik\n• Auto-complete suggestions\n• Smooth animations\n• Instant highlighting',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ],
                          ),
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
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Tidak ada hasil',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tidak ditemukan berita untuk "$_currentQuery"',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          // Results header dengan animasi
                          AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            width: double.infinity,
                            padding: EdgeInsets.all(16),
                            color: Colors.white,
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Ditemukan ${_searchResults.length} berita untuk "$_currentQuery"',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'REAL-TIME',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Results list dengan staggered animation
                          Expanded(
                            child: ListView.builder(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                return _buildAnimatedResultCard(_searchResults[index], index);
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
