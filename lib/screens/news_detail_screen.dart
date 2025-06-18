import 'package:flutter/material.dart';
import '../models/news_model.dart';
import '../services/news_service.dart';
import '../services/favorite_service.dart';

class NewsDetailScreen extends StatefulWidget {
  final String newsId;

  const NewsDetailScreen({
    Key? key,
    required this.newsId,
  }) : super(key: key);

  @override
  _NewsDetailScreenState createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  NewsModel? _news;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNewsDetail();
  }

  Future<void> _loadNewsDetail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final news = await NewsService.getNewsById(widget.newsId);
      setState(() {
        _news = news;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat detail berita: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuat detail berita...'),
                ],
              ),
            )
          : _news == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Berita tidak ditemukan',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Kembali'),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    // App Bar dengan gambar
                    SliverAppBar(
                      expandedHeight: 300,
                      pinned: true,
                      backgroundColor: Colors.blue[600],
                      flexibleSpace: FlexibleSpaceBar(
                        background: Image.network(
                          _news!.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
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
                      actions: [
                        // Tombol favorite
                        IconButton(
                          icon: Icon(
                            FavoriteService.isFavorite(_news!.id) 
                                ? Icons.favorite 
                                : Icons.favorite_border,
                            color: FavoriteService.isFavorite(_news!.id) 
                                ? Colors.red 
                                : Colors.white,
                          ),
                          onPressed: () => _toggleFavorite(_news!),
                        ),
                        IconButton(
                          icon: Icon(Icons.share),
                          onPressed: () {
                            // Implementasi share (untuk saat ini hanya menampilkan snackbar)
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Fitur share akan segera tersedia')),
                            );
                          },
                        ),
                      ],
                    ),
                    
                    // Konten berita
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Kategori dan waktu
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor(_news!.category),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    _news!.category,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  _formatTime(_news!.publishedAt),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            
                            SizedBox(height: 16),
                            
                            // Judul berita
                            Text(
                              _news!.title,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                height: 1.3,
                              ),
                            ),
                            
                            SizedBox(height: 16),
                            
                            // Info author dan source
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.blue[600],
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _news!.author,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          _news!.source,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            SizedBox(height: 24),
                            
                            // Deskripsi
                            Text(
                              _news!.description,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[700],
                                height: 1.5,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            
                            SizedBox(height: 20),
                            
                            // Garis pemisah
                            Divider(thickness: 1),
                            
                            SizedBox(height: 20),
                            
                            // Konten berita
                            Text(
                              _news!.content,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                height: 1.6,
                              ),
                            ),
                            
                            SizedBox(height: 32),
                            
                            // Footer
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.blue[600],
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Terima kasih telah membaca berita dari ${_news!.source}',
                                      style: TextStyle(
                                        color: Colors.blue[800],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
