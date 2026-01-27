import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class BookingScreen extends StatefulWidget {
  final Map court;

  const BookingScreen({super.key, required this.court});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  double totalPrice = 0;

  DateTime selectedDate = DateTime.now();

  void calculateTotal() {
    if (startTime == null || endTime == null) {
      totalPrice = 0;
      return;
    }

    final start = startTime!.hour;
    final end = endTime!.hour;

    if (end <= start) {
      totalPrice = 0;
      return;
    }

    final hours = end - start;
    totalPrice =
        hours.toDouble() * (widget.court['pricePerHour'] as num).toDouble();
  }

  Future<void> pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );

    if (picked == null) return;

    if (picked.minute != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chỉ được chọn giờ tròn (ví dụ: 18:00)')),
      );
      return;
    }

    setState(() {
      startTime = picked;
      calculateTotal();
    });
  }

  Future<void> pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );

    if (picked == null) return;

    if (picked.minute != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chỉ được chọn giờ tròn (ví dụ: 20:00)')),
      );
      return;
    }

    setState(() {
      endTime = picked;
      calculateTotal();
    });
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> bookCourt() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = await auth.storage.read(key: 'token');

    final start = selectedDate.copyWith(hour: startTime!.hour, minute: 0);

    final end = selectedDate.copyWith(hour: endTime!.hour, minute: 0);

    try {
      debugPrint('Booking court ${widget.court['id']} from $start to $end');
      await auth.api.bookCourt(
        token: token!,
        courtId: widget.court['id'],
        start: start,
        end: end,
      );

      await auth.loadProfile();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đặt sân thành công')));

      Navigator.pop(context);
    } catch (e) {
      debugPrint('Book error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi đặt sân: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final wallet = auth.walletBalance ?? 0;
    final enoughMoney = wallet >= totalPrice;

    return Scaffold(
      appBar: AppBar(title: Text('Đặt ${widget.court['name']}')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.sports_soccer,
                      color: Colors.lightGreen,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Giá: ${widget.court['pricePerHour']} VNĐ / giờ',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
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
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.lightGreen,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Ngày: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: pickDate,
                      child: const Text('Chọn ngày'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.access_time),
                label: Text(
                  startTime == null
                      ? 'Chọn giờ bắt đầu'
                      : 'Bắt đầu: ${startTime!.format(context)}',
                ),
                onPressed: pickStartTime,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.access_time),
                label: Text(
                  endTime == null
                      ? 'Chọn giờ kết thúc'
                      : 'Kết thúc: ${endTime!.format(context)}',
                ),
                onPressed: pickEndTime,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.lightGreen.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.attach_money,
                      color: Colors.lightGreen,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tổng tiền: ${totalPrice.toStringAsFixed(0)} VNĐ',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.lightGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            if (!enoughMoney && totalPrice > 0)
              Card(
                color: Colors.red.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Không đủ tiền trong ví',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (enoughMoney && totalPrice > 0) ? bookCourt : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'XÁC NHẬN ĐẶT SÂN',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
