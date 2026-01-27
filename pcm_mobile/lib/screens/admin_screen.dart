import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List users = [];
  List courts = [];
  List bookings = [];
  List tournaments = [];
  List topUpRequests = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    loadData();
  }

  Future<void> loadData() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = await auth.storage.read(key: 'token');

      // Load all data in parallel
      final results = await Future.wait([
        auth.api.getAdminUsers(token!),
        auth.api.getAdminCourts(token),
        auth.api.getAdminBookings(token),
        auth.api.getAdminTournaments(token),
        auth.api.getAdminTopUpRequests(token),
      ]);

      setState(() {
        users = results[0] as List;
        courts = results[1] as List;
        bookings = results[2] as List;
        tournaments = results[3] as List;
        topUpRequests = results[4] as List;
      });
    } catch (e) {
      debugPrint('Load admin data failed: $e');
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Admin'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Người dùng'),
            Tab(text: 'Sân'),
            Tab(text: 'Đặt sân'),
            Tab(text: 'Giải đấu'),
            Tab(text: 'Nạp tiền'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUsersTab(),
          _buildCourtsTab(),
          _buildBookingsTab(),
          _buildTournamentsTab(),
          _buildTopUpRequestsTab(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildUsersTab() {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.person),
            title: Text(user['fullName']),
            subtitle: Text('${user['userName']} - ${user['role']}'),
            trailing: PopupMenuButton(
              onSelected: (value) => _handleUserAction(user, value),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'admin', child: Text('Đặt làm Admin')),
                const PopupMenuItem(value: 'user', child: Text('Đặt làm User')),
                const PopupMenuItem(value: 'delete', child: Text('Xóa tài khoản')),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCourtsTab() {
    return ListView.builder(
      itemCount: courts.length,
      itemBuilder: (context, index) {
        final court = courts[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.sports_soccer),
            title: Text(court['name']),
            subtitle: Text('${court['pricePerHour']} VNĐ/h - ${court['isActive'] ? 'Hoạt động' : 'Không hoạt động'}'),
            trailing: PopupMenuButton(
              onSelected: (value) => _handleCourtAction(court, value),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'toggle', child: Text('Chuyển trạng thái')),
                const PopupMenuItem(value: 'delete', child: Text('Xóa sân')),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookingsTab() {
    return ListView.builder(
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.book_online),
            title: Text('${booking['courtName']} - ${booking['memberName']}'),
            subtitle: Text('${booking['startTime']} - ${booking['endTime']}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteBooking(booking['id']),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTournamentsTab() {
    return ListView.builder(
      itemCount: tournaments.length,
      itemBuilder: (context, index) {
        final tournament = tournaments[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.emoji_events),
            title: Text(tournament['name']),
            subtitle: Text('${tournament['sport']} - ${tournament['status']}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteTournament(tournament['id']),
            ),
          ),
        );
      },
    );
  }

  void _handleUserAction(Map<String, dynamic> user, String action) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = await auth.storage.read(key: 'token');

    try {
      if (action == 'delete') {
        await auth.api.deleteUser(token!, user['id']);
        setState(() {
          users.removeWhere((u) => u['id'] == user['id']);
        });
      } else {
        await auth.api.updateUserRole(token!, user['id'], action);
        setState(() {
          user['role'] = action;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thao tác thành công')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  void _handleCourtAction(Map<String, dynamic> court, String action) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = await auth.storage.read(key: 'token');

    try {
      if (action == 'delete') {
        await auth.api.deleteCourt(token!, court['id']);
        setState(() {
          courts.removeWhere((c) => c['id'] == court['id']);
        });
      } else if (action == 'toggle') {
        await auth.api.updateCourt(token!, court['id'], {...court, 'isActive': !court['isActive']});
        setState(() {
          court['isActive'] = !court['isActive'];
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thao tác thành công')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  void _deleteBooking(int id) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = await auth.storage.read(key: 'token');

    try {
      await auth.api.deleteBookingAdmin(token!, id);
      setState(() {
        bookings.removeWhere((b) => b['id'] == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa đặt sân thành công')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  void _deleteTournament(int id) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = await auth.storage.read(key: 'token');

    try {
      await auth.api.deleteTournamentAdmin(token!, id);
      setState(() {
        tournaments.removeWhere((t) => t['id'] == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa giải đấu thành công')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Widget _buildTopUpRequestsTab() {
    return ListView.builder(
      itemCount: topUpRequests.length,
      itemBuilder: (context, index) {
        final request = topUpRequests[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.account_balance_wallet, color: Colors.green),
            title: Text('${request['member']['fullName']} - ${request['amount']} VNĐ'),
            subtitle: Text('Thời gian: ${DateTime.parse(request['createdDate']).toLocal()}'),
            trailing: ElevatedButton(
              onPressed: () => _approveTopUp(request['id']),
              child: const Text('Duyệt'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => _showCreateOptions(),
      backgroundColor: Colors.lightGreen,
      foregroundColor: Colors.white,
      tooltip: 'Tạo mới',
      child: const Icon(Icons.add),
    );
  }

  void _showCreateOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.sports_soccer),
              title: const Text('Tạo sân bóng'),
              onTap: () {
                Navigator.pop(context);
                _showCreateCourtDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events),
              title: const Text('Tạo giải đấu'),
              onTap: () {
                Navigator.pop(context);
                _showCreateTournamentDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateCourtDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tạo sân bóng mới'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên sân'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên sân';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Giá/giờ (VNĐ)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập giá';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Giá phải là số';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final token = await auth.storage.read(key: 'token');

                try {
                  await auth.api.createCourtAdmin(token!, {
                    'name': nameController.text,
                    'pricePerHour': int.parse(priceController.text),
                  });

                  Navigator.pop(context);
                  loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tạo sân bóng thành công')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              }
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  void _showCreateTournamentDialog() {
    final nameController = TextEditingController();
    final sportController = TextEditingController();
    final entryFeeController = TextEditingController();
    final maxTeamsController = TextEditingController();
    final prizePoolController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tạo giải đấu mới'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Tên giải đấu'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập tên giải đấu';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: sportController,
                  decoration: const InputDecoration(labelText: 'Môn thi đấu'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập môn thi đấu';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: entryFeeController,
                  decoration: const InputDecoration(labelText: 'Phí tham gia (VNĐ)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập phí tham gia';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Phí tham gia phải là số';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: maxTeamsController,
                  decoration: const InputDecoration(labelText: 'Số đội tối đa'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập số đội tối đa';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Số đội phải là số';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: prizePoolController,
                  decoration: const InputDecoration(labelText: 'Quỹ thưởng (VNĐ)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập quỹ thưởng';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Quỹ thưởng phải là số';
                    }
                    return null;
                  },
                ),
                ListTile(
                  title: const Text('Ngày bắt đầu'),
                  subtitle: Text(selectedDate.toLocal().toString().split(' ')[0]),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final token = await auth.storage.read(key: 'token');

                try {
                  await auth.api.createTournamentAdmin(token!, {
                    'name': nameController.text,
                    'sport': sportController.text,
                    'startDate': selectedDate.toIso8601String(),
                    'entryFee': int.parse(entryFeeController.text),
                    'maxTeams': int.parse(maxTeamsController.text),
                    'prizePool': int.parse(prizePoolController.text),
                  });

                  Navigator.pop(context);
                  loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tạo giải đấu thành công')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              }
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  void _approveTopUp(int transactionId) async {
    // For now, just show a message that top-up is approved
    // In a real app, you'd update the transaction status
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã duyệt yêu cầu nạp tiền')),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}