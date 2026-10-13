const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

String fmtDate(DateTime d) {
  final l = d.toLocal();
  final h = l.hour % 12 == 0 ? 12 : l.hour % 12;
  final m = l.minute.toString().padLeft(2, '0');
  final ap = l.hour >= 12 ? 'PM' : 'AM';
  return '${l.day} ${_months[l.month - 1]} ${l.year}, $h:$m $ap';
}

String fmtTimeAgo(DateTime? d) {
  if (d == null) return 'Never';
  final diff = DateTime.now().difference(d);
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  return fmtDate(d);
}

String nowIso() => DateTime.now().toUtc().toIso8601String();

DateTime? parseIso(String? value) =>
    value == null || value.isEmpty ? null : DateTime.tryParse(value);

String? blankToNull(String? value) {
  final v = value?.trim();
  return v == null || v.isEmpty ? null : v;
}
