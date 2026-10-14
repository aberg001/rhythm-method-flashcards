int _counter = 0;

/// A stable id. The counter keeps two calls in the same microsecond distinct.
String newId() {
  final micros = DateTime.now().toUtc().microsecondsSinceEpoch;
  _counter += 1;
  return '$micros-$_counter';
}
