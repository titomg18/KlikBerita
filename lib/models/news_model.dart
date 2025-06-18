import 'package:flutter/material.dart';

class NewsModel {
  final String id;
  final String title;
  final String description;
  final String content;
  final String imageUrl;
  final String category;
  final String author;
  final DateTime publishedAt;
  final String source;

  NewsModel({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.imageUrl,
    required this.category,
    required this.author,
    required this.publishedAt,
    required this.source,
  });

  // Factory constructor untuk membuat NewsModel dari PocketBase Record
  factory NewsModel.fromPocketBase(dynamic record) {
    try {
      // Extract data dari PocketBase record sesuai struktur collection 'berita'
      final String newsTitle = record.getStringValue('berita') ?? 'Judul Berita';
      final String newsContent = record.getStringValue('detail_berita') ?? '';
      final String imageFile = record.getStringValue('Gambar') ?? '';
      final String category = record.getStringValue('category') ?? 'Umum';
      
      // Parse author dan source dari title jika menggunakan format "Title|Author|Source"
      String cleanTitle = newsTitle;
      String author = 'Admin KlikBerita';
      String source = 'KlikBerita';
      
      if (newsTitle.contains('|')) {
        List<String> parts = newsTitle.split('|');
        cleanTitle = parts[0].trim();
        if (parts.length >= 2) {
          author = parts[1].trim();
        }
        if (parts.length >= 3) {
          source = parts[2].trim();
        }
      }
      
      // Generate description dari content (ambil 200 karakter pertama)
      String description = '';
      if (newsContent.isNotEmpty) {
        // Remove HTML tags if any and get first 200 characters
        String cleanContent = newsContent.replaceAll(RegExp(r'<[^>]*>'), '');
        description = cleanContent.length > 200 
            ? '${cleanContent.substring(0, 200)}...'
            : cleanContent;
      }
      
      // Generate image URL dari PocketBase
      String baseUrl = 'http://127.0.0.1:8090'; // Sesuaikan dengan server Anda
      String imageUrl = '';
      
      if (imageFile.isNotEmpty) {
        // Fix: Use the correct collection name directly
        imageUrl = '$baseUrl/api/files/berita/${record.id}/$imageFile';
      } else {
        // Use default image based on category
        imageUrl = _getDefaultImageByCategory(category);
      }
      
      // Parse created date
      DateTime publishedAt;
      try {
        publishedAt = DateTime.parse(record.getStringValue('created'));
      } catch (e) {
        publishedAt = DateTime.now();
      }
      
      return NewsModel(
        id: record.id,
        title: cleanTitle,
        description: description,
        content: newsContent,
        imageUrl: imageUrl,
        category: category,
        author: author,
        publishedAt: publishedAt,
        source: source,
      );
    } catch (e) {
      print('❌ Error parsing PocketBase record: $e');
      // Return a default NewsModel to prevent crashes
      return NewsModel(
        id: record.id ?? 'unknown',
        title: 'Error Loading News',
        description: 'Terjadi kesalahan saat memuat berita',
        content: 'Konten tidak dapat dimuat',
        imageUrl: _getDefaultImageByCategory('Umum'),
        category: 'Umum',
        author: 'System',
        publishedAt: DateTime.now(),
        source: 'KlikBerita',
      );
    }
  }

  // Helper method untuk mendapatkan default image berdasarkan kategori
  static String _getDefaultImageByCategory(String category) {
    switch (category.toLowerCase()) {
      case 'teknologi':
        return 'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=800&h=400&fit=crop';
      case 'olahraga':
        return 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800&h=400&fit=crop';
      case 'ekonomi':
        return 'https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?w=800&h=400&fit=crop';
      case 'pendidikan':
        return 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=800&h=400&fit=crop';
      case 'wisata':
        return 'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=800&h=400&fit=crop';
      case 'politik':
        return 'https://images.unsplash.com/photo-1529107386315-e1a2ed48a620?w=800&h=400&fit=crop';
      case 'kesehatan':
        return 'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=800&h=400&fit=crop';
      case 'hiburan':
        return 'https://images.unsplash.com/photo-1489599904472-af1b7f54a3ef?w=800&h=400&fit=crop';
      default:
        return 'https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=800&h=400&fit=crop';
    }
  }

  // Alternative method to generate PocketBase image URL
  static String generatePocketBaseImageUrl({
    required String baseUrl,
    required String collectionName,
    required String recordId,
    required String fileName,
  }) {
    if (fileName.isEmpty) return _getDefaultImageByCategory('Umum');
    return '$baseUrl/api/files/$collectionName/$recordId/$fileName';
  }

