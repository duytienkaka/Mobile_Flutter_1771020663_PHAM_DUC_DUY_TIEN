import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'court_screen.dart';
import 'booking_history_screen.dart';
import 'topup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    final pages = [
      _homeTab(auth),
      const CourtScreen(),
      const BookingHistoryScreen(),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person, size: 90, color: Colors.blue),

          const SizedBox(height: 20),

          Text(
            auth.fullName != null ? 'Xin chào ${auth.fullName}' : 'Xin chào',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          Text(
            auth.walletBalance != null
                ? 'Số dư ví: ${auth.walletBalance!.toStringAsFixed(0)} VNĐ'
                : 'Số dư ví: --',
            style: const TextStyle(fontSize: 18),
          ),

          const SizedBox(height: 30),

          ElevatedButton.icon(
            icon: const Icon(Icons.account_balance_wallet),
            label: const Text('Nạp tiền'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TopUpScreen()),
              );
            },
          ),

          const SizedBox(height: 20),

          const Text(
            'Chọn chức năng bên dưới để tiếp tục',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
