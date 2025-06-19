import 'package:pocketbase/pocketbase.dart';

class AuthService {
  // PocketBase instance dengan URL yang benar
  static final PocketBase _pb = PocketBase('http://127.0.0.1:8090');
  static const String collectionName = 'users_berita';
  
  // Getter untuk PocketBase instance
  static PocketBase get pb => _pb;
  
  // Test koneksi PocketBase dengan cara yang lebih sederhana
  static Future<Map<String, dynamic>> testPocketBaseConnection() async {
    try {
      print('🔄 Testing PocketBase connection...');
      print('📍 URL: ${_pb.baseUrl}');
      
      // Test dengan mencoba fetch collections (method yang pasti ada)
      final collections = await _pb.collections.getList();
      print('✅ PocketBase connection successful');
      print('📦 Available collections: ${collections.items.map((c) => c.name).toList()}');
      
      return {
        'success': true,
        'message': 'PocketBase connection successful',
        'collections': collections.items.map((c) => c.name).toList(),
      };
    } catch (e) {
      print('❌ PocketBase connection failed: $e');
      print('🔍 Error type: ${e.runtimeType}');
      if (e is ClientException) {
        print('🔍 ClientException details: ${e.response}');
      }
      return {
        'success': false,
        'message': 'PocketBase connection failed: $e',
        'error': e.toString(),
      };
    }
  }
  
  // Getter untuk mengecek apakah user sudah login
  static bool get isLoggedIn => _pb.authStore.isValid;
  static RecordModel? get currentUser => _pb.authStore.model;
  static String? get authToken => _pb.authStore.token;

  // Initialize auth store listener
  static void initialize() {
    print('🚀 Initializing AuthService...');
    print('📍 PocketBase URL: ${_pb.baseUrl}');
    
    _pb.authStore.onChange.listen((e) {
      print('🔄 Auth state changed: ${_pb.authStore.isValid}');
    });
    
    // Test koneksi saat initialize
    testPocketBaseConnection();
  }

  // Register user baru
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      print('🔄 Registering user: $email');
      
      final record = await _pb.collection(collectionName).create(body: {
        'email': email,
        'password': password,
        'passwordConfirm': password,
        'name': name,
        'emailVisibility': true,
      });

