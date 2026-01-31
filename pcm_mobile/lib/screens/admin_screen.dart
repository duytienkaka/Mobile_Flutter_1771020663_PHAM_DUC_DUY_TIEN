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
  String? topUpError;
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

      // Load in parallel but tolerate failures per section
      final results = await Future.wait<List<dynamic>>(
        [
          _safeCall(() => auth.api.getAdminUsers(token!)),
          _safeCall(() => auth.api.getAdminCourts(token!)),
          _safeCall(() => auth.api.getAdminBookings(token!)),
          _safeCall(() => auth.api.getAdminTournaments(token!)),
          _loadTopUps(token!),
        ],
      );

      setState(() {
        users = results[0];
        courts = results[1];
        bookings = results[2];
        tournaments = results[3];
        topUpRequests = results[4];
      });

      debugPrint('Admin data loaded: users=${users.length}, courts=${courts.length}, bookings=${bookings.length}, tournaments=${tournaments.length}, topups=${topUpRequests.length}');
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
      body: Container(
        color: const Color(0xFFF6F7FB),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildUsersTab(),
            _buildCourtsTab(),
            _buildBookingsTab(),
            _buildTournamentsTab(),
            _buildTopUpRequestsTab(),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildUsersTab() {
    return _tabScaffold(
      header: _statChips([
        ('Tổng', users.length.toString(), Colors.blue),
        ('Admin', users.where((u) => ((u['role'] ?? '').toString().toLowerCase() == 'admin')).length.toString(), Colors.orange),
      ]),
      child: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return _cardTile(
            icon: Icons.person,
            iconColor: Colors.indigo,
            title: user['fullName'] ?? '--',
            subtitle: '${user['userName'] ?? ''} · ${(user['role'] ?? '').toString()}',
            trailing: PopupMenuButton(
              onSelected: (value) => _handleUserAction(user, value),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'Admin', child: Text('Đặt làm Admin')),
                const PopupMenuItem(value: 'User', child: Text('Đặt làm User')),
                const PopupMenuItem(value: 'delete', child: Text('Xóa tài khoản')),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCourtsTab() {
    return _tabScaffold(
      header: _statChips([
        ('Tổng', courts.length.toString(), Colors.teal),
        ('Hoạt động', courts.where((c) => c['isActive'] == true).length.toString(), Colors.green),
      ]),
      child: ListView.builder(
        itemCount: courts.length,
        itemBuilder: (context, index) {
          final court = courts[index];
          final active = court['isActive'] == true;
          return _cardTile(
            icon: Icons.sports_soccer,
            iconColor: Colors.teal,
            title: court['name'] ?? 'Sân',
            subtitle: '${court['pricePerHour'] ?? '--'} VNĐ/h · ${active ? 'Hoạt động' : 'Tạm dừng'}',
            trailing: PopupMenuButton(
              onSelected: (value) => _handleCourtAction(court, value),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'toggle', child: Text(active ? 'Tạm dừng' : 'Kích hoạt')),
                const PopupMenuItem(value: 'delete', child: Text('Xóa sân')),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookingsTab() {
    return _tabScaffold(
      header: _statChips([
        ('Tổng', bookings.length.toString(), Colors.purple),
      ]),
      child: ListView.builder(
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return _cardTile(
            icon: Icons.book_online,
            iconColor: Colors.deepPurple,
            title: '${booking['courtName'] ?? ''} · ${booking['memberName'] ?? ''}',
            subtitle: '${booking['startTime'] ?? ''} → ${booking['endTime'] ?? ''}',
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteBooking(booking['id']),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTournamentsTab() {
    return _tabScaffold(
      header: _statChips([
        ('Tổng', tournaments.length.toString(), Colors.amber),
      ]),
      child: ListView.builder(
        itemCount: tournaments.length,
        itemBuilder: (context, index) {
          final tournament = tournaments[index];
          return _cardTile(
            icon: Icons.emoji_events,
            iconColor: Colors.orange,
            title: tournament['name'] ?? 'Giải đấu',
            subtitle: '${tournament['sport'] ?? ''} · ${tournament['status'] ?? ''}',
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteTournament(tournament['id']),
            ),
          );
        },
      ),
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
    return _tabScaffold(
      header: _statChips([
        ('Chờ duyệt', topUpRequests.length.toString(), Colors.red),
      ]),
      child: RefreshIndicator(
        onRefresh: loadData,
        child: topUpRequests.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 140),
                  if (topUpError != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Không tải được yêu cầu nạp tiền: $topUpError',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const Center(child: Text('Chưa có yêu cầu nạp tiền chờ duyệt')),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: topUpRequests.length,
                itemBuilder: (context, index) {
                  final request = topUpRequests[index];
                  final member = request['member'] ?? {};
                  final fullName = (member['fullName'] ?? '').toString();
                  final userName = (member['userName'] ?? '').toString();
                  final amount = (request['amount'] as num?)?.toDouble() ?? 0;
                  final created = DateTime.tryParse(request['createdDate']?.toString() ?? '');
                  return _cardTile(
                    icon: Icons.account_balance_wallet,
                    iconColor: Colors.green,
                    title: '${fullName.isNotEmpty ? fullName : 'Người dùng'} (${userName.isNotEmpty ? userName : ''})',
                    subtitle: 'Số tiền: ${amount.toStringAsFixed(0)} VNĐ\nThời gian: ${created != null ? created.toLocal() : ''}',
                    trailing: ElevatedButton(
                      onPressed: () => _approveTopUp(request['id']),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Duyệt'),
                    ),
                  );
                },
              ),
      ),
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
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = await auth.storage.read(key: 'token');
    try {
      await auth.api.approveTopUpRequest(token!, transactionId);
      await loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã duyệt yêu cầu nạp tiền')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<List<dynamic>> _safeCall(Future<List<dynamic>> Function() call) async {
    try {
      return await call();
    } catch (e) {
      debugPrint('Admin data load error: $e');
      return [];
    }
  }

  Future<List<dynamic>> _loadTopUps(String token) async {
    try {
      final data = await Provider.of<AuthProvider>(context, listen: false).api.getAdminTopUpRequests(token);
      topUpError = null;
      return data;
    } catch (e) {
      topUpError = e.toString();
      debugPrint('Top-up load error: $e');
      return [];
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _tabScaffold({required Widget child, Widget? header}) {
    return Column(
      children: [
        if (header != null)
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: header,
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: child,
          ),
        ),
      ],
    );
  }

  Widget _cardTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.12),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: trailing,
      ),
    );
  }

  Widget _statChips(List<(String, String, Color)> items) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: items
          .map(
            (item) => Chip(
              label: Text('${item.$1}: ${item.$2}', style: const TextStyle(fontWeight: FontWeight.w600)),
              backgroundColor: item.$3.withOpacity(0.12),
              labelStyle: TextStyle(color: item.$3),
            ),
          )
          .toList(),
    );
  }
}