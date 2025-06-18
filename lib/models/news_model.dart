import 'package:flutter/material.dart'; // Import ini yang kurang!

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
    // Extract data dari PocketBase record
    final String newsContent = record.getStringValue('news') ?? '';
    final String newsDetail = record.getStringValue('news_detail') ?? '';
    final String imageFile = record.getStringValue('Gambar') ?? '';
    final String category = record.getStringValue('category') ?? 'Umum'; // Field category terpisah
    
    // Parse title, author, dan source dari field news
    List<String> newsParts = newsContent.split('|');
    String title = newsParts.isNotEmpty ? newsParts[0].trim() : 'Judul Berita';
    String author = newsParts.length > 1 ? newsParts[1].trim() : 'Admin';
    String source = newsParts.length > 2 ? newsParts[2].trim() : 'KlikBerita';
    
    // Generate description dari news_detail (ambil 150 karakter pertama)
    String description = newsDetail.length > 150 
        ? '${newsDetail.substring(0, 150)}...'
        : newsDetail;
    
    // Generate image URL dari PocketBase
    String baseUrl = 'http://127.0.0.1:8090'; // Sesuaikan dengan server Anda
    String imageUrl = imageFile.isNotEmpty 
        ? '$baseUrl/api/files/berita/${record.id}/$imageFile'
        : 'https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=800&h=400&fit=crop'; // Default image
    
    return NewsModel(
      id: record.id,
      title: title,
      description: description,
      content: newsDetail,
      imageUrl: imageUrl,
      category: category, // Gunakan field category langsung
      author: author,
      publishedAt: DateTime.parse(record.getStringValue('created')),
      source: source,
    );
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
      'news': '$title|$author|$source', // Tidak perlu category di sini lagi
      'news_detail': content,
      'category': category, // Field category terpisah
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
}