      print('✅ User registered successfully: ${record.id}');
      return {
        'success': true,
        'message': 'Registrasi berhasil! Silakan login.',
        'data': record,
      };
    } on ClientException catch (e) {
      print('❌ Registration failed: ${e.response}');
      String errorMessage = 'Registrasi gagal';
      
      if (e.response.containsKey('data')) {
        final errors = e.response['data'];
        if (errors['email'] != null) {
          errorMessage = 'Email sudah digunakan';
        } else if (errors['password'] != null) {
          errorMessage = 'Password terlalu lemah (minimal 8 karakter)';
        } else if (errors['name'] != null) {
          errorMessage = 'Nama tidak valid';
        }
      } else {
        errorMessage = e.response['message'] ?? errorMessage;
      }
      
      return {
        'success': false,
        'message': errorMessage,
        'errors': e.response,
      };
    } catch (e) {
      print('❌ General registration error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Login user
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔄 Logging in user: $email');
      
      final authData = await _pb.collection(collectionName).authWithPassword(
        email,
        password,
      );

      print('✅ Login successful: ${authData.record?.id}');
      return {
        'success': true,
        'message': 'Login berhasil!',
        'data': {
          'token': authData.token,
          'record': authData.record,
        },
      };
    } on ClientException catch (e) {
      print('❌ Login failed: ${e.response}');
      String errorMessage = 'Login gagal';
      
      if (e.response['message'] != null) {
        if (e.response['message'].toString().contains('Failed to authenticate')) {
          errorMessage = 'Email atau password salah';
        } else {
          errorMessage = e.response['message'];
        }
      }
      
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      print('❌ General login error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Logout user
  static Future<void> logout() async {
    print('🔄 Logging out user...');
    _pb.authStore.clear();
    
    // Clear favorites cache when logging out
    try {
      // Import FavoriteService if not already imported
      // await FavoriteService.clearLocalCache();
    } catch (e) {
      print('⚠️ Error clearing favorites cache: $e');
    }
    
    print('✅ User logged out');
  }

  // Refresh auth token
  static Future<Map<String, dynamic>> refreshAuth() async {
    if (!_pb.authStore.isValid) {
      return {
        'success': false,
        'message': 'No valid auth token',
      };
    }

    try {
      print('🔄 Refreshing auth token...');
      final authData = await _pb.collection(collectionName).authRefresh();
      
      print('✅ Auth token refreshed');
      return {
        'success': true,
        'message': 'Token refreshed successfully',
        'data': {
          'token': authData.token,
          'record': authData.record,
        },
      };
    } on ClientException catch (e) {
      print('❌ Auth refresh failed: ${e.response}');
      await logout();
      return {
        'success': false,
        'message': 'Auth token expired',
      };
    } catch (e) {
      print('❌ General auth refresh error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? email,
  }) async {
    if (!_pb.authStore.isValid || _pb.authStore.model == null) {
      return {
        'success': false,
        'message': 'User not authenticated',
      };
    }

    try {
      final Map<String, dynamic> updateData = {'name': name};
      if (email != null && email.isNotEmpty) {
        updateData['email'] = email;
      }

      final record = await _pb.collection(collectionName).update(
        _pb.authStore.model!.id,
        body: updateData,
      );

      _pb.authStore.save(_pb.authStore.token, record);

      return {
        'success': true,
        'message': 'Profile berhasil diupdate',
        'data': record,
      };
    } on ClientException catch (e) {
      String errorMessage = 'Update profile gagal';
      
      if (e.response.containsKey('data')) {
        final errors = e.response['data'];
        if (errors['email'] != null) {
          errorMessage = 'Email sudah digunakan';
        }
      } else {
        errorMessage = e.response['message'] ?? errorMessage;
      }
      
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Change password
  static Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (!_pb.authStore.isValid || _pb.authStore.model == null) {
      return {
        'success': false,
        'message': 'User not authenticated',
      };
    }

    try {
      await _pb.collection(collectionName).update(
        _pb.authStore.model!.id,
        body: {
          'oldPassword': oldPassword,
          'password': newPassword,
          'passwordConfirm': newPassword,
        },
      );

      return {
        'success': true,
        'message': 'Password berhasil diubah',
      };
    } on ClientException catch (e) {
      String errorMessage = 'Ubah password gagal';
      
      if (e.response.containsKey('data')) {
        final errors = e.response['data'];
        if (errors['oldPassword'] != null) {
          errorMessage = 'Password lama salah';
        } else if (errors['password'] != null) {
          errorMessage = 'Password baru terlalu lemah';
        }
      } else {
        errorMessage = e.response['message'] ?? errorMessage;
      }
      
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Request password reset
  static Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      await _pb.collection(collectionName).requestPasswordReset(email);
      
      return {
        'success': true,
        'message': 'Link reset password telah dikirim ke email Anda',
      };
    } on ClientException catch (e) {
      return {
        'success': false,
        'message': e.response['message'] ?? 'Gagal mengirim reset password',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Request email verification
  static Future<Map<String, dynamic>> requestEmailVerification() async {
    if (!_pb.authStore.isValid || _pb.authStore.model == null) {
      return {
        'success': false,
        'message': 'User not authenticated',
      };
    }

    try {
      await _pb.collection(collectionName).requestVerification(
        _pb.authStore.model!.getStringValue('email'),
      );
      
      return {
        'success': true,
        'message': 'Link verifikasi telah dikirim ke email Anda',
      };
    } on ClientException catch (e) {
      return {
        'success': false,
        'message': e.response['message'] ?? 'Gagal mengirim verifikasi email',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Get user by ID
  static Future<RecordModel?> getUserById(String id) async {
    try {
      final record = await _pb.collection(collectionName).getOne(id);
      return record;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // Get all users (admin only)
  static Future<List<RecordModel>> getAllUsers({
    int page = 1,
    int perPage = 50,
    String? filter,
    String? sort,
  }) async {
    try {
      final resultList = await _pb.collection(collectionName).getList(
        page: page,
        perPage: perPage,
        filter: filter,
        sort: sort ?? '-created',
      );
      return resultList.items;
    } catch (e) {
      print('Error getting users: $e');
      return [];
    }
  }

  // Check if email exists
  static Future<bool> emailExists(String email) async {
    try {
      await _pb.collection(collectionName).getFirstListItem(
        'email = "$email"',
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get user stats
  static Future<Map<String, dynamic>> getUserStats() async {
    if (!_pb.authStore.isValid || _pb.authStore.model == null) {
      return {
        'success': false,
        'message': 'User not authenticated',
      };
    }

    try {
      final user = _pb.authStore.model!;
      
      return {
        'success': true,
        'data': {
          'id': user.id,
          'name': user.getStringValue('name'),
          'email': user.getStringValue('email'),
          'verified': user.getBoolValue('verified'),
          'created': user.getStringValue('created'),
          'updated': user.getStringValue('updated'),
        },
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
}
