import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/reveal_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/skeleton_loader.dart';

class PendingRevealsScreen extends StatefulWidget {
  const PendingRevealsScreen({super.key});

  @override
  State<PendingRevealsScreen> createState() => _PendingRevealsScreenState();
}

class _PendingRevealsScreenState extends State<PendingRevealsScreen> {
  final ApiClient _apiClient = ApiClient();
  List<RevealModel> _reveals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingReveals();
  }

  Future<void> _fetchPendingReveals() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get(ApiConstants.pendingReveals);
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          _reveals = data.map((r) => RevealModel.fromJson(r)).toList();
        });
      }
    } catch (_) {
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _respondToReveal(String revealId, String action) async {
    try {
      final res = await _apiClient.post(
        ApiConstants.respondReveal(revealId),
        body: {'action': action},
      );
      if (res.statusCode == 200) {
        _fetchPendingReveals();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: const Text('Identity Reveal Requests', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppTheme.onSurface)),
      ),
      body: _isLoading
          ? const SkeletonFeedList(count: 3)
          : _reveals.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mark_email_read_outlined, size: 54, color: AppTheme.outlineVariant),
                      SizedBox(height: 12),
                      Text('No pending identity reveal requests', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 15)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reveals.length,
                  separatorBuilder: (ctx, idx) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final rev = _reveals[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.cardBorder),
                        boxShadow: const [AppTheme.ambientShadow],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppTheme.primaryContainer,
                                child: Text(rev.seniorName[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  rev.seniorName,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.onSurface),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.warning.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('PENDING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.warning)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Requested to connect on: "${rev.queryTitle}"',
                            style: const TextStyle(color: AppTheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.secondary,
                                    side: const BorderSide(color: AppTheme.secondary),
                                  ),
                                  onPressed: () => _respondToReveal(rev.id, 'REJECT'),
                                  child: const Text('Decline'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _respondToReveal(rev.id, 'ACCEPT'),
                                  child: const Text('Accept & Reveal'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
