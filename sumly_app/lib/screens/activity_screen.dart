import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/summary_service.dart';
import '../services/document_service.dart';
import '../models/models.dart';
import '../utils/app_colors.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final SummaryService _summaryService = SummaryService();
  final DocumentService _documentService = DocumentService();

  List<Summary> _recentSummaries = [];
  List<DocumentModel> _recentDocuments = [];
  Map<String, int> _monthlyStats = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  Future<void> _loadActivity() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final summariesResult = await _summaryService.getSummaries();
      final documentsResult = await _documentService.getDocuments();

      if (mounted) {
        if (summariesResult['success'] == true &&
            documentsResult['success'] == true) {
          final allSummaries = summariesResult['summaries'] as List<Summary>? ?? [];
          final allDocuments = documentsResult['documents'] as List<DocumentModel>? ?? [];

          setState(() {
            _recentSummaries = allSummaries.take(20).toList();
            _recentDocuments = allDocuments.take(20).toList();
            _monthlyStats = _calculateMonthlyStats(allDocuments);
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Error al cargar actividad';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error de conexión: $e';
          _isLoading = false;
        });
      }
    }
  }

  Map<String, int> _calculateMonthlyStats(List<DocumentModel> documents) {
    final stats = <String, int>{};
    final now = DateTime.now();
    final dateFormat = DateFormat('MMM yy', 'es');

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey = dateFormat.format(month);
      stats[monthKey] = 0;
    }

    for (final doc in documents) {
      final monthKey = dateFormat.format(doc.createdAt);
      if (stats.containsKey(monthKey)) {
        stats[monthKey] = (stats[monthKey] ?? 0) + 1;
      }
    }

    return stats;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';

    return DateFormat('d MMM', 'es').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Mi Actividad',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
              size: 22,
            ),
            onPressed: _loadActivity,
          ),
        ],
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 28, color: AppColors.error),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadActivity,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadActivity,
      color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildStatsSummary(isDark),
          const SizedBox(height: 32),
          _buildMonthlyChart(isDark),
          const SizedBox(height: 32),
          _buildRecentActivity(isDark),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildStatsSummary(bool isDark) {
    final totalDocs = _recentDocuments.length;
    final totalSummaries = _recentSummaries.length;
    final thisMonthDocs = _recentDocuments.where((doc) {
      final now = DateTime.now();
      return doc.createdAt.year == now.year && doc.createdAt.month == now.month;
    }).length;
    final timeEstimate = totalDocs * 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actividad',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 24),
        _buildStatCard(
          'Total Resúmenes',
          '$totalSummaries',
          'generados con IA',
          Icons.auto_awesome_rounded,
          [isDark ? AppColors.darkAccent : AppColors.lightAccent,
           isDark ? AppColors.darkAccent2 : AppColors.lightAccent2],
          isDark,
        ),
        const SizedBox(height: 16),
        _buildStatCard(
          'Este Mes',
          '$thisMonthDocs',
          'documentos procesados',
          Icons.calendar_today_rounded,
          [AppColors.success, AppColors.success.withOpacity(0.7)],
          isDark,
        ),
        const SizedBox(height: 16),
        _buildStatCard(
          'Tiempo Ahorrado',
          '~$timeEstimate horas',
          'estimado en lectura',
          Icons.schedule_rounded,
          [AppColors.warning, AppColors.warning.withOpacity(0.7)],
          isDark,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    String subtitle,
    IconData icon,
    List<Color> gradientColors,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: gradientColors[0].withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart(bool isDark) {
    if (_monthlyStats.isEmpty) return const SizedBox.shrink();

    final maxValue = _monthlyStats.values.reduce((a, b) => a > b ? a : b);
    if (maxValue == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mensual',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                height: 100,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _monthlyStats.entries.map((entry) {
                    final height = maxValue > 0
                        ? (entry.value / maxValue) * 80
                        : 0.0;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (entry.value > 0)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Text(
                                  '${entry.value}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                                  ),
                                ),
                              ),
                            Container(
                              height: height > 0 ? height : 3,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    isDark ? AppColors.darkAccent : AppColors.lightAccent,
                                    isDark ? AppColors.darkAccent2 : AppColors.lightAccent2,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _monthlyStats.keys.map((month) {
                  return Expanded(
                    child: Text(
                      month,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(bool isDark) {
    final allActivity = <Map<String, dynamic>>[];

    for (final doc in _recentDocuments) {
      allActivity.add({
        'type': 'document',
        'title': doc.title,
        'date': doc.createdAt,
        'icon': Icons.upload_file_rounded,
      });
    }

    for (final summary in _recentSummaries) {
      allActivity.add({
        'type': 'summary',
        'title': summary.title,
        'date': summary.createdAt,
        'icon': Icons.auto_awesome_rounded,
      });
    }

    allActivity.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    final recentActivity = allActivity.take(15).toList();

    if (recentActivity.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.timeline_rounded,
                size: 28,
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              ),
              const SizedBox(height: 12),
              Text(
                'Sin actividad',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reciente',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentActivity.length,
            separatorBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Divider(
                height: 1,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            itemBuilder: (context, index) {
              final activity = recentActivity[index];
              final isDocument = activity['type'] == 'document';

              return Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 2,
                      height: 28,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            isDark ? AppColors.darkAccent : AppColors.lightAccent,
                            isDark ? AppColors.darkAccent2 : AppColors.lightAccent2,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.15),
                            (isDark ? AppColors.darkAccent2 : AppColors.lightAccent2).withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        activity['icon'] as IconData,
                        color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            activity['title'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            isDocument ? 'Doc' : 'Resumen',
                            style: TextStyle(
                              fontSize: 9,
                              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _formatDate(activity['date'] as DateTime),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
