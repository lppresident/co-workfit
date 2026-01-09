import 'package:flutter/material.dart';
import 'package:co_workfit/features/log_run/presentation/models/calendar_challenge_data.dart';

/// 주간 캘린더 위젯
class WeeklyCalendarWidget extends StatelessWidget {
  final DateTime selectedDate;
  final Map<DateTime, CalendarChallengeData> challengeDataMap;
  final ValueChanged<DateTime> onDateSelected;

  const WeeklyCalendarWidget({
    super.key,
    required this.selectedDate,
    required this.challengeDataMap,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final weekDates = _getWeekDates(selectedDate);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          // 주 선택 헤더
          _buildWeekHeader(context, weekDates.first),
          const SizedBox(height: 16),
          // 요일 표시
          _buildDayHeaders(),
          const SizedBox(height: 8),
          // 날짜 표시
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: weekDates.map((date) {
              final data = challengeDataMap[_normalizeDate(date)];
              final isSelected = _isSameDay(date, selectedDate);
              final isToday = _isSameDay(date, DateTime.now());

              return _DayCell(
                date: date,
                isSelected: isSelected,
                isToday: isToday,
                challengeData: data,
                onTap: () => onDateSelected(date),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekHeader(BuildContext context, DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${weekStart.month}월 ${weekStart.day}일 - ${weekEnd.month}월 ${weekEnd.day}일',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  final prevWeek = selectedDate.subtract(const Duration(days: 7));
                  onDateSelected(prevWeek);
                },
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  final nextWeek = selectedDate.add(const Duration(days: 7));
                  onDateSelected(nextWeek);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayHeaders() {
    const days = ['월', '화', '수', '목', '금', '토', '일'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: days.map((day) {
        return SizedBox(
          width: 48,
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

  List<DateTime> _getWeekDates(DateTime date) {
    final weekday = date.weekday;
    final monday = date.subtract(Duration(days: weekday - 1));

    return List.generate(7, (index) => monday.add(Duration(days: index)));
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
  final CalendarChallengeData? challengeData;
  final VoidCallback onTap;

  const _DayCell({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.challengeData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = challengeData?.hasChallenges ?? false;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 64,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : isToday
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isToday && !isSelected
              ? Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : isToday
                        ? Theme.of(context).primaryColor
                        : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            if (hasData) _buildIndicator(context),
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
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.green,
          shape: BoxShape.circle,
        ),
      );
    } else if (failureCount > 0) {
      return Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.red,
          shape: BoxShape.circle,
        ),
      );
    } else if (activeCount > 0) {
      return Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.orange,
          shape: BoxShape.circle,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
