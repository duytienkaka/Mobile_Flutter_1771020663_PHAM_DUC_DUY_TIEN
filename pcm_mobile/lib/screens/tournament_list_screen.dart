import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'tournament_detail_screen.dart';

class TournamentListScreen extends StatefulWidget {
  const TournamentListScreen({super.key});

  @override
  State<TournamentListScreen> createState() => _TournamentListScreenState();
}

class _TournamentListScreenState extends State<TournamentListScreen> {
  List tournaments = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadTournaments();
  }

  Future<void> loadTournaments() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = await auth.storage.read(key: 'token');

      final data = await auth.api.getTournaments(token!);

      setState(() {
        tournaments = data;
      });
    } catch (e) {
      setState(() {
        error = 'Không tải được danh sách giải đấu';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giải đấu'),
        actions: auth.role == 'Admin' ? [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateTournamentDialog(),
          ),
        ] : null,
      ),
      body: RefreshIndicator(
        onRefresh: loadTournaments,
        child: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Text(error!, style: const TextStyle(color: Colors.red)),
            )
          : tournaments.isEmpty
          ? const Center(child: Text('Chưa có giải đấu nào'))
          : ListView.builder(
              itemCount: tournaments.length,
              itemBuilder: (context, index) {
                final t = tournaments[index];
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
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TournamentDetailScreen(tournamentId: t['id']),
                      ),
                    ),
                    leading: const Icon(
                      Icons.emoji_events,
                      color: Colors.lightGreen,
                    ),
                    title: Text(
                      t['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Môn: ${t['sport']}'),
                        Text('Phí: ${t['entryFee']} VNĐ'),
                        Text('Trạng thái: ${t['status']}'),
                      ],
                    ),
                    trailing: Text(
                      'Quỹ: ${t['prizePool']} VNĐ',
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

  void _showCreateTournamentDialog() {
    final nameController = TextEditingController();
    final sportController = TextEditingController();
    DateTime startDate = DateTime.now();
    double entryFee = 0;
    int maxTeams = 8;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Tạo giải đấu'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Tên giải'),
                ),
                TextField(
                  controller: sportController,
                  decoration: const InputDecoration(labelText: 'Môn thể thao'),
                ),
                ListTile(
                  title: Text('Ngày bắt đầu: ${startDate.toLocal().toString().split(' ')[0]}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => startDate = picked);
                    }
                  },
                ),
                TextField(
                  keyboardType: TextInputType.number,
                  onChanged: (v) => entryFee = double.tryParse(v) ?? 0,
                  decoration: const InputDecoration(labelText: 'Phí tham gia (VNĐ)'),
                ),
                TextField(
                  keyboardType: TextInputType.number,
                  onChanged: (v) => maxTeams = int.tryParse(v) ?? 8,
                  decoration: const InputDecoration(labelText: 'Số đội tối đa'),
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
                try {
                  final auth = Provider.of<AuthProvider>(context, listen: false);
                  final token = await auth.storage.read(key: 'token');

                  await auth.api.createTournament(
                    token: token!,
                    name: nameController.text,
                    sport: sportController.text,
                    startDate: startDate,
                    entryFee: entryFee,
                    maxTeams: maxTeams,
                  );

                  Navigator.pop(context);
                  loadTournaments();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tạo giải đấu thành công')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              },
              child: const Text('Tạo'),
            ),
          ],
        ),
      ),
    );
  }
}