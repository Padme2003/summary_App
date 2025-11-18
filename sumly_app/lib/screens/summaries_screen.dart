import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/summary_service.dart';
import '../models/models.dart';

class SummariesScreen extends StatefulWidget {
  final String? filter; // 'all', 'completed', 'generating', 'error'

  const SummariesScreen({super.key, this.filter});

  @override
  State<SummariesScreen> createState() => _SummariesScreenState();
}

class _SummariesScreenState extends State<SummariesScreen> {
  final SummaryService _summaryService = SummaryService();
  List<Summary> _summaries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSummaries();
  }

  Future<void> _loadSummaries() async {
    setState(() => _isLoading = true);

    try {
      final result = await _summaryService.getSummaries();

      if (mounted) {
        setState(() {
          _summaries = result['summaries'] ?? [];

          // Apply filter if specified
          if (widget.filter != null && widget.filter != 'all') {
            _summaries = _summaries.where((s) => s.status == widget.filter).toList();
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getTitle() {
    switch (widget.filter) {
      case 'completed':
        return 'Resúmenes Completados';
      case 'generating':
        return 'Generando...';
      case 'error':
        return 'Resúmenes con Error';
      default:
        return 'Mis Resúmenes';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _getTitle(),
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            onPressed: _loadSummaries,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _summaries.isEmpty
              ? _buildEmptyState()
              : _buildSummariesList(),
    );
  }

  Widget _buildSummariesList() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _loadSummaries,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Total', _summaries.length, Colors.blue),
                _buildStat(
                  'Completados',
                  _summaries.where((s) => s.status == 'completed').length,
                  Colors.green,
                ),
                _buildStat(
                  'Generando',
                  _summaries.where((s) => s.status == 'generating').length,
                  Colors.orange,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // List
          ..._summaries.map((summary) => _buildSummaryCard(summary)),
        ],
      ),
    );
  }

  Widget _buildStat(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(Summary summary) {
    final dateFormat = DateFormat('d MMM yyyy • HH:mm', 'es');
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Color getStatusColor() {
      switch (summary.status) {
        case 'completed':
          return Colors.green;
        case 'generating':
          return Colors.orange;
        case 'error':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    String getStatusText() {
      switch (summary.status) {
        case 'completed':
          return 'Completado';
        case 'generating':
          return 'Generando...';
        case 'error':
          return 'Error';
        default:
          return 'Desconocido';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: summary.status == 'completed'
            ? () {
                Navigator.pushNamed(
                  context,
                  '/summary',
                  arguments: {'id': summary.id},
                ).then((_) => _loadSummaries());
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      summary.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (summary.isFavorite)
                    const Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                summary.content,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      getStatusText(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: getStatusColor(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.calendar_today, size: 14, color: isDarkMode ? Colors.grey[600] : Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(summary.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  if (summary.audioUrl != null) ...[
                    Icon(Icons.headphones, size: 14, color: isDarkMode ? Colors.grey[600] : Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      '${(summary.audioDuration ?? 0) ~/ 60} min',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_stories_outlined,
            size: 100,
            color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            'No hay resúmenes aún',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Genera tu primer resumen desde un documento',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
