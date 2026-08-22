import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/reveal_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class PendingRevealsScreen extends StatefulWidget {
  const PendingRevealsScreen({super.key});

  @override
  State<PendingRevealsScreen> createState() => _PendingRevealsScreenState();
}

class _PendingRevealsScreenState extends State<PendingRevealsScreen> {
  final ApiClient _apiClient = ApiClient();
  List<RevealModel> _pendingReveals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingReveals();
  }

  Future<void> _fetchPendingReveals() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get('${ApiConstants.reveals}/pending');
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        setState(() {
          _pendingReveals = list.map((r) => RevealModel.fromJson(r)).toList();
        });
      }
    } catch (_) {
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _respondToReveal(String revealRequestId, bool accept) async {
    try {
      final res = await _apiClient.post('${ApiConstants.reveals}/$revealRequestId/respond?accept=$accept');
      if (res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(accept ? 'Identity shared with mentor!' : 'Reveal request declined.')),
          );
        }
        await _fetchPendingReveals();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.darkSurface,
        title: const Text('Identity Disclosure Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryLight))
          : _pendingReveals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline, size: 54, color: AppTheme.textSecondary.withOpacity(0.5)),
                      const SizedBox(height: 14),
                      const Text(
                        'No pending reveal requests',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Your anonymity is protected across all active queries.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(18),
                  itemCount: _pendingReveals.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final req = _pendingReveals[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person_pin_outlined, color: AppTheme.primaryLight, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  req.seniorName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Pending Your Approval',
                                    style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Mentor is requesting to connect directly on your question:',
                              style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.8), fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '"${req.queryTitle}"',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _respondToReveal(req.id, false),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.dangerColor,
                                      side: const BorderSide(color: AppTheme.dangerColor),
                                    ),
                                    child: const Text('Decline'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _respondToReveal(req.id, true),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor),
                                    child: const Text('Allow Reveal'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
