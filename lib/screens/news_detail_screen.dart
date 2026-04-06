import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/ai_service.dart';
import '../models/stock_note.dart';
import '../providers/notes_provider.dart';

class NewsDetailScreen extends StatefulWidget {
  final dynamic article;
  final String ticker;

  const NewsDetailScreen({super.key, required this.article, required this.ticker});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  final AIService _aiService = AIService();
  Map<String, dynamic>? _aiAnalysis;
  bool _isAnalyzing = false;
  bool _isSaving = false;

  Future<void> _getAIAnalysis() async {
    setState(() => _isAnalyzing = true);

    try {
      final result = await _aiService.analyzeSentiment(
        widget.article['headline'] ?? '',
        widget.article['summary'] ?? '',
      );

      setState(() {
        _aiAnalysis = result;
        _isAnalyzing = false;
      });

      if (result == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to get AI analysis. Please try again.')),
          );
        }
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _saveToNotes() async {
    if (_aiAnalysis == null) return;

    setState(() => _isSaving = true);

    final sentiment = _aiAnalysis!['sentiment'] as String? ?? 'Neutral';
    final reasoning = _aiAnalysis!['ai_reasoning'] as String? ?? '';
    final headline = widget.article['headline'] ?? 'Stock News';

    final note = StockNote(
      ticker: widget.ticker,
      title: 'AI Analysis: $headline',
      content: 'Sentiment: $sentiment\n\n$reasoning',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await context.read<NotesProvider>().createNote(note);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved to your research notes!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save note: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Color _getSentimentColor(String? sentiment) {
    switch (sentiment?.toLowerCase()) {
      case 'bullish':
        return Colors.green;
      case 'bearish':
        return Colors.red;
      case 'neutral':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(
        (widget.article['datetime'] as int) * 1000);

    return Scaffold(
      appBar: AppBar(
        title: const Text('News Detail'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.article['image'] != null && (widget.article['image'] as String).isNotEmpty)
              Image.network(
                widget.article['image'],
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image, size: 50),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.article['headline'] ?? '',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.article['source'] ?? 'Unknown Source',
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('MMMM d, yyyy').format(date),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Text(
                    widget.article['summary'] ?? 'No summary available.',
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  
                  // AI Analysis Section
                  if (_aiAnalysis == null)
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _isAnalyzing ? null : _getAIAnalysis,
                        icon: _isAnalyzing 
                            ? const SizedBox(
                                width: 20, 
                                height: 20, 
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                              )
                            : const Icon(Icons.auto_awesome),
                        label: Text(_isAnalyzing ? 'Analyzing...' : 'Get AI Insights'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    )
                  else
                    _buildAIAnalysisCard(),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final url = Uri.parse(widget.article['url'] ?? '');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Read Full Article'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIAnalysisCard() {
    final sentiment = _aiAnalysis!['sentiment'] as String?;
    final confidence = _aiAnalysis!['confidence'];
    final reasoning = _aiAnalysis!['ai_reasoning'] as String?;
    final color = _getSentimentColor(sentiment);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text(
                      'AI Analysis',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color),
                  ),
                  child: Text(
                    sentiment?.toUpperCase() ?? 'UNKNOWN',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (confidence != null)
              Text(
                'Confidence: ${confidence is double ? confidence.toStringAsFixed(1) : confidence}%',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            const Divider(height: 24),
            Text(
              'Reasoning:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              reasoning ?? 'No reasoning provided.',
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _isSaving ? null : _saveToNotes,
                  icon: _isSaving 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.bookmark_add_outlined),
                  label: const Text('Save to Notes'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => setState(() => _aiAnalysis = null),
                  child: const Text('Refresh'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}