String toCsv(List<Map<String, dynamic>> rows, {List<String>? columns}) {
  if (rows.isEmpty) return '';
  final cols = columns ?? rows.first.keys.toList();
  final buffer = StringBuffer();
  buffer.writeln(cols.join(','));
  for (final r in rows) {
    final values =
        cols.map((c) => (r[c] ?? '').toString().replaceAll(',', ';'));
    buffer.writeln(values.join(','));
  }
  return buffer.toString();
}
