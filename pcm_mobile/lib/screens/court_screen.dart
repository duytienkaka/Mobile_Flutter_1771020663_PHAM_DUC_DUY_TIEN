import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'booking_screen.dart';

class CourtScreen extends StatefulWidget {
  const CourtScreen({super.key});

  @override
  State<CourtScreen> createState() => _CourtScreenState();
}

class _CourtScreenState extends State<CourtScreen> {
  List courts = [];
  List filteredCourts = [];
  bool loading = true;
  String? error;
  String searchQuery = '';
  String sortBy = 'name'; // 'name', 'price_low', 'price_high'

  @override
  void initState() {
    super.initState();
    loadCourts();
  }

  Future<void> loadCourts() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = await auth.storage.read(key: 'token');
      if (token == null) {
        throw Exception('token_missing');
      }

      final data = await auth.api.getCourts(token);

      setState(() {
        courts = data;
        filteredCourts = data;
        error = null;
      });
    } catch (e) {
      String message = 'Không tải được danh sách sân';
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
      setState(() {
        error = message;
      });
      debugPrint('Courts load error: $e');
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  void filterCourts() {
    final q = searchQuery.toLowerCase();
    List temp = courts.where((court) {
      final name = court['name']?.toString().toLowerCase() ?? '';
      return name.contains(q);
    }).toList();

    if (sortBy == 'price_low') {
      temp.sort((a, b) => a['pricePerHour'].compareTo(b['pricePerHour']));
    } else if (sortBy == 'price_high') {
      temp.sort((a, b) => b['pricePerHour'].compareTo(a['pricePerHour']));
    }

    setState(() {
      filteredCourts = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách sân')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm sân...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      searchQuery = value;
                      filterCourts();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: sortBy,
                  items: const [
                    DropdownMenuItem(value: 'name', child: Text('Tên')),
                    DropdownMenuItem(value: 'price_low', child: Text('Giá ↑')),
                    DropdownMenuItem(value: 'price_high', child: Text('Giá ↓')),
                  ],
                  onChanged: (value) {
                    sortBy = value!;
                    filterCourts();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: loadCourts,
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Text(error!, style: const TextStyle(color: Colors.red)),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: loadCourts,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Thử lại'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          itemCount: filteredCourts.length,
                          itemBuilder: (context, index) {
                            final court = filteredCourts[index];
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
                                leading: const Icon(
                                  Icons.sports_soccer,
                                  color: Colors.lightGreen,
                                ),
                                title: Text(
                                  court['name']?.toString() ?? 'Sân',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Giá: ${court['pricePerHour'] ?? '--'} VNĐ / giờ',
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                    TextButton(
                                      onPressed: () => showReviewsDialog(court),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text('Reviews'),
                                    ),
                                  ],
                                ),
                                trailing: ConstrainedBox(
                                  constraints: const BoxConstraints(minWidth: 72, maxWidth: 110),
                                  child: ElevatedButton(
                                    child: const Text('Đặt'),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => BookingScreen(court: court),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      minimumSize: const Size(0, 40),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  void showReviewsDialog(Map court) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = await auth.storage.read(key: 'token');
    List reviews = await auth.api.getCourtReviews(court['id'], token!);

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Reviews: ${court['name']}'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              children: reviews.map<Widget>((r) => ListTile(
                title: Text('${r['memberName']}: ${List.generate(r['rating'], (_) => '⭐').join()}'),
                subtitle: Text(r['comment']),
              )).toList(),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Thêm review'),
              onPressed: () => addReviewDialog(court['id'], () async {
                reviews = await auth.api.getCourtReviews(court['id'], token);
                setState(() {});
              }),
            ),
            TextButton(
              child: const Text('Đóng'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void addReviewDialog(int courtId, VoidCallback onReviewAdded) {
    int rating = 5;
    String comment = '';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Đánh giá sân'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<int>(
                value: rating,
                items: [1,2,3,4,5].map((e) => DropdownMenuItem(value: e, child: Text('$e sao'))).toList(),
                onChanged: (v) => setState(() => rating = v!),
              ),
              TextField(
                onChanged: (v) => comment = v,
                decoration: const InputDecoration(labelText: 'Comment'),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Gửi'),
              onPressed: () async {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final token = await auth.storage.read(key: 'token');
                await auth.api.addCourtReview(courtId, token!, rating, comment);
                Navigator.pop(context);
                onReviewAdded();
              },
            ),
          ],
        ),
      ),
    );
  }
}
