String formatRelativeTimestamp(DateTime createdAt, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final elapsed = current.difference(createdAt);
  final today = DateTime(current.year, current.month, current.day);
  final postDay = DateTime(createdAt.year, createdAt.month, createdAt.day);
  final dayDifference = today.difference(postDay).inDays;

  if (dayDifference <= 0 && elapsed.inMinutes < 1) return 'Baru saja';
  if (dayDifference <= 0 && elapsed.inHours < 1) {
    return '${elapsed.inMinutes} menit lalu';
  }
  if (dayDifference <= 0) {
    return '${elapsed.inHours} jam lalu';
  }

  if (dayDifference == 1) return 'Kemarin';
  if (dayDifference < 7) return '$dayDifference hari lalu';
  if (dayDifference == 7) return 'Seminggu';

  final date = '${_twoDigits(createdAt.day)}/${_twoDigits(createdAt.month)}';
  if (createdAt.year == current.year) return date;

  return '$date/${_twoDigits(createdAt.year % 100)}';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');