  // Factory constructor untuk membuat NewsModel dari JSON (backward compatibility)
  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      content: json['content'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      category: json['category'] ?? '',
      author: json['author'] ?? '',
      publishedAt: DateTime.parse(json['publishedAt'] ?? DateTime.now().toIso8601String()),
      source: json['source'] ?? '',
    );
  }

  // Method untuk convert NewsModel ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'content': content,
      'imageUrl': imageUrl,
      'category': category,
      'author': author,
      'publishedAt': publishedAt.toIso8601String(),
      'source': source,
    };
  }

  // Method untuk convert ke PocketBase format
  Map<String, dynamic> toPocketBase() {
    return {
      'berita': '$title|$author|$source',
      'detail_berita': content,
      'category': category,
      // Gambar akan dihandle terpisah sebagai file upload
    };
  }

  // Helper method untuk mendapatkan warna kategori
  Color getCategoryColor() {
    switch (category.toLowerCase()) {
      case 'teknologi':
        return Color(0xFF2196F3); // Blue
      case 'olahraga':
        return Color(0xFF4CAF50); // Green
      case 'ekonomi':
        return Color(0xFFFF9800); // Orange
      case 'pendidikan':
        return Color(0xFF9C27B0); // Purple
      case 'wisata':
        return Color(0xFF009688); // Teal
      case 'politik':
        return Color(0xFFF44336); // Red
      case 'kesehatan':
        return Color(0xFF8BC34A); // Light Green
      case 'hiburan':
        return Color(0xFFE91E63); // Pink
      default:
        return Color(0xFF757575); // Grey
    }
  }

  // Helper method untuk mendapatkan icon kategori
  IconData getCategoryIcon() {
    switch (category.toLowerCase()) {
      case 'teknologi':
        return Icons.computer;
      case 'olahraga':
        return Icons.sports_soccer;
      case 'ekonomi':
        return Icons.trending_up;
      case 'pendidikan':
        return Icons.school;
      case 'wisata':
        return Icons.travel_explore;
      case 'politik':
        return Icons.account_balance;
      case 'kesehatan':
        return Icons.health_and_safety;
      case 'hiburan':
        return Icons.movie;
      default:
        return Icons.article;
    }
  }

  // Helper method untuk mendapatkan deskripsi kategori
  String getCategoryDescription() {
    switch (category.toLowerCase()) {
      case 'teknologi':
        return 'Berita seputar teknologi, gadget, dan inovasi';
      case 'olahraga':
        return 'Berita olahraga nasional dan internasional';
      case 'ekonomi':
        return 'Berita ekonomi, bisnis, dan keuangan';
      case 'pendidikan':
        return 'Berita pendidikan dan dunia akademik';
      case 'wisata':
        return 'Berita pariwisata dan destinasi menarik';
      case 'politik':
        return 'Berita politik dan pemerintahan';
      case 'kesehatan':
        return 'Berita kesehatan dan gaya hidup sehat';
      case 'hiburan':
        return 'Berita hiburan, selebriti, dan entertainment';
      default:
        return 'Berita umum dan informasi terkini';
    }
  }

  // Helper method untuk cek apakah kategori trending
  bool isTrendingCategory() {
    final trendingCategories = ['teknologi', 'olahraga', 'ekonomi', 'politik'];
    return trendingCategories.contains(category.toLowerCase());
  }

  // Helper method untuk format kategori display
  String getFormattedCategory() {
    return category.toUpperCase();
  }

  // Helper method untuk mendapatkan kategori terkait
  List<String> getRelatedCategories() {
    switch (category.toLowerCase()) {
      case 'teknologi':
        return ['Ekonomi', 'Pendidikan'];
      case 'olahraga':
        return ['Kesehatan', 'Hiburan'];
      case 'ekonomi':
        return ['Teknologi', 'Politik'];
      case 'pendidikan':
        return ['Teknologi', 'Kesehatan'];
      case 'wisata':
        return ['Ekonomi', 'Hiburan'];
      case 'politik':
        return ['Ekonomi'];
      case 'kesehatan':
        return ['Olahraga', 'Pendidikan'];
      case 'hiburan':
        return ['Olahraga', 'Wisata'];
      default:
        return [];
    }
  }

  // Helper method untuk mendapatkan estimasi waktu baca
  int getReadingTimeMinutes() {
    // Asumsi rata-rata 200 kata per menit
    final wordCount = content.split(' ').length;
    return (wordCount / 200).ceil();
  }

  // Helper method untuk mendapatkan preview content
  String getContentPreview({int maxLength = 300}) {
    if (content.length <= maxLength) return content;
    
    // Cari titik terakhir dalam batas maxLength
    int cutIndex = maxLength;
    while (cutIndex > 0 && content[cutIndex] != ' ' && content[cutIndex] != '.') {
      cutIndex--;
    }
    
    return '${content.substring(0, cutIndex)}...';
  }

  // Helper method untuk format tanggal Indonesia
  String getFormattedDate() {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    
    return '${publishedAt.day} ${months[publishedAt.month - 1]} ${publishedAt.year}';
  }

  // Helper method untuk format waktu relatif
  String getRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return getFormattedDate();
    }
  }
}
