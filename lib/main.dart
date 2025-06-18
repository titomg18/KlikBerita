import 'package:flutter/material.dart';
import 'services/Auth.dart';
import 'screens/home_screen.dart';
import 'screens/Auth/login_screen.dart';
import 'services/news_service.dart'; // Perbaiki dari 'services/NewsService.dart'

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Starting KlikBerita App...');
  
  // Initialize AuthService
  AuthService.initialize();
  
  // Debug PocketBase connection on startup
  print('🔧 Running initial debug check...');
  try {
    await NewsService.debugPocketBase();
  } catch (e) {
    print('❌ Initial debug failed: $e');
  }
  
  runApp(const KlikBeritaApp());
}

class KlikBeritaApp extends StatelessWidget {
  const KlikBeritaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KlikBerita',
      theme: ThemeData(
        // Tema aplikasi
        primarySwatch: Colors.blue,
        primaryColor: Colors.blue[600],
        
        // Font theme
        fontFamily: 'Roboto',
        
        // AppBar theme
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        
        // Card theme
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        
        // Button theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        
        // Input decoration theme
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
          ),
        ),
      ),
      
      // Splash screen untuk check auth status
      home: SplashScreen(),
      
      // Debug banner
      debugShowCheckedModeBanner: false,
    );
  }
}

// Splash screen untuk mengecek status autentikasi
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Simulasi loading
    await Future.delayed(Duration(seconds: 2));
    
    // Cek apakah user sudah login
    if (AuthService.isLoggedIn) {
      // Coba refresh token untuk memastikan masih valid
      final refreshResult = await AuthService.refreshAuth();
      
      if (refreshResult['success']) {
        // Token valid, langsung ke home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        // Token expired, ke login screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    } else {
      // Belum login, ke login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[600],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo aplikasi
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                Icons.article,
                size: 60,
                color: Colors.blue[600],
              ),
            ),
            
            SizedBox(height: 32),
            
            // Nama aplikasi
            Text(
              'KlikBerita',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            SizedBox(height: 8),
            
            Text(
              'Berita Terkini Indonesia',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            
            SizedBox(height: 48),
            
            // Loading indicator
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            
            SizedBox(height: 16),
            
            Text(
              'Memuat aplikasi...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
