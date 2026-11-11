// islamic_calendar_screen.dart
//
// Muslim Daily – World-Class 3D Animated Islamic Hijri Calendar.
// Responsive month grid, Islamic events highlights, jump to year, and 3D event detail cards.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:islam/core/storage/hive_service.dart';
import 'package:islam/core/ui/app_theme_tokens.dart';
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
    if (!mounted) return;
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
          backgroundColor: AppColors.surfaceContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Jump to Year',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              color: AppColors.onBackground,
            ),
          ),
          content: SizedBox(
            width: 300,
            height: 380,
            child: ListView.builder(
              itemCount: years.length,
              itemBuilder: (context, index) {
                final year = years[index];
                final isCurrent = year == _visibleMonth.year;
                return ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  selected: isCurrent,
                  selectedTileColor: AppColors.primary.withOpacity(0.15),
                  title: Text(
                    '$year',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                      color: isCurrent ? AppColors.primary : AppColors.onBackground,
                    ),
                  ),
                  onTap: () => Navigator.of(context).pop(year),
                );
              },
            ),
          ),
        );
      },
    );
    if (selected == null) return;
    setState(() {
      _visibleMonth = DateTime(selected, _visibleMonth.month, 1);
    });
    await _loadMonth();
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = AppResponsive.isSmall(context);
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
      final hasEvents = (match?.events.length ?? 0) > 0;

      cells.add(
        ScaleButton(
          onTap: match == null ? null : () => setState(() => _selectedDay = match),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(isSmall ? 2 : 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: isSelected
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1E3A2B), Color(0xFF112219)],
                    )
                  : null,
              color: isSelected
                  ? null
                  : (isToday
                      ? AppColors.primary.withOpacity(0.12)
                      : AppColors.surfaceContainer.withOpacity(0.6)),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : (isToday
                        ? AppColors.primary.withOpacity(0.6)
                        : Colors.white.withOpacity(0.06)),
                width: (isSelected || isToday) ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$day',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isSmall ? 12 : 14,
                      fontWeight: isToday || isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isToday
                          ? AppColors.primary
                          : (isSelected ? Colors.white : AppColors.onBackground),
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    match?.hijriDay.toString() ?? '',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isSmall ? 9 : 10,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? AppColors.secondary : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
                if (hasEvents)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Islamic Calendar',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: AppColors.onBackground,
          ),
        ),
        actions: [
          ScaleButton(
            onTap: _selectYear,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceContainerHigh.withOpacity(0.8),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                size: 20,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: AtmosphericBackground(
        child: Stack(
          children: [
          // Ambient Glows
          Positioned(
            top: 40,
            right: -60,
            child: GlowOrb(color: AppColors.primary, radius: 240, opacity: 0.12),
          ),
          Positioned(
            bottom: 40,
            left: -80,
            child: GlowOrb(color: AppColors.gold, radius: 220, opacity: 0.08),
          ),

          _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      children: [
                        // Month Navigation Bar
                        Card3D(
                          borderRadius: 22,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ScaleButton(
                                onTap: () async {
                                  setState(() {
                                    _visibleMonth = DateTime(
                                      _visibleMonth.year,
                                      _visibleMonth.month - 1,
                                      1,
                                    );
                                  });
                                  await _loadMonth();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.surfaceVariant.withOpacity(0.6),
                                  ),
                                  child: const Icon(
                                    Icons.chevron_left_rounded,
                                    color: AppColors.onSurface,
                                    size: 20,
                                  ),
                                ),
                              ),
                              Text(
                                DateFormat('MMMM yyyy').format(_visibleMonth),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  color: AppColors.onBackground,
                                ),
                              ),
                              ScaleButton(
                                onTap: () async {
                                  setState(() {
                                    _visibleMonth = DateTime(
                                      _visibleMonth.year,
                                      _visibleMonth.month + 1,
                                      1,
                                    );
                                  });
                                  await _loadMonth();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.surfaceVariant.withOpacity(0.6),
                                  ),
                                  child: const Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.onSurface,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Weekdays Row
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

                        // Calendar Grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 7,
                          crossAxisSpacing: isSmall ? 4 : 8,
                          mainAxisSpacing: isSmall ? 4 : 8,
                          childAspectRatio: isSmall ? 0.78 : 0.95,
                          children: cells,
                        ),
                        const SizedBox(height: 24),

                        // 3D Selected Date Card
                        if (_selectedDay != null)
                          Card3D(
                            borderRadius: 22,
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _selectedDay!.events.isEmpty
                                            ? AppColors.primary.withOpacity(0.15)
                                            : AppColors.gold.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: _selectedDay!.events.isEmpty
                                              ? AppColors.primary.withOpacity(0.3)
                                              : AppColors.gold.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        _selectedDay!.events.isEmpty
                                            ? 'SELECTED DATE'
                                            : 'ISLAMIC EVENT',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                          color: _selectedDay!.events.isEmpty
                                              ? AppColors.primary
                                              : AppColors.gold,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      DateFormat('dd MMM yyyy').format(
                                        _selectedDay!.gregorianDate,
                                      ),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _selectedDay!.events.isEmpty
                                      ? DateFormat('EEEE, MMMM d, yyyy').format(
                                          _selectedDay!.gregorianDate,
                                        )
                                      : _selectedDay!.events.first.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.onBackground,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Hijri: ${_selectedDay!.hijriDateLabel}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                                if (_selectedDay!.events.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    _selectedDay!.events.first.description,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      height: 1.5,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    ),
  );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String text;
  const _WeekdayLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
