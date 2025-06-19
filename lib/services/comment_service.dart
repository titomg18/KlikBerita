import 'package:pocketbase/pocketbase.dart';
import '../models/comment_model.dart';
import 'Auth.dart';

class CommentService {
  // PocketBase instance
  static PocketBase get _pb => AuthService.pb;
  static const String collectionName = 'komentar_berita';
  
  // Get comments for a specific news article
  static Future<List<CommentModel>> getCommentsByNewsId(String newsId) async {
    try {
      print('📝 Loading comments for news: $newsId');
      
      // Get comments - no need for expand since we have name field directly
      final result = await _pb.collection(collectionName).getList(
        filter: 'berita = "$newsId"',
        sort: '-created',
        perPage: 100,
      );
      
      print('✅ Found ${result.items.length} comments');
      
      List<CommentModel> comments = [];
      for (var record in result.items) {
        print('📝 Processing comment record: ${record.id}');
        
        try {
          // Get data directly from record fields
          String commentText = record.getStringValue('Komentar') ?? '';
          String userId = record.getStringValue('user') ?? '';
          String userName = record.getStringValue('name') ?? 'User'; // Use name field directly
          String userEmail = ''; // We don't store email in comment, that's fine
          
          print('📝 Comment: $commentText');
          print('📝 User ID: $userId');
          print('📝 User Name: $userName');
          
          // If name is empty, try to get from current user or fallback
          if (userName.isEmpty || userName == 'User') {
            final currentUser = AuthService.currentUser;
            if (currentUser != null && currentUser.id == userId) {
              userName = currentUser.getStringValue('name') ?? 'You';
              userEmail = currentUser.getStringValue('email') ?? '';
              print('📝 Using current user name: $userName');
            } else {
              // Try to fetch user manually as last resort
              try {
                final userRecord = await _pb.collection('users_berita').getOne(userId);
                userName = userRecord.getStringValue('name') ?? 'User';
                userEmail = userRecord.getStringValue('email') ?? '';
                print('📝 Fetched user name: $userName');
              } catch (e) {
                print('📝 Could not fetch user, using fallback');
                userName = 'User';
              }
            }
          }
          
          final comment = CommentModel(
            id: record.id,
            newsId: record.getStringValue('berita') ?? '',
            userId: userId,
            userName: userName,
            userEmail: userEmail,
            comment: commentText,
            createdAt: DateTime.tryParse(record.getStringValue('created')) ?? DateTime.now(),
            updatedAt: DateTime.tryParse(record.getStringValue('updated')) ?? DateTime.now(),
          );
          
          comments.add(comment);
          print('✅ Successfully created comment with user: $userName');
          
        } catch (e) {
          print('⚠️ Error parsing comment ${record.id}: $e');
          
          // Create minimal fallback comment
          final fallbackComment = CommentModel(
            id: record.id,
            newsId: record.getStringValue('berita') ?? '',
            userId: record.getStringValue('user') ?? '',
            userName: record.getStringValue('name') ?? 'User',
            userEmail: '',
            comment: record.getStringValue('Komentar') ?? 'Error loading comment',
            createdAt: DateTime.tryParse(record.getStringValue('created')) ?? DateTime.now(),
            updatedAt: DateTime.tryParse(record.getStringValue('updated')) ?? DateTime.now(),
          );
          comments.add(fallbackComment);
        }
      }
      
      print('✅ Total parsed comments: ${comments.length}');
      return comments;
      
    } catch (e) {
      print('❌ Error loading comments: $e');
      print('❌ Error type: ${e.runtimeType}');
      if (e is ClientException) {
        print('❌ ClientException response: ${e.response}');
      }
      return [];
    }
  }
  
  // Add a new comment
  static Future<Map<String, dynamic>> addComment({
    required String newsId,
    required String commentText,
  }) async {
    if (!AuthService.isLoggedIn) {
      return {
        'success': false,
        'message': 'User must be logged in to add comments',
      };
    }
    
    if (commentText.trim().isEmpty) {
      return {
        'success': false,
        'message': 'Komentar tidak boleh kosong',
      };
    }
    
    try {
      final currentUser = AuthService.currentUser!;
      final userName = currentUser.getStringValue('name') ?? 'User';
      
      print('💬 Adding comment to news: $newsId');
      print('💬 User ID: ${currentUser.id}');
      print('💬 User name: $userName');
      print('💬 Comment text: $commentText');
      
      // Create comment with name field included
      final record = await _pb.collection(collectionName).create(body: {
        'berita': newsId,
        'user': currentUser.id,
        'name': userName, // Store user name directly
        'Komentar': commentText.trim(),
      });
      
      print('✅ Comment added successfully: ${record.id}');
      
      // Create comment model with the data we just saved
      final newComment = CommentModel(
        id: record.id,
        newsId: record.getStringValue('berita') ?? newsId,
        userId: record.getStringValue('user') ?? currentUser.id,
        userName: record.getStringValue('name') ?? userName,
        userEmail: currentUser.getStringValue('email') ?? '',
        comment: commentText.trim(),
        createdAt: DateTime.tryParse(record.getStringValue('created')) ?? DateTime.now(),
        updatedAt: DateTime.tryParse(record.getStringValue('updated')) ?? DateTime.now(),
      );
      
      return {
        'success': true,
        'message': 'Komentar berhasil ditambahkan',
        'data': newComment,
      };
    } catch (e) {
      print('❌ Error adding comment: $e');
      print('❌ Error type: ${e.runtimeType}');
      if (e is ClientException) {
        print('❌ ClientException response: ${e.response}');
      }
      return {
        'success': false,
        'message': 'Gagal menambahkan komentar: $e',
      };
    }
  }
  
