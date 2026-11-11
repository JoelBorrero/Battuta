/// Small helpers shared by the organization entities' JSON mapping.
///
/// Keys are the column names of the Supabase schema (snake_case).
library;

/// Parses a `timestamptz` value into a UTC instant.
DateTime? parseTimestamp(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc();
  return DateTime.tryParse(value.toString())?.toUtc();
}

/// Serializes an instant as an ISO-8601 UTC string.
String? formatTimestamp(DateTime? value) => value?.toUtc().toIso8601String();

/// Parses a Postgres `date` (`yyyy-MM-dd`) into a date-only [DateTime]
/// (local midnight, no time zone conversion).
DateTime parseDateOnly(Object? value) {
  final text = value.toString();
  final parts = text.split('T').first.split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

/// Serializes a [DateTime] as a Postgres `date` (`yyyy-MM-dd`), using the
/// calendar day of [value] as given (no time zone conversion).
String formatDateOnly(DateTime value) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${value.year.toString().padLeft(4, '0')}-${two(value.month)}-${two(value.day)}';
}

List<String> parseStringList(Object? value) {
  if (value is List) return value.map((e) => e.toString()).toList();
  return const [];
}

Map<String, dynamic> parseJsonMap(Object? value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}
