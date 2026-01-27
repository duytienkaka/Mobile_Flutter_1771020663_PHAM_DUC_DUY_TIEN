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

  @override
  void initState() {
    super.initState();
    loadAvailableCourts();
  }

  Future<void> loadAvailableCourts() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = await auth.storage.read(key: 'token');
      final data = await auth.api.getCourts(token!);
      setState(() {
        courts = data;
      });
    } catch (e) {
      debugPrint('Load courts failed: $e');
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
      appBar: AppBar(
        title: const Text('PCM Booking'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
        ],
      ),

      body: pages[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.indigo,

        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,

        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),

        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer),
            label: 'Đặt sân',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Lịch sử'),
        ],
      ),
    );
  }

  Widget _homeTab(AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.account_circle, size: 90, color: Colors.lightGreen),

          const SizedBox(height: 20),

          Text(
            auth.fullName != null ? 'Xin chào ${auth.fullName}' : 'Xin chào',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.lightGreen,
            ),
          ),

          const SizedBox(height: 20),

          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.lightGreen,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    auth.walletBalance != null
                        ? 'Số dư ví: ${auth.walletBalance} VNĐ'
                        : 'Số dư ví: --',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Nạp tiền'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TopUpScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.emoji_events),
              label: const Text('Giải đấu'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TournamentListScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          if (auth.role == 'Admin') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text('Quản lý Admin'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 30),

          const SizedBox(height: 10),

          Expanded(
            child: courtsLoading
                ? const Center(child: CircularProgressIndicator())
                : courts.isEmpty
                ? const Center(child: Text('Không có sân trống'))
                : ListView.builder(
                    itemCount: courts.length,
                    itemBuilder: (context, index) {
                      final court = courts[index];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.sports_soccer,
                            color: Colors.lightGreen,
                          ),
                          title: Text(court['name']),
                          subtitle: Text('Giá: ${court['pricePerHour']} VNĐ/h'),
                          trailing: ElevatedButton(
                            child: const Text('Đặt'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BookingScreen(court: court),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
