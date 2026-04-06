import 'package:flutter/foundation.dart';
import '../models/stock_note.dart';
import '../services/notes_service.dart';

class NotesProvider extends ChangeNotifier {
  final NotesService _notesService = NotesService();

  List<StockNote> _notes = [];
  bool _isLoading = false;
  String? _error;
  String? _currentTickerFilter;

  List<StockNote> get notes => _notes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAllNotes() async {
    _isLoading = true;
    _error = null;
    _currentTickerFilter = null;
    notifyListeners();

    try {
      _notes = await _notesService.getAllNotes();
    } catch (e) {
      _error = 'Failed to load notes: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNotesByTicker(String ticker) async {
    _isLoading = true;
    _error = null;
    _currentTickerFilter = ticker;
    notifyListeners();

    try {
      _notes = await _notesService.getNotesByTicker(ticker);
    } catch (e) {
      _error = 'Failed to load notes: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int> getNotesCountByTicker(String ticker) async {
    return await _notesService.getNotesCountByTicker(ticker);
  }

  Future<void> createNote(StockNote note) async {
    try {
      await _notesService.createNote(note);
      await _reloadCurrentView();
    } catch (e) {
      _error = 'Failed to create note: $e';
      notifyListeners();
    }
  }

  Future<void> updateNote(StockNote note) async {
    try {
      await _notesService.updateNote(note);
      await _reloadCurrentView();
    } catch (e) {
      _error = 'Failed to update note: $e';
      notifyListeners();
    }
  }

  Future<void> deleteNote(int id) async {
    try {
      await _notesService.deleteNote(id);
      await _reloadCurrentView();
    } catch (e) {
      _error = 'Failed to delete note: $e';
      notifyListeners();
    }
  }

  Future<void> searchNotes(String query) async {
    if (query.isEmpty) {
      await _reloadCurrentView();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _notes = await _notesService.searchNotes(query, ticker: _currentTickerFilter);
    } catch (e) {
      _error = 'Failed to search notes: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _reloadCurrentView() async {
    if (_currentTickerFilter != null) {
      await loadNotesByTicker(_currentTickerFilter!);
    } else {
      await loadAllNotes();
    }
  }
}