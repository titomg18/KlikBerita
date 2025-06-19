import 'package:flutter/material.dart';
import '../services/Auth.dart';

class CommentModel {
  final String id;
  final String newsId;
  final String userId;
  final String userName;
  final String userEmail;
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;

  CommentModel({
    required this.id,
    required this.newsId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor untuk membuat CommentModel dari PocketBase Record
  factory CommentModel.fromPocketBase(dynamic record) {
    try {
      print('📝 Parsing comment record: ${record.id}');
      
      // Get basic data first
      final userId = record.getStringValue('user') ?? '';
      final commentText = record.getStringValue('Komentar') ?? '';
      
      print('📝 User ID: $userId');
      print('📝 Comment text: $commentText');
      print('📝 Expand data available: ${record.expand != null}');
      
      String userName = 'Unknown User';
      String userEmail = '';
      
      // Try to get user data from expanded relation
      if (record.expand != null && record.expand!.containsKey('user')) {
        final userData = record.expand!['user'];
        print('📝 User data type: ${userData.runtimeType}');
        print('📝 User data: $userData');
        
        // Handle different possible formats of expanded user data
        if (userData is List && userData.isNotEmpty) {
          // If userData is a list, take the first item
          final user = userData.first;
          if (user is Map<String, dynamic>) {
            userName = user['name']?.toString() ?? 'User';
            userEmail = user['email']?.toString() ?? '';
            print('📝 User from expand (list-map): $userName');
          } else if (user.toString().contains('RecordModel')) {
            // If it's a RecordModel, try to access its data
            try {
              userName = user.getStringValue('name') ?? 'User';
              userEmail = user.getStringValue('email') ?? '';
              print('📝 User from expand (list-record): $userName');
            } catch (e) {
              print('📝 Error accessing RecordModel in list: $e');
              userName = 'User';
            }
          }
        } else if (userData is Map<String, dynamic>) {
          // If userData is a map directly
          userName = userData['name']?.toString() ?? 'User';
          userEmail = userData['email']?.toString() ?? '';
          print('📝 User from expand (map): $userName');
        } else if (userData.toString().contains('RecordModel')) {
          // If userData is a RecordModel directly
          try {
            userName = userData.getStringValue('name') ?? 'User';
            userEmail = userData.getStringValue('email') ?? '';
            print('📝 User from expand (record): $userName');
          } catch (e) {
            print('📝 Error accessing RecordModel: $e');
            userName = 'User';
          }
        } else {
          print('📝 Unknown userData format: ${userData.runtimeType}');
          userName = 'User';
        }
      } else {
        print('📝 No expand data found, trying fallback methods');
        
        // Fallback 1: Check if it's the current user
        final currentUser = AuthService.currentUser;
        if (currentUser != null && currentUser.id == userId) {
          userName = currentUser.getStringValue('name') ?? 'You';
          userEmail = currentUser.getStringValue('email') ?? '';
          print('📝 User from current auth: $userName');
        } else {
          // Fallback 2: Use a generic name based on user ID
          userName = 'User ${userId.substring(0, 8)}';
          print('📝 Using fallback username: $userName');
        }
      }
      
      final commentModel = CommentModel(
        id: record.id ?? '',
        newsId: record.getStringValue('berita') ?? '',
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        comment: commentText,
        createdAt: DateTime.tryParse(record.getStringValue('created')) ?? DateTime.now(),
        updatedAt: DateTime.tryParse(record.getStringValue('updated')) ?? DateTime.now(),
      );
      
      print('✅ Successfully parsed comment with user: $userName');
      return commentModel;
      
    } catch (e) {
      print('❌ Error parsing comment from PocketBase: $e');
      print('❌ Record data: ${record.toJson()}');
      
      // Return a safe fallback comment
      return CommentModel(
        id: record.id ?? 'unknown',
        newsId: record.getStringValue('berita') ?? '',
        userId: record.getStringValue('user') ?? '',
        userName: 'User',
        userEmail: '',
        comment: record.getStringValue('Komentar') ?? 'Error loading comment',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  // Factory constructor untuk membuat CommentModel dari JSON
  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] ?? '',
      newsId: json['newsId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userEmail: json['userEmail'] ?? '',
      comment: json['comment'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  // Method untuk convert CommentModel ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'newsId': newsId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Method untuk convert ke PocketBase format
  Map<String, dynamic> toPocketBase() {
    return {
      'berita': newsId,
      'user': userId,
      'Komentar': comment,
    };
  }

  // Helper method untuk mendapatkan inisial nama user
  String getUserInitials() {
    if (userName.isEmpty) return '?';
    
    final words = userName.trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    } else {
      return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'.toUpperCase();
    }
  }

  // Helper method untuk format waktu relatif
  String getRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return getFormattedDate();
    }
  }

  // Helper method untuk format tanggal Indonesia
  String getFormattedDate() {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    
    return '${createdAt.day} ${months[createdAt.month - 1]} ${createdAt.year}';
  }

  // Helper method untuk format waktu lengkap
  String getFormattedDateTime() {
    return '${getFormattedDate()} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  // Helper method untuk cek apakah komentar sudah diedit
  bool isEdited() {
    return updatedAt.isAfter(createdAt.add(Duration(seconds: 1)));
  }

  // Helper method untuk mendapatkan warna avatar berdasarkan nama
  Color getAvatarColor() {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    
    final index = userName.hashCode % colors.length;
    return colors[index.abs()];
  }

  // Helper method untuk mendapatkan preview komentar (untuk list)
  String getCommentPreview({int maxLength = 100}) {
    if (comment.length <= maxLength) return comment;
    
    // Cari spasi terakhir dalam batas maxLength
    int cutIndex = maxLength;
    while (cutIndex > 0 && comment[cutIndex] != ' ') {
      cutIndex--;
    }
    
    return '${comment.substring(0, cutIndex)}...';
  }

  // Helper method untuk validasi komentar
  static String? validateComment(String? text) {
    if (text == null || text.trim().isEmpty) {
      return 'Komentar tidak boleh kosong';
    }
    
    if (text.trim().length < 3) {
      return 'Komentar minimal 3 karakter';
    }
    
    if (text.trim().length > 1000) {
      return 'Komentar maksimal 1000 karakter';
    }
    
    return null; // Valid
  }

  // Helper method untuk cek apakah user adalah pemilik komentar
  bool isOwnedBy(String currentUserId) {
    return userId == currentUserId;
  }

  // Helper method untuk mendapatkan status komentar
  String getStatus() {
    if (isEdited()) {
      return 'Diedit ${getRelativeTime()}';
    } else {
      return getRelativeTime();
    }
  }

  // Copy with method untuk update komentar
  CommentModel copyWith({
    String? id,
    String? newsId,
    String? userId,
    String? userName,
    String? userEmail,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CommentModel(
      id: id ?? this.id,
      newsId: newsId ?? this.newsId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CommentModel(id: $id, userName: $userName, comment: ${getCommentPreview()})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is CommentModel &&
        other.id == id &&
        other.comment == comment &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^ comment.hashCode ^ updatedAt.hashCode;
  }
}
