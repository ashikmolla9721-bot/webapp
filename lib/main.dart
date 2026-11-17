import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF1E3A8A),
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Just Cold Shop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: const WebViewScreen(),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasConnection = true;
  double _progress = 0;
  final String _targetUrl = 'https://justcoldshop.com';

  @override
  void initState() {
    super.initState();
    _checkConnectivityOnInit();
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFFFFFFF))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _progress = progress / 100.0;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(_targetUrl));
  }

  Future<void> _checkConnectivityOnInit() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      setState(() {
        _hasConnection = false;
      });
    }
  }

  Future<void> _reloadPage() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      setState(() {
        _hasConnection = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ইন্টারনেট সংযোগ নেই। দয়া করে চেক করুন।')),
        );
      }
    } else {
      setState(() {
        _hasConnection = true;
      });
      _controller.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await _controller.canGoBack()) {
          _controller.goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: SafeArea(
          child: !_hasConnection
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off, size: 80, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'ইন্টারনেট সংযোগ বিচ্ছিন্ন রয়েছে',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'দয়া করে আপনার ইন্টারনেট কানেকশন চেক করে পুনরায় চেষ্টা করুন।',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _reloadPage,
                          icon: const Icon(Icons.refresh),
                          label: const Text('পুনরায় চেষ্টা করুন'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    WebViewWidget(controller: _controller),
                    if (_isLoading)
                      LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: Colors.transparent,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                      ),
                  ],
                ),
        ),
        bottomNavigationBar: Container(
          color: Colors.white,
          height: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)),
                onPressed: () async {
                  if (await _controller.canGoBack()) {
                    _controller.goBack();
                  }
                },
                tooltip: 'পেছনে যান',
              ),
              IconButton(
                icon: const Icon(Icons.home, color: Color(0xFF1E3A8A)),
                onPressed: () {
                  _controller.loadRequest(Uri.parse(_targetUrl));
                },
                tooltip: 'হোম',
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF1E3A8A)),
                onPressed: _reloadPage,
                tooltip: 'রিফ্রেশ',
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward, color: Color(0xFF1E3A8A)),
                onPressed: () async {
                  if (await _controller.canGoForward()) {
                    _controller.goForward();
                  }
                },
                tooltip: 'সামনে যান',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
