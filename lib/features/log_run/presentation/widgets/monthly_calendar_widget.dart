import 'package:flutter/material.dart';
import 'package:co_workfit/features/log_run/presentation/models/calendar_challenge_data.dart';

/// 월간 캘린더 위젯
class MonthlyCalendarWidget extends StatelessWidget {
  final DateTime selectedDate;
  final Map<DateTime, CalendarChallengeData> challengeDataMap;
  final ValueChanged<DateTime> onDateSelected;

  const MonthlyCalendarWidget({
    super.key,
    required this.selectedDate,
    required this.challengeDataMap,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 월 선택 헤더
          _buildMonthHeader(context),
          const SizedBox(height: 16),
          // 요일 표시
          _buildDayHeaders(),
          const SizedBox(height: 8),
          // 날짜 그리드
          _buildCalendarGrid(context),
        ],
      ),
    );
  }

  Widget _buildMonthHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${selectedDate.year}년 ${selectedDate.month}월',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                final prevMonth = DateTime(
                  selectedDate.year,
                  selectedDate.month - 1,
                  1,
                );
                onDateSelected(prevMonth);
              },
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                final nextMonth = DateTime(
                  selectedDate.year,
                  selectedDate.month + 1,
                  1,
                );
                onDateSelected(nextMonth);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDayHeaders() {
    const days = ['월', '화', '수', '목', '금', '토', '일'];

    return Row(
      children: days.map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    final monthDates = _getMonthDates(selectedDate);
    final weeks = <List<DateTime?>>[];

    // 주 단위로 분할
    for (var i = 0; i < monthDates.length; i += 7) {
      weeks.add(monthDates.sublist(i, i + 7));
    }

    return Column(
      children: weeks.map((week) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: week.map((date) {
              if (date == null) {
                return const Expanded(child: SizedBox(height: 48));
              }

              final data = challengeDataMap[_normalizeDate(date)];
              final isSelected = _isSameDay(date, selectedDate);
              final isToday = _isSameDay(date, DateTime.now());
              final isCurrentMonth = date.month == selectedDate.month;

              return Expanded(
                child: _DayCell(
                  date: date,
                  isSelected: isSelected,
                  isToday: isToday,
                  isCurrentMonth: isCurrentMonth,
                  challengeData: data,
                  onTap: () => onDateSelected(date),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  List<DateTime?> _getMonthDates(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    final lastDay = DateTime(date.year, date.month + 1, 0);

    final startWeekday = firstDay.weekday;
    final dates = <DateTime?>[];

    // 이전 달 빈 칸
    for (var i = 1; i < startWeekday; i++) {
      dates.add(null);
    }

    // 현재 달 날짜
    for (var day = 1; day <= lastDay.day; day++) {
      dates.add(DateTime(date.year, date.month, day));
    }

    // 다음 달 빈 칸 (7의 배수로 맞추기)
    while (dates.length % 7 != 0) {
      dates.add(null);
    }

    return dates;
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DayCell extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final bool isCurrentMonth;
  final CalendarChallengeData? challengeData;
  final VoidCallback onTap;

  const _DayCell({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.isCurrentMonth,
    required this.challengeData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = challengeData?.hasChallenges ?? false;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : isToday
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Colors.transparent,
          shape: BoxShape.circle,
          border: isToday && !isSelected
              ? Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                )
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : !isCurrentMonth
                        ? Colors.grey[400]
                        : isToday
                            ? Theme.of(context).primaryColor
                            : Colors.black87,
              ),
            ),
            if (hasData)
              Positioned(
                bottom: 6,
                child: _buildIndicator(context),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicator(BuildContext context) {
    final successCount = challengeData!.successCount;
    final failureCount = challengeData!.failureCount;
    final activeCount = challengeData!.activeCount;

    if (successCount > 0) {
      return Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.green,
          shape: BoxShape.circle,
        ),
      );
    } else if (failureCount > 0) {
      return Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.red,
          shape: BoxShape.circle,
        ),
      );
    } else if (activeCount > 0) {
      return Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.orange,
          shape: BoxShape.circle,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
