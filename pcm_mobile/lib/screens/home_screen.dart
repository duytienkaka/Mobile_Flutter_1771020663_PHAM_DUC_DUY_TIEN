import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'court_screen.dart';
import 'booking_history_screen.dart';
import 'topup_screen.dart';
import 'user_profile_screen.dart';
import 'booking_screen.dart';
import 'tournament_list_screen.dart';
import 'admin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List courts = [];
  bool courtsLoading = true;
  String? courtsError;
  bool showFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    loadAvailableCourts();
  }

  Future<void> loadAvailableCourts() async {
    setState(() {
      courtsLoading = true;
    });
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = await auth.storage.read(key: 'token');
      if (token == null) {
        throw Exception('token_missing');
      }
      final data = await auth.api.getCourts(token);
      setState(() {
        courts = data;
        courtsError = null;
      });
    } catch (e) {
      String message = 'Không tải được dữ liệu sân';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          message = data['message'].toString();
        } else if (data is String) {
          message = data;
        } else {
          message = e.message ?? message;
        }
      } else if (e.toString().contains('token_missing')) {
        message = 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
      }
      debugPrint('Load courts failed: $message');
      setState(() {
        courtsError = message;
      });
      debugPrint('Courts load error: $e');
    } finally {
      setState(() {
        courtsLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    final pages = [
      _homeTab(auth),
      const CourtScreen(),
      const BookingHistoryScreen(),
      const UserProfileScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF16A34A),
        unselectedItemColor: const Color(0xFF94A3B8),
        elevation: 10,
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Trang chủ'),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer_rounded),
            label: 'Đặt sân',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Lịch sử'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Cá nhân'),
        ],
      ),
    );
  }

  Widget _homeTab(AuthProvider auth) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: loadAvailableCourts,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF16A34A), Color(0xFF0EA5E9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            auth.fullName != null ? 'Xin chào, ${auth.fullName}' : 'Xin chào',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout_outlined, color: Colors.white),
                          tooltip: 'Đăng xuất',
                          onPressed: () async {
                            await auth.logout();
                            if (mounted) {
                              Navigator.pushReplacementNamed(context, '/');
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Phiên bản 2026 · Đặt sân nhanh hơn',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 30),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  auth.walletBalance != null
                                      ? '${auth.walletBalance} VNĐ'
                                      : '--',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Số dư ví',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Nạp tiền'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0F172A),
                              minimumSize: const Size(120, 44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const TopUpScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                'Lối tắt nhanh',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _quickAction(
                    icon: Icons.sports_soccer,
                    label: 'Đặt sân',
                    color: const Color(0xFFDCFCE7),
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                  const SizedBox(width: 12),
                  _quickAction(
                    icon: Icons.emoji_events,
                    label: 'Giải đấu',
                    color: const Color(0xFFE0F2FE),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TournamentListScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  _quickAction(
                    icon: Icons.history_toggle_off,
                    label: 'Lịch sử',
                    color: const Color(0xFFF4F4F5),
                    onTap: () => setState(() => _currentIndex = 2),
                  ),
                ],
              ),

              if (auth.role == 'Admin') ...[
                const SizedBox(height: 16),
                _adminCard(),
              ],

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Sân nổi bật',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => setState(() => showFavoritesOnly = !showFavoritesOnly),
                        child: Row(
                          children: [
                            Icon(
                              showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
                              color: showFavoritesOnly ? Colors.red : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 6),
                            Text(showFavoritesOnly ? 'Ưa thích' : 'Tất cả'),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _currentIndex = 1),
                        child: const Text('Xem tất cả'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 190,
                child: courtsLoading
                    ? const Center(child: CircularProgressIndicator())
                    : (courtsError != null)
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(courtsError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    courtsLoading = true;
                                  });
                                  loadAvailableCourts();
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Thử lại'),
                              ),
                            ],
                          )
                        : courts.isEmpty
                            ? const Center(child: Text('Không có sân trống'))
                            : ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _filteredCourts(auth).length,
                                separatorBuilder: (_, __) => const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  final court = _filteredCourts(auth)[index];
                                  return _courtCard(court);
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: const Color(0xFF0F172A)),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _courtCard(Map court) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0F172A),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Sân tiêu chuẩn',
                style: TextStyle(
                  color: Color(0xFF1D4ED8),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              court['name']?.toString() ?? 'Sân',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              '${court['pricePerHour'] ?? '--'} VNĐ / giờ',
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingScreen(court: court),
                        ),
                      );
                    },
                    child: const Text('Đặt ngay'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    final auth = Provider.of<AuthProvider>(context, listen: false);
                    final id = (court['id'] ?? court['courtId']) as int?;
                    if (id == null) return;
                    auth.toggleFavoriteCourt(id);
                  },
                  icon: Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      final id = (court['id'] ?? court['courtId']) as int?;
                      final isFav = id != null && auth.isFavoriteCourt(id);
                      return Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.red : const Color(0xFF94A3B8),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _adminCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_outlined, color: Color(0xFFB91C1C)),
              SizedBox(width: 8),
              Text(
                'Khu vực quản trị',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.admin_panel_settings),
            label: const Text('Quản lý Admin'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  List _filteredCourts(AuthProvider auth) {
    if (!showFavoritesOnly) return courts;
    return courts.where((c) {
      final id = (c['id'] ?? c['courtId']) as int?;
      if (id == null) return false;
      return auth.isFavoriteCourt(id);
    }).toList();
  }
}
