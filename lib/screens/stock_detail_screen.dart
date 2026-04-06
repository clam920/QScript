import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/stock_quote.dart';
import '../models/stock_profile.dart';
import '../services/api_service.dart';
import '../providers/watchlist_provider.dart';
import '../providers/notes_provider.dart';
import 'notes_screen.dart';
import 'note_editor_screen.dart';

class StockDetailScreen extends StatefulWidget {
  final String ticker;

  const StockDetailScreen({super.key, required this.ticker});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  final ApiService _apiService = ApiService();
  StockQuote? _quote;
  StockProfile? _profile;
  List<Map<String, dynamic>> _historicalData = [];
  bool _isLoading = true;
  bool _isInWatchlist = false;
  int _notesCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Try to get quote from provider cache first
    final provider = context.read<WatchlistProvider>();
    var quote = provider.quotes[widget.ticker];

    // If not cached, fetch it
    if (quote == null) {
      quote = await provider.getQuoteForTicker(widget.ticker);
    }

    final profile = await _apiService.getProfile(widget.ticker);
    final historical = await _apiService.getHistoricalPrices(widget.ticker);
    final inWatchlist = await provider.isInWatchlist(widget.ticker);
    final notesCount = await context
        .read<NotesProvider>()
        .getNotesCountByTicker(widget.ticker);

    setState(() {
      _quote = quote;
      _profile = profile;
      _historicalData = historical;
      _isInWatchlist = inWatchlist;
      _notesCount = notesCount;
      _isLoading = false;
    });
  }

  Widget _buildPriceChart() {
    if (_historicalData.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No chart data available')),
      );
    }

    final spots = _historicalData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value['close']);
    }).toList();

    final minY = _historicalData
        .map((e) => e['close'] as double)
        .reduce((a, b) => a < b ? a : b);
    final maxY = _historicalData
        .map((e) => e['close'] as double)
        .reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 250,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_historicalData.length} Day Price Chart',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxY - minY) / 4,
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              '\$${value.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: (_historicalData.length / 4).ceilToDouble(),
                        getTitlesWidget: (value, meta) {
                          if (value < 0 || value >= _historicalData.length) {
                            return const SizedBox.shrink();
                          }

                          final index = value.toInt();
                          final date = _historicalData[index]['date'] as String;

                          try {
                            final dateParts = date.split('-');
                            if (dateParts.length == 3) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  '${dateParts[1]}/${dateParts[2]}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            }
                          } catch (e) {
                            return const SizedBox.shrink();
                          }

                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(color: Colors.grey[300]!),
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  minY: minY * 0.99,
                  maxY: maxY * 1.01,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: _quote != null && _quote!.change >= 0
                          ? Colors.green
                          : Colors.red,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: (_quote != null && _quote!.change >= 0
                            ? Colors.green
                            : Colors.red)
                            .withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ticker),
        actions: [
          IconButton(
            icon: Icon(_isInWatchlist ? Icons.star : Icons.star_border),
            onPressed: () async {
              if (_isInWatchlist) {
                await context
                    .read<WatchlistProvider>()
                    .removeStock(widget.ticker);
              } else {
                await context
                    .read<WatchlistProvider>()
                    .addStock(widget.ticker);
              }
              await _loadData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quote == null
          ? const Center(child: Text('Failed to load stock data'))
          : RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Price Header
              Container(
                width: double.infinity,
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _quote!.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${_quote!.price.toStringAsFixed(2)}',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          _quote!.change >= 0
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: _quote!.change >= 0
                              ? Colors.green
                              : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_quote!.change >= 0 ? '+' : ''}${_quote!.change.toStringAsFixed(2)} (${_quote!.changePercent.toStringAsFixed(2)}%)',
                          style: TextStyle(
                            color: _quote!.change >= 0
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Chart
              _buildPriceChart(),

              const Divider(),

              // Key Statistics
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Key Statistics',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildStatRow('Market Cap',
                        _formatMarketCap(_quote!.marketCap)),
                    _buildStatRow('Volume',
                        _formatNumber(_quote!.volume)),
                    _buildStatRow('Day High',
                        '\$${_quote!.dayHigh?.toStringAsFixed(2) ?? 'N/A'}'),
                    _buildStatRow('Day Low',
                        '\$${_quote!.dayLow?.toStringAsFixed(2) ?? 'N/A'}'),
                  ],
                ),
              ),

              // Company Profile
              if (_profile != null) ...[
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About ${_profile!.companyName}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      if (_profile!.sector != null)
                        Text('Sector: ${_profile!.sector}'),
                      if (_profile!.industry != null)
                        Text('Industry: ${_profile!.industry}'),
                      const SizedBox(height: 8),
                      if (_profile!.description != null)
                        Text(_profile!.description!),
                    ],
                  ),
                ),
              ],

              // Action Buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NotesScreen(
                                ticker: widget.ticker,
                              ),
                            ),
                          ).then((_) => _loadData());
                        },
                        icon: const Icon(Icons.notes),
                        label: Text('View Notes ($_notesCount)'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteEditorScreen(
                ticker: widget.ticker,
              ),
            ),
          ).then((_) => _loadData());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatMarketCap(double? marketCap) {
    if (marketCap == null) return 'N/A';
    if (marketCap >= 1e12) return '\$${(marketCap / 1e12).toStringAsFixed(2)}T';
    if (marketCap >= 1e9) return '\$${(marketCap / 1e9).toStringAsFixed(2)}B';
    if (marketCap >= 1e6) return '\$${(marketCap / 1e6).toStringAsFixed(2)}M';
    return '\$${marketCap.toStringAsFixed(2)}';
  }

  String _formatNumber(int? number) {
    if (number == null) return 'N/A';
    return NumberFormat.compact().format(number);
  }
}