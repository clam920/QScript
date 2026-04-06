import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/stock_quote.dart';
import '../models/stock_profile.dart';
import '../models/stock_note.dart';
import '../services/fmp_service.dart';
import '../services/finnhub_service.dart';
import '../providers/watchlist_provider.dart';
import '../providers/notes_provider.dart';
import 'note_editor_screen.dart';
import 'news_detail_screen.dart';

class StockDetailScreen extends StatefulWidget {
  final String ticker;

  const StockDetailScreen({super.key, required this.ticker});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> with SingleTickerProviderStateMixin {
  final FMPService _fmpService = FMPService();
  final FinnhubService _finnhubService = FinnhubService();
  late TabController _tabController;

  StockQuote? _quote;
  StockProfile? _profile;
  List<Map<String, dynamic>> _historicalData = [];
  List<dynamic> _news = [];
  bool _isLoading = true;
  bool _isNewsLoading = false;
  bool _isInWatchlist = false;
  String _newsPeriod = '7'; // Default to 7 days

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    setState(() {});
    
    if (_tabController.index == 1 && _news.isEmpty) {
      _loadNews();
    } else if (_tabController.index == 2) {
      context.read<NotesProvider>().loadNotesByTicker(widget.ticker);
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final provider = context.read<WatchlistProvider>();
    var quote = provider.quotes[widget.ticker];

    if (quote == null) {
      quote = await provider.getQuoteForTicker(widget.ticker);
    }

    final profile = await _fmpService.getProfile(widget.ticker);
    final historical = await _fmpService.getHistoricalPrices(widget.ticker);
    final inWatchlist = await provider.isInWatchlist(widget.ticker);

    setState(() {
      _quote = quote;
      _profile = profile;
      _historicalData = historical;
      _isInWatchlist = inWatchlist;
      _isLoading = false;
    });

    if (_tabController.index == 2) {
      context.read<NotesProvider>().loadNotesByTicker(widget.ticker);
    }
  }

  Future<void> _loadNews() async {
    setState(() => _isNewsLoading = true);

    final toDate = DateTime.now();
    DateTime fromDate;

    switch (_newsPeriod) {
      case '30':
        fromDate = toDate.subtract(const Duration(days: 30));
        break;
      case '90':
        fromDate = toDate.subtract(const Duration(days: 90));
        break;
      case '7':
      default:
        fromDate = toDate.subtract(const Duration(days: 7));
        break;
    }

    final dateFormat = DateFormat('yyyy-MM-dd');
    final news = await _finnhubService.getCompanyNews(
      widget.ticker,
      dateFormat.format(fromDate),
      dateFormat.format(toDate),
    );

    setState(() {
      _news = news;
      _isNewsLoading = false;
    });
  }

  Widget _buildInfoTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_quote == null) return const Center(child: Text('Failed to load stock data'));

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_quote!.name, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('\$${_quote!.price.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(_quote!.change >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                          color: _quote!.change >= 0 ? Colors.green : Colors.red, size: 16),
                      const SizedBox(width: 4),
                      Text('${_quote!.change >= 0 ? '+' : ''}${_quote!.change.toStringAsFixed(2)} (${_quote!.changePercent.toStringAsFixed(2)}%)',
                          style: TextStyle(color: _quote!.change >= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ),
            _buildPriceChart(),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Key Statistics', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  _buildStatRow('Market Cap', _formatMarketCap(_quote!.marketCap)),
                  _buildStatRow('Volume', _formatNumber(_quote!.volume)),
                  _buildStatRow('Day High', '\$${_quote!.dayHigh?.toStringAsFixed(2) ?? 'N/A'}'),
                  _buildStatRow('Day Low', '\$${_quote!.dayLow?.toStringAsFixed(2) ?? 'N/A'}'),
                ],
              ),
            ),
            if (_profile != null) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('About ${_profile!.companyName}', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    if (_profile!.sector != null) Text('Sector: ${_profile!.sector}'),
                    if (_profile!.industry != null) Text('Industry: ${_profile!.industry}'),
                    const SizedBox(height: 8),
                    if (_profile!.description != null) Text(_profile!.description!),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Period: '),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _newsPeriod,
                items: const [
                  DropdownMenuItem(value: '7', child: Text('Last 7 Days')),
                  DropdownMenuItem(value: '30', child: Text('Last 30 Days')),
                  DropdownMenuItem(value: '90', child: Text('Last 3 Months')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _newsPeriod = value);
                    _loadNews();
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _isNewsLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
            onRefresh: _loadNews,
            child: _news.isEmpty
                ? const Center(child: Text('No news found for this period'))
                : ListView.separated(
              itemCount: _news.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final article = _news[index];
                final date = DateTime.fromMillisecondsSinceEpoch((article['datetime'] as int) * 1000);

                return ListTile(
                  title: Text(article['headline'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(article['summary'] ?? '', maxLines: 3, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(article['source'] ?? '', style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w500)),
                          Text(DateFormat('MMM d, y').format(date)),
                        ],
                      ),
                    ],
                  ),
                  trailing: article['image'] != null && (article['image'] as String).isNotEmpty
                      ? Image.network(article['image'], width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.newspaper))
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NewsDetailScreen(article: article),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesTab() {
    return Consumer<NotesProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) return const Center(child: CircularProgressIndicator());
        if (provider.notes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.note_add, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No notes for this stock yet'),
                ElevatedButton(onPressed: () => _addNote(), child: const Text('Add your first note')),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => provider.loadNotesByTicker(widget.ticker),
          child: ListView.builder(
            itemCount: provider.notes.length,
            itemBuilder: (context, index) {
              final note = provider.notes[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(note.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('Updated: ${DateFormat('MMM d, y HH:mm').format(note.updatedAt)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  onTap: () => _editNote(note),
                  trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteNote(note.id!)),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _addNote() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => NoteEditorScreen(ticker: widget.ticker)))
        .then((_) => context.read<NotesProvider>().loadNotesByTicker(widget.ticker));
  }

  void _editNote(StockNote note) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => NoteEditorScreen(ticker: widget.ticker, note: note)))
        .then((_) => context.read<NotesProvider>().loadNotesByTicker(widget.ticker));
  }

  void _deleteNote(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () { context.read<NotesProvider>().deleteNote(id); Navigator.pop(context); }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Widget _buildPriceChart() {
    if (_historicalData.isEmpty) return const SizedBox(height: 200, child: Center(child: Text('No chart data available')));
    final spots = _historicalData.asMap().entries.map((entry) => FlSpot(entry.key.toDouble(), entry.value['close'])).toList();
    final minY = _historicalData.map((e) => e['close'] as double).reduce((a, b) => a < b ? a : b);
    final maxY = _historicalData.map((e) => e['close'] as double).reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 250,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_historicalData.length} Day Price Chart', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: (maxY - minY) / 4),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 45, getTitlesWidget: (value, meta) => Padding(padding: const EdgeInsets.only(right: 8.0), child: Text('\$${value.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10))))),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: (_historicalData.length / 4).ceilToDouble(), getTitlesWidget: (value, meta) {
                      if (value < 0 || value >= _historicalData.length) return const SizedBox.shrink();
                      final index = value.toInt();
                      final date = _historicalData[index]['date'] as String;
                      try {
                        final dateParts = date.split('-');
                        if (dateParts.length == 3) return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text('${dateParts[1]}/${dateParts[2]}', style: const TextStyle(fontSize: 10)));
                      } catch (e) { return const SizedBox.shrink(); }
                      return const SizedBox.shrink();
                    })),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true, border: Border(left: BorderSide(color: Colors.grey[300]!), bottom: BorderSide(color: Colors.grey[300]!))),
                  minY: minY * 0.99,
                  maxY: maxY * 1.01,
                  lineBarsData: [LineChartBarData(spots: spots, isCurved: true, color: _quote != null && _quote!.change >= 0 ? Colors.green : Colors.red, barWidth: 2, dotData: FlDotData(show: false), belowBarData: BarAreaData(show: true, color: (_quote != null && _quote!.change >= 0 ? Colors.green : Colors.red).withOpacity(0.1)))],
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
              if (_isInWatchlist) { await context.read<WatchlistProvider>().removeStock(widget.ticker); }
              else { await context.read<WatchlistProvider>().addStock(widget.ticker); }
              await _loadData();
            },
          ),
        ],
        bottom: TabBar(controller: _tabController, tabs: const [Tab(text: 'Info', icon: Icon(Icons.info_outline)), Tab(text: 'News', icon: Icon(Icons.newspaper)), Tab(text: 'Notes', icon: Icon(Icons.notes))]),
      ),
      body: TabBarView(controller: _tabController, children: [_buildInfoTab(), _buildNewsTab(), _buildNotesTab()]),
      floatingActionButton: _tabController.index == 2 ? FloatingActionButton(onPressed: _addNote, tooltip: 'Add Note', child: const Icon(Icons.add)) : null,
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.grey)), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))]));
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