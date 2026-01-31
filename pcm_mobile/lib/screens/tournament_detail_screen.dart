import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class TournamentDetailScreen extends StatefulWidget {
  final int tournamentId;

  const TournamentDetailScreen({super.key, required this.tournamentId});

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> {
  Map<String, dynamic>? tournament;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadTournamentDetails();
  }

  Future<void> loadTournamentDetails() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = await auth.storage.read(key: 'token');

      final data = await auth.api.getTournamentDetails(widget.tournamentId, token!);

      setState(() {
        tournament = data;
      });
    } catch (e) {
      String message = 'Lỗi không xác định';
      if (e is DioException) {
        message = e.response?.data?.toString() ?? e.message ?? message;
      } else {
        message = e.toString();
      }
      setState(() {
        error = message;
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết giải đấu')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết giải đấu')),
        body: Center(
          child: Text(error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    final t = tournament!;

    return Scaffold(
      appBar: AppBar(title: Text(t['name'])),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Môn: ${t['sport']}', style: const TextStyle(fontSize: 16)),
                    Text('Ngày bắt đầu: ${DateTime.parse(t['startDate']).toLocal().toString().split(' ')[0]}'),
                    Text('Phí tham gia: ${t['entryFee']} VNĐ'),
                    Text('Số đội tối đa: ${t['maxTeams']}'),
                    Text('Quỹ thưởng: ${t['prizePool']} VNĐ'),
                    Text('Trạng thái: ${t['status']}'),
                    Text('Người tạo: ${t['creatorName']}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (t['status'] == 'Open')
              ElevatedButton(
                onPressed: () => _showRegisterDialog(),
                child: const Text('Đăng ký tham gia'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            const SizedBox(height: 20),
            const Text('Các đội tham gia:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...(t['teams'] as List).map((team) => Card(
              child: ListTile(
                title: Text(team['teamName']),
                subtitle: Text('Thành viên: ${team['memberIds'].length}'),
                trailing: team['isRegistered'] ? const Icon(Icons.check, color: Colors.green) : const Text('Chưa đăng ký'),
              ),
            )),
            const SizedBox(height: 20),
            const Text('Lịch thi đấu:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...(t['matches'] as List).map((match) => Card(
              child: ListTile(
                title: Text('${match['teamAName'] ?? 'TBD'} vs ${match['teamBName'] ?? 'TBD'}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Thời gian: ${DateTime.parse(match['scheduledTime']).toLocal()}'),
                    if (match['courtName'] != null) Text('Sân: ${match['courtName']}'),
                    if (match['scoreA'] != null) Text('Tỉ số: ${match['scoreA']} - ${match['scoreB']}'),
                    Text('Trạng thái: ${match['status']}'),
                  ],
                ),
                trailing: match['winnerName'] != null ? Text('Thắng: ${match['winnerName']}') : null,
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _showRegisterDialog() {
    final teamNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Đăng ký tham gia'),
        content: TextField(
          controller: teamNameController,
          decoration: const InputDecoration(labelText: 'Tên đội'),
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

                await auth.api.registerForTournament(
                  token: token!,
                  tournamentId: widget.tournamentId,
                  teamName: teamNameController.text,
                );

                Navigator.pop(context);
                loadTournamentDetails();
                auth.loadProfile(); // Update wallet
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đăng ký thành công')),
                );
              } catch (e) {
                String message = 'Lỗi không xác định';
                if (e is DioException) {
                  final data = e.response?.data;
                  final serverMessage = data is String ? data : data?.toString();
                  message = _friendlyError(serverMessage ?? e.message ?? message);
                } else {
                  message = e.toString();
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              }
            },
            child: const Text('Đăng ký'),
          ),
        ],
      ),
    );
  }

  String _friendlyError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('already registered')) return 'Bạn đã đăng ký giải đấu này rồi';
    if (lower.contains('insufficient')) return 'Số dư ví không đủ để đăng ký';
    if (lower.contains('not open')) return 'Giải đấu hiện không mở đăng ký';
    return message;
  }
}