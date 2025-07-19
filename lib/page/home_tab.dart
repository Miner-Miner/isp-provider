// lib/page/home_tab.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:isp_provider/const/route.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late Future<List<Map<String, dynamic>>> _bannersFuture;
  late Future<List<Map<String, dynamic>>> _packagesFuture;

  // For auto-sliding
  final _pageController = PageController(viewportFraction: 0.9);
  Timer? _timer;
  int _currentBanner = 0;
  int _bannerCount = 0;

  @override
  void initState() {
    super.initState();
    _bannersFuture = fetchBanners();
    _packagesFuture = fetchPackages();

    // Once banners are loaded, capture count and start timer
    _bannersFuture.then((banners) {
      if (mounted && banners.isNotEmpty) {
        _bannerCount = banners.length;
        _startAutoSlide();
      }
    }).catchError((_) {
      // ignore errors for auto-slide
    });
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_pageController.hasClients || _bannerCount == 0) return;
      _currentBanner = (_currentBanner + 1) % _bannerCount;
      _pageController.animateToPage(
        _currentBanner,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<List<Map<String, dynamic>>> fetchBanners() async {
    try {
      final raw = await Supabase.instance.client.from('banner').select();
      return List<Map<String, dynamic>>.from(raw as List);
    } catch (e) {
      throw Exception('Failed to load banners: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchPackages() async {
    try {
      final raw = await Supabase.instance.client.from('package').select();
      return List<Map<String, dynamic>>.from(raw as List);
    } catch (e) {
      throw Exception('Failed to load packages: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: your FAB action
        },
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Banners',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          SizedBox(
            height: 180,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _bannersFuture,
              builder: (ctx, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final banners = snap.data!;
                if (banners.isEmpty) {
                  return const Center(child: Text('No banners'));
                }
                return Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: banners.length,
                      onPageChanged: (i) {
                        setState(() => _currentBanner = i);
                      },
                      itemBuilder: (ctx, i) {
                        final b = banners[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              b['url'] as String,
                              fit: BoxFit.cover,
                              loadingBuilder: (ctx, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                    child: CircularProgressIndicator());
                              },
                              errorBuilder: (ctx, _, __) => Container(
                                color: Colors.grey[300],
                                child: const Center(
                                    child: Icon(Icons.broken_image)),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Dots indicator
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(banners.length, (i) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentBanner == i ? 12 : 8,
                            height: _currentBanner == i ? 12 : 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentBanner == i
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey,
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 24),
          const Text('Packages',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          FutureBuilder<List<Map<String, dynamic>>>(
            future: _packagesFuture,
            builder: (ctx, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text('Error: ${snap.error}'));
              }
              final packages = snap.data!;
              if (packages.isEmpty) {
                return const Center(child: Text('No packages'));
              }
              return Column(
                children: packages.map((p) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        packageDetailRoute,
                        arguments: p,
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(p['name'] as String),
                        subtitle: Text(p['description'] as String),
                        trailing: Text('${p['price']} MMK'),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
