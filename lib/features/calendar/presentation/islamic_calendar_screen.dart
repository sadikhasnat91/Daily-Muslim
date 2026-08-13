import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:islam/core/storage/hive_service.dart';
import 'package:islam/features/calendar/data/islamic_calendar_repository.dart';

class IslamicCalendarScreen extends StatefulWidget {
  const IslamicCalendarScreen({super.key});

  @override
  State<IslamicCalendarScreen> createState() => _IslamicCalendarScreenState();
}

class _IslamicCalendarScreenState extends State<IslamicCalendarScreen> {
  late DateTime _visibleMonth;
  List<CalendarDayData> _days = const [];
  CalendarDayData? _selectedDay;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month, 1);
    _loadMonth();
  }

  Future<void> _loadMonth() async {
    setState(() => _loading = true);
    final repository = IslamicCalendarRepository(HiveService.instance);
    final days = await repository.loadMonth(
      year: _visibleMonth.year,
      month: _visibleMonth.month,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _days = days;
      _selectedDay = days.isNotEmpty ? days.first : null;
      _loading = false;
    });
  }

  Future<void> _selectYear() async {
    final years = List<int>.generate(60, (index) => 2000 + index);
    final selected = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Jump to Year'),
          content: SizedBox(
            width: 300,
            height: 400,
            child: ListView.builder(
              itemCount: years.length,
              itemBuilder: (context, index) {
                final year = years[index];
                return ListTile(
                  title: Text('$year'),
                  onTap: () => Navigator.of(context).pop(year),
                );
              },
            ),
          ),
        );
      },
    );
    if (selected == null) {
      return;
    }
    setState(() {
      _visibleMonth = DateTime(selected, _visibleMonth.month, 1);
    });
    await _loadMonth();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final firstWeekday = _visibleMonth.weekday % 7;
    final monthLength = DateUtils.getDaysInMonth(
      _visibleMonth.year,
      _visibleMonth.month,
    );
    final cells = <Widget>[];
    for (var i = 0; i < firstWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= monthLength; day++) {
      final current = DateTime(_visibleMonth.year, _visibleMonth.month, day);
      final match = _days.cast<CalendarDayData?>().firstWhere(
        (item) =>
            item != null &&
            item.gregorianDate.year == current.year &&
            item.gregorianDate.month == current.month &&
            item.gregorianDate.day == current.day,
        orElse: () => null,
      );
      final isToday =
          current.year == today.year &&
          current.month == today.month &&
          current.day == today.day;
      final isSelected = _selectedDay?.gregorianDate == current;
      cells.add(
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: match == null
              ? null
              : () {
                  setState(() => _selectedDay = match);
                },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                  : null,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isToday
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$day', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  match?.hijriDay.toString() ?? '',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if ((match?.events.length ?? 0) > 0) ...[
                  const Spacer(),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Islamic Calendar'),
        actions: [
          IconButton(
            onPressed: _selectYear,
            icon: const Icon(Icons.calendar_today_outlined),
            tooltip: 'Jump to year',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () async {
                            setState(() {
                              _visibleMonth = DateTime(
                                _visibleMonth.year,
                                _visibleMonth.month - 1,
                                1,
                              );
                            });
                            await _loadMonth();
                          },
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text(
                          DateFormat('MMMM yyyy').format(_visibleMonth),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        IconButton(
                          onPressed: () async {
                            setState(() {
                              _visibleMonth = DateTime(
                                _visibleMonth.year,
                                _visibleMonth.month + 1,
                                1,
                              );
                            });
                            await _loadMonth();
                          },
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        _WeekdayLabel('Sun'),
                        _WeekdayLabel('Mon'),
                        _WeekdayLabel('Tue'),
                        _WeekdayLabel('Wed'),
                        _WeekdayLabel('Thu'),
                        _WeekdayLabel('Fri'),
                        _WeekdayLabel('Sat'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 7,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.9,
                      children: cells,
                    ),
                    const SizedBox(height: 20),
                    if (_selectedDay != null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedDay!.events.isEmpty
                                    ? 'Selected Date'
                                    : _selectedDay!.events.first.name,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text('Hijri: ${_selectedDay!.hijriDateLabel}'),
                              Text(
                                'Gregorian: ${DateFormat('EEEE, dd MMM yyyy').format(_selectedDay!.gregorianDate)}',
                              ),
                              if (_selectedDay!.events.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(_selectedDay!.events.first.description),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
