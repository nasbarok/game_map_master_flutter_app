/// Buffer circulaire optimisé pour les positions
class CircularBuffer<T> {
  final List<T?> _buffer;
  final int _capacity;
  int _size = 0;
  int _head = 0;

  CircularBuffer(this._capacity) : _buffer = List.filled(_capacity, null);

  /// Ajoute un élément au buffer
  void add(T item) {
    _buffer[_head] = item;
    _head = (_head + 1) % _capacity;
    if (_size < _capacity) {
      _size++;
    }
  }

  /// Récupère tous les éléments valides
  List<T> getAll() {
    List<T> result = [];
    if (_size == 0) return result;

    int start = _size < _capacity ? 0 : _head;
    for (int i = 0; i < _size; i++) {
      int index = (start + i) % _capacity;
      T? item = _buffer[index];
      if (item != null) {
        result.add(item);
      }
    }
    return result;
  }

  /// Récupère le dernier élément
  T? get last {
    if (_size == 0) return null;
    int lastIndex = (_head - 1 + _capacity) % _capacity;
    return _buffer[lastIndex];
  }

  /// Vide le buffer
  void clear() {
    _size = 0;
    _head = 0;
    for (int i = 0; i < _capacity; i++) {
      _buffer[i] = null;
    }
  }

  /// Taille actuelle
  int get length => _size;

  /// Capacité maximale
  int get capacity => _capacity;

  /// Vérifie si le buffer est plein
  bool get isFull => _size == _capacity;

  /// Vérifie si le buffer est vide
  bool get isEmpty => _size == 0;
}