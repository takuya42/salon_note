const closedDayBookingMessage = '定休日のため予約できません';

/// Reads weekly closing days using Dart's weekday values (Monday = 1).
Set<int> readClosedWeekdays(Map<String, dynamic> data) {
  for (final field in const ['closedWeekdays', 'closedDays']) {
    if (data.containsKey(field)) {
      return _normalizeWeekdays(data[field]);
    }
  }

  return parseClosedWeekdaysFromBusinessHours(
    (data['businessHours'] as String?) ?? '',
  );
}

Set<int> parseClosedWeekdaysFromBusinessHours(String businessHours) {
  final closedSectionIndex = businessHours.indexOf('定休日');
  if (closedSectionIndex < 0) {
    return <int>{};
  }

  final closedSection = businessHours.substring(closedSectionIndex);
  const labels = <String, int>{
    '月': DateTime.monday,
    '火': DateTime.tuesday,
    '水': DateTime.wednesday,
    '木': DateTime.thursday,
    '金': DateTime.friday,
    '土': DateTime.saturday,
    '日': DateTime.sunday,
  };

  return {
    for (final entry in labels.entries)
      if (RegExp('${entry.key}(?:曜)?日').hasMatch(closedSection)) entry.value,
  };
}

bool isClosedDay(DateTime selectedDate, Iterable<int> closedWeekdays) {
  return closedWeekdays.contains(selectedDate.weekday);
}

Set<int> _normalizeWeekdays(dynamic value) {
  if (value is! Iterable) {
    return <int>{};
  }

  const labels = <String, int>{
    '月': DateTime.monday,
    '月曜': DateTime.monday,
    '月曜日': DateTime.monday,
    '火': DateTime.tuesday,
    '火曜': DateTime.tuesday,
    '火曜日': DateTime.tuesday,
    '水': DateTime.wednesday,
    '水曜': DateTime.wednesday,
    '水曜日': DateTime.wednesday,
    '木': DateTime.thursday,
    '木曜': DateTime.thursday,
    '木曜日': DateTime.thursday,
    '金': DateTime.friday,
    '金曜': DateTime.friday,
    '金曜日': DateTime.friday,
    '土': DateTime.saturday,
    '土曜': DateTime.saturday,
    '土曜日': DateTime.saturday,
    '日': DateTime.sunday,
    '日曜': DateTime.sunday,
    '日曜日': DateTime.sunday,
  };

  return value.map<int?>((day) {
    if (day is num) {
      final weekday = day.toInt();
      return weekday >= DateTime.monday && weekday <= DateTime.sunday
          ? weekday
          : null;
    }
    if (day is String) {
      return labels[day.trim()];
    }
    return null;
  }).whereType<int>().toSet();
}
