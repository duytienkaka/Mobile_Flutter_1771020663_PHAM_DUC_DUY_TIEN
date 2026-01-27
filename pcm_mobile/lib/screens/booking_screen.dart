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

  Future<void> bookCourt() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = await auth.storage.read(key: 'token');

    final start = DateTime.now().copyWith(hour: startTime!.hour, minute: 0);

    final end = DateTime.now().copyWith(hour: endTime!.hour, minute: 0);

    try {
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Không đủ tiền trong ví')));
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
            Text(
              'Giá: ${widget.court['pricePerHour']} VNĐ / giờ',
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: pickStartTime,
              child: Text(
                startTime == null
                    ? 'Chọn giờ bắt đầu'
                    : 'Bắt đầu: ${startTime!.format(context)}',
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: pickEndTime,
              child: Text(
                endTime == null
                    ? 'Chọn giờ kết thúc'
                    : 'Kết thúc: ${endTime!.format(context)}',
              ),
            ),

            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(15),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Tổng tiền: ${totalPrice.toStringAsFixed(0)} VNĐ',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),

            const SizedBox(height: 10),

            if (!enoughMoney && totalPrice > 0)
              const Text(
                '⚠ Không đủ tiền trong ví',
                style: TextStyle(color: Colors.red),
              ),

            const Spacer(),

            ElevatedButton(
              onPressed: (enoughMoney && totalPrice > 0) ? bookCourt : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text(
                'XÁC NHẬN ĐẶT SÂN',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
