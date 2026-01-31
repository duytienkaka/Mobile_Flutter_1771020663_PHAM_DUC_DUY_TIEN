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

        setState(() {
          bookings.removeWhere((booking) => booking['id'] == id);
        });

        await loadBookings();
        await auth.loadProfile();
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
                ? Center(child: Text(error!, style: const TextStyle(color: Colors.red)))
                : (bookings.isEmpty && groupBookings.isEmpty)
                    ? const Center(child: Text('Chưa có lịch sử đặt sân'))
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF16A34A), Color(0xFF0EA5E9)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.history_edu, color: Colors.white, size: 32),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tất cả lịch sử',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${bookings.length + groupBookings.length} lượt',
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          if (bookings.isNotEmpty) ...[
                            Text('Đặt sân cá nhân', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            ...bookings.map((b) => _bookingCard(b)).toList(),
                            const SizedBox(height: 12),
                          ],

                          if (groupBookings.isNotEmpty) ...[
                            Text('Đặt sân nhóm', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            ...groupBookings.map((b) => _bookingCard(b, isGroup: true)).toList(),
                          ],
                        ],
                      ),
      ),
    );
  }

  Widget _bookingCard(Map b, {bool isGroup = false}) {
    final start = DateTime.parse(b['startTime']).toLocal();
    final end = DateTime.parse(b['endTime']).toLocal();
    final canCancel = (b['status'] == 'Confirmed' && start.isAfter(DateTime.now()) && !isGroup);
    final priceLabel = b['totalPrice'] != null ? '${b['totalPrice']} VNĐ' : '';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(isGroup ? Icons.groups_3 : Icons.sports_tennis, color: const Color(0xFF16A34A)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b['courtName'] ?? 'Sân',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatDate(start)} | ${_formatTime(start)} → ${_formatTime(end)}',
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                if (priceLabel.isNotEmpty)
                  Text(
                    priceLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 18, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 6),
                    Text(b['status'] ?? 'Unknown', style: const TextStyle(color: Color(0xFF94A3B8))),
                  ],
                ),
                Row(
                  children: [
                    if (isGroup && (b['hasPaid'] == false))
                      TextButton(
                        onPressed: () => payGroupShare(b['groupId']),
                        child: const Text('Thanh toán phần mình'),
                      ),
                    if (canCancel)
                      TextButton(
                        onPressed: () => cancelBooking(b['id']),
                        child: const Text('Hủy', style: TextStyle(color: Colors.red)),
                      )
                    else
                      TextButton(
                        onPressed: () => showBookingDetail(b),
                        child: const Text('Chi tiết'),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final parts = d.toLocal().toString().split(' ').first.split('-');
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  String _formatTime(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
