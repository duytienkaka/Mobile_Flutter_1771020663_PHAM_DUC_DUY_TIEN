import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  List bookings = [];
  List groupBookings = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadBookings();
  }

  Future<void> loadBookings() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = await auth.storage.read(key: 'token');

      final data = await auth.api.getMyBookings(token!);
      final groupData = await auth.api.getMyGroupBookings(token!);

      setState(() {
        bookings = data;
        groupBookings = groupData;
      });
    } catch (e) {
      setState(() {
        error = 'Không tải được lịch sử đặt sân';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  void showBookingDetail(Map b) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Chi tiết đặt sân: ${b['courtName']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ngày: ${DateTime.parse(b['startTime']).toLocal().toString().split(' ')[0]}'),
            Text('Giờ bắt đầu: ${DateTime.parse(b['startTime']).toLocal().hour}:${DateTime.parse(b['startTime']).toLocal().minute.toString().padLeft(2, '0')}'),
            Text('Giờ kết thúc: ${DateTime.parse(b['endTime']).toLocal().hour}:${DateTime.parse(b['endTime']).toLocal().minute.toString().padLeft(2, '0')}'),
            Text('Tổng tiền: ${b['totalPrice']} VNĐ'),
            Text('Trạng thái: ${b['status'] ?? 'Unknown'}'),
          ],
        ),
        actions: [
          if (DateTime.parse(b['startTime']).isAfter(DateTime.now()))
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                cancelBooking(b['id']);
              },
              child: const Text('Hủy đặt sân', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> cancelBooking(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hủy đặt sân?'),
        content: const Text('Bạn sẽ được hoàn tiền.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Không')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Có')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final token = await auth.storage.read(key: 'token');

        debugPrint('Canceling booking $id with token $token');
        final response = await auth.api.dio.delete(
          '/api/bookings/$id',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        debugPrint('Cancel response: ${response.statusCode}');

        // Remove the canceled booking from the list
        setState(() {
          bookings.removeWhere((booking) => booking['id'] == id);
        });

        await loadBookings(); // Reload
        await auth.loadProfile(); // Update wallet
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã hủy và hoàn tiền')));
      } catch (e) {
        debugPrint('Cancel error: $e');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi hủy booking')));
      }
    }
  }

  Future<void> payGroupShare(int groupId) async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = await auth.storage.read(key: 'token');

      await auth.api.payGroupShare(token!, groupId);

      await loadBookings();
      await auth.loadProfile();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanh toán thành công')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi thanh toán: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử đặt sân')),
      body: RefreshIndicator(
        onRefresh: loadBookings,
        child: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Text(error!, style: const TextStyle(color: Colors.red)),
            )
          : bookings.isEmpty
          ? const Center(child: Text('Chưa có lịch sử đặt sân'))
          : ListView.builder(
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final b = bookings[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    onTap: () => showBookingDetail(b),
                    leading: const Icon(
                      Icons.history,
                      color: Colors.lightGreen,
                    ),
                    title: Text(
                      b['courtName'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${DateTime.parse(b['startTime']).toLocal().toString().split(' ')[0]} - ${DateTime.parse(b['startTime']).toLocal().hour}:${DateTime.parse(b['startTime']).toLocal().minute.toString().padLeft(2, '0')} → ${DateTime.parse(b['endTime']).toLocal().hour}:${DateTime.parse(b['endTime']).toLocal().minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: (b['status'] == 'Confirmed' && DateTime.parse(b['startTime']).isAfter(DateTime.now()))
                        ? ElevatedButton(
                      onPressed: () => cancelBooking(b['id']),
                      child: const Text('Hủy'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    )
                        : Text(
                      '${b['totalPrice']} VNĐ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.lightGreen,
                      ),
                    ),
                  ),
                );
              },
            ),
      ),
    );
  }
}
