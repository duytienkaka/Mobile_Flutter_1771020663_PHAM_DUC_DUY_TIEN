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
  double pricePerHour = 0;

  DateTime selectedDate = DateTime.now();

  bool isGroupBooking = false;
  List<String> invitedUserNames = [];
  TextEditingController inviteController = TextEditingController();

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
    totalPrice = hours.toDouble() * pricePerHour;
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

    if (startTime == null || endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn giờ bắt đầu và kết thúc')),
      );
      return;
    }

    final start = selectedDate.copyWith(hour: startTime!.hour, minute: 0);

    final end = selectedDate.copyWith(hour: endTime!.hour, minute: 0);

    try {
      if (isGroupBooking) {
        await auth.api.createGroupBooking(
          token: token!,
          courtId: widget.court['id'],
          start: start,
          end: end,
          invitedUserNames: invitedUserNames,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo nhóm đặt sân thành công')),
        );
      } else {
        await auth.api.bookCourt(
          token: token!,
          courtId: widget.court['id'],
          start: start,
          end: end,
        );
        await auth.loadProfile();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đặt sân thành công')),
        );
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  @override
  void dispose() {
    inviteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    pricePerHour = (widget.court['pricePerHour'] as num?)?.toDouble() ?? 0;
    final wallet = auth.walletBalance ?? 0;
    final enoughMoney = wallet >= totalPrice;
    return Scaffold(
      appBar: AppBar(title: Text('Đặt ${widget.court['name'] ?? 'Sân'}')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 800.0;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  minWidth: maxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _priceCard(),
                    const SizedBox(height: 20),
                    _dateCard(),
                    const SizedBox(height: 20),
                    _groupToggleCard(),
                    if (isGroupBooking) ...[
                      const SizedBox(height: 20),
                      _inviteCard(),
                    ],
                    const SizedBox(height: 20),
                    _timeButton(
                      label: startTime == null
                          ? 'Chọn giờ bắt đầu'
                          : 'Bắt đầu: ${startTime!.format(context)}',
                      icon: Icons.access_time,
                      onTap: pickStartTime,
                    ),
                    const SizedBox(height: 10),
                    _timeButton(
                      label: endTime == null
                          ? 'Chọn giờ kết thúc'
                          : 'Kết thúc: ${endTime!.format(context)}',
                      icon: Icons.access_time,
                      onTap: pickEndTime,
                    ),
                    const SizedBox(height: 30),
                    _summaryCard(),
                    const SizedBox(height: 10),
                    if (!enoughMoney && totalPrice > 0) _notEnoughCard(),
                    const SizedBox(height: 16),
                    _confirmButton(enoughMoney),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _priceCard() {
    return Card(
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
              'Giá: ${pricePerHour.toStringAsFixed(0)} VNĐ / giờ',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateCard() {
    return Card(
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
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: pickDate,
              child: const Text('Chọn ngày'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupToggleCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.group,
              color: Colors.lightGreen,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text(
              'Đặt nhóm',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            Switch(
              value: isGroupBooking,
              onChanged: (value) => setState(() => isGroupBooking = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inviteCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mời bạn bè',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: inviteController,
                    decoration: const InputDecoration(
                      hintText: 'Tên đăng nhập',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    if (inviteController.text.isNotEmpty) {
                      setState(() {
                        invitedUserNames.add(inviteController.text);
                        inviteController.clear();
                      });
                    }
                  },
                  child: const Text('Thêm'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: invitedUserNames
                  .map((user) => Chip(
                        label: Text(user),
                        onDeleted: () => setState(() => invitedUserNames.remove(user)),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeButton({required String label, required IconData icon, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _summaryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.lightGreen.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
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
            if (isGroupBooking && invitedUserNames.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Phần mỗi người: ${(totalPrice / (invitedUserNames.length + 1)).toStringAsFixed(0)} VNĐ',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.lightGreen,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _notEnoughCard() {
    return Card(
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
    );
  }

  Widget _confirmButton(bool enoughMoney) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (enoughMoney && totalPrice > 0) ? bookCourt : null,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          isGroupBooking ? 'TẠO NHÓM ĐẶT SÂN' : 'XÁC NHẬN ĐẶT SÂN',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