  // Update a comment (only by the comment author)
  static Future<Map<String, dynamic>> updateComment({
    required String commentId,
    required String newText,
  }) async {
    if (!AuthService.isLoggedIn) {
      return {
        'success': false,
        'message': 'User must be logged in to update comments',
      };
    }
    
    if (newText.trim().isEmpty) {
      return {
        'success': false,
        'message': 'Komentar tidak boleh kosong',
      };
    }
    
    try {
      print('✏️ Updating comment: $commentId');
      
      // Check if user owns this comment
      final existingComment = await _pb.collection(collectionName).getOne(commentId);
      if (existingComment.getStringValue('user') != AuthService.currentUser!.id) {
        return {
          'success': false,
          'message': 'Anda hanya bisa mengedit komentar sendiri',
        };
      }
      
      await _pb.collection(collectionName).update(commentId, body: {
        'Komentar': newText.trim(),
      });
      
      print('✅ Comment updated successfully');
      
      return {
        'success': true,
        'message': 'Komentar berhasil diperbarui',
      };
    } catch (e) {
      print('❌ Error updating comment: $e');
      return {
        'success': false,
        'message': 'Gagal memperbarui komentar: $e',
      };
    }
  }
  
  // Delete a comment (only by the comment author)
  static Future<Map<String, dynamic>> deleteComment(String commentId) async {
    if (!AuthService.isLoggedIn) {
      return {
        'success': false,
        'message': 'User must be logged in to delete comments',
      };
    }
    
    try {
      print('🗑️ Deleting comment: $commentId');
      
      // Check if user owns this comment
      final existingComment = await _pb.collection(collectionName).getOne(commentId);
      if (existingComment.getStringValue('user') != AuthService.currentUser!.id) {
        return {
          'success': false,
          'message': 'Anda hanya bisa menghapus komentar sendiri',
        };
      }
      
      await _pb.collection(collectionName).delete(commentId);
      
      print('✅ Comment deleted successfully');
      
      return {
        'success': true,
        'message': 'Komentar berhasil dihapus',
      };
    } catch (e) {
      print('❌ Error deleting comment: $e');
      return {
        'success': false,
        'message': 'Gagal menghapus komentar: $e',
      };
    } 
  }
  
  // Get comment count for a news article
  static Future<int> getCommentCount(String newsId) async {
    try {
      final result = await _pb.collection(collectionName).getList(
        filter: 'berita = "$newsId"',
        perPage: 1, // We only need the count
      );
      
      return result.totalItems;
    } catch (e) {
      print('❌ Error getting comment count: $e');
      return 0;
    }
  }
  
  // Get recent comments by user
  static Future<List<CommentModel>> getCommentsByUser(String userId, {int limit = 10}) async {
    try {
      final result = await _pb.collection(collectionName).getList(
        filter: 'user = "$userId"',
        sort: '-created',
        perPage: limit,
      );
      
      List<CommentModel> comments = [];
      for (var record in result.items) {
        try {
          final comment = CommentModel(
            id: record.id,
            newsId: record.getStringValue('berita') ?? '',
            userId: record.getStringValue('user') ?? '',
            userName: record.getStringValue('name') ?? 'User',
            userEmail: '',
            comment: record.getStringValue('Komentar') ?? '',
            createdAt: DateTime.tryParse(record.getStringValue('created')) ?? DateTime.now(),
            updatedAt: DateTime.tryParse(record.getStringValue('updated')) ?? DateTime.now(),
          );
          comments.add(comment);
        } catch (e) {
          print('⚠️ Error parsing user comment ${record.id}: $e');
        }
      }
      
      return comments;
    } catch (e) {
      print('❌ Error loading user comments: $e');
      return [];
    }
  }
  
  // Search comments
  static Future<List<CommentModel>> searchComments(String query, {String? newsId}) async {
    try {
      String filter = 'Komentar ~ "$query"';
      if (newsId != null) {
        filter += ' && berita = "$newsId"';
      }
      
      final result = await _pb.collection(collectionName).getList(
        filter: filter,
        sort: '-created',
        perPage: 50,
      );
      
      List<CommentModel> comments = [];
      for (var record in result.items) {
        try {
          final comment = CommentModel(
            id: record.id,
            newsId: record.getStringValue('berita') ?? '',
            userId: record.getStringValue('user') ?? '',
            userName: record.getStringValue('name') ?? 'User',
            userEmail: '',
            comment: record.getStringValue('Komentar') ?? '',
            createdAt: DateTime.tryParse(record.getStringValue('created')) ?? DateTime.now(),
            updatedAt: DateTime.tryParse(record.getStringValue('updated')) ?? DateTime.now(),
          );
          comments.add(comment);
        } catch (e) {
          print('⚠️ Error parsing search comment ${record.id}: $e');
        }
      }
      
      return comments;
    } catch (e) {
      print('❌ Error searching comments: $e');
      return [];
    }
  }
  
  // Get comment statistics
  static Future<Map<String, dynamic>> getCommentStats() async {
    if (!AuthService.isLoggedIn) {
      return {
        'success': false,
        'message': 'User not authenticated',
      };
    }
    
    try {
      final userId = AuthService.currentUser!.id;
      
      // Get user's comment count
      final userComments = await _pb.collection(collectionName).getList(
        filter: 'user = "$userId"',
        perPage: 1,
      );
      
      // Get total comments in system
      final totalComments = await _pb.collection(collectionName).getList(
        perPage: 1,
      );
      
      return {
        'success': true,
        'data': {
          'userComments': userComments.totalItems,
          'totalComments': totalComments.totalItems,
        },
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal mengambil statistik komentar: $e',
      };
    }
  }
}
