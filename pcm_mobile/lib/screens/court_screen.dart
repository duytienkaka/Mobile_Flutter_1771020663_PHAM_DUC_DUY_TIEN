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

      final data = await auth.api.getCourts(token!);

      setState(() {
        courts = data;
        filteredCourts = data;
      });
    } catch (e) {
      setState(() {
        error = 'Không tải được danh sách sân';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  void filterCourts() {
    List temp = courts.where((court) {
      return court['name'].toLowerCase().contains(searchQuery.toLowerCase());
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
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                ? Center(
                    child: Text(error!, style: const TextStyle(color: Colors.red)),
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
                            court['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Giá: ${court['pricePerHour']} VNĐ / giờ',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          trailing: Column(
                            children: [
                              ElevatedButton(
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
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              TextButton(
                                child: const Text('Reviews'),
                                onPressed: () => showReviewsDialog(court),
                              ),
                            ],
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
