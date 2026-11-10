// prayer_times_screen.dart
//
// Muslim Daily – World-Class 3D Animated Prayer Times screen.
// Responsive for phone, tablet, and desktop with precision waqt tracking.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:islam/core/navigation/ui_actions.dart';
import 'package:islam/core/storage/hive_keys.dart';
import 'package:islam/core/storage/hive_service.dart';
import 'package:islam/core/time/timezone_helper.dart';
import 'package:islam/core/ui/app_theme_tokens.dart';
import 'package:islam/features/location/presentation/district_selection_sheet.dart';
import 'package:islam/features/prayer/data/prayer_repository.dart';
import 'package:islam/features/prayer/domain/prayer_day_data.dart';
import 'package:islam/features/prayer/domain/prayer_time_entry.dart';
import 'package:islam/features/prayer/presentation/prayer_controller.dart';
import 'package:islam/features/settings/presentation/settings_controller.dart';

int monthlyCompletedPrayerCount(DateTime now) {
  final box = HiveService.instance.prayerTrackerBox;
  final prefix = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  var count = 0;
  for (final key in box.keys) {
    if (key is String && key.startsWith(prefix)) {
      if (box.get(key) == true) {
        count++;
      }
    }
  }
  return count;
}

int currentPrayerStreakDays(DateTime now) {
  final box = HiveService.instance.prayerTrackerBox;
  var streak = 0;
  var checkDate = DateTime(now.year, now.month, now.day);

  for (var i = 0; i < 365; i++) {
    final dateStr =
        '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
    var completedAny = false;
    for (final prayer in ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']) {
      if (box.get('${dateStr}_$prayer') == true) {
        completedAny = true;
        break;
      }
    }
    if (completedAny) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    } else {
      if (i == 0) {
        checkDate = checkDate.subtract(const Duration(days: 1));
        continue;
      }
      break;
    }
  }
  return streak;
}

int missedPrayerCount(DateTime now) {
  final box = HiveService.instance.prayerTrackerBox;
  var missed = 0;
  for (var i = 1; i <= 30; i++) {
    final d = now.subtract(Duration(days: i));
    final dateStr =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    for (final prayer in ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']) {
      final key = '${dateStr}_$prayer';
      final val = box.get(key);
      if (val == null || val == false) {
        missed++;
      }
    }
  }
  return missed;
}

IconData _iconForPrayer(String name) {
  switch (name.toLowerCase()) {
    case 'fajr':
      return Icons.wb_twilight_rounded;
    case 'dhuhr':
      return Icons.wb_sunny_rounded;
    case 'asr':
      return Icons.wb_cloudy_rounded;
    case 'maghrib':
      return Icons.nights_stay_rounded;
    case 'isha':
      return Icons.bedtime_rounded;
    default:
      return Icons.access_time_filled_rounded;
  }
}

class PrayerTimesScreen extends ConsumerStatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  ConsumerState<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends ConsumerState<PrayerTimesScreen> {
  final PrayerRepository _prayerRepository = PrayerRepository(
    HiveService.instance,
  );
  late DateTime _now;
  Timer? _ticker;
  PrayerDayData? _dayData;
  DateTime? _lastLoadedDay;

  String get _timezoneId {
    final settings = ref.read(settingsControllerProvider);
    return settings.timezone.trim().isNotEmpty
        ? settings.timezone.trim()
        : 'Asia/Dhaka';
  }

  @override
  void initState() {
    super.initState();
    _now = appNowForTimezone(_timezoneId);
    _loadPrayerData();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = appNowForTimezone(_timezoneId));
      _refreshDailyIfNeeded();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _loadPrayerData() async {
    final now = appNowForTimezone(_timezoneId);
    final data = await _prayerRepository.getPrayerDayData(now);
    if (!mounted) return;
    setState(() {
      _dayData = data;
      _lastLoadedDay = DateTime(now.year, now.month, now.day);
    });
  }

  void _refreshDailyIfNeeded() {
    final now = appNowForTimezone(_timezoneId);
    final day = DateTime(now.year, now.month, now.day);
    if (_lastLoadedDay == null || _lastLoadedDay != day) {
      _loadPrayerData();
    }
  }

  List<PrayerTimeEntry> get _fallbackPrayers {
    final settings = ref.read(settingsControllerProvider);
    final fallbackDay = PrayerRepository.calculatePrayerDayForSettings(
      date: _now,
      settings: settings,
    );
    return fallbackDay.prayers;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(settingsControllerProvider, (previous, next) {
      if (previous == null ||
          previous.city != next.city ||
          previous.country != next.country ||
          previous.timezone != next.timezone ||
          previous.prayerMethod != next.prayerMethod ||
          previous.madhhab != next.madhhab ||
          previous.latitude != next.latitude ||
          previous.longitude != next.longitude) {
        _loadPrayerData();
      }
    });

    final isWide = AppResponsive.isWide(context);
    final dayData = _dayData;
    final prayers = dayData?.prayers ?? _fallbackPrayers;
    final sunrise =
        dayData?.sunrise ?? DateTime(_now.year, _now.month, _now.day, 6, 0);
    final trackerState = ref.watch(prayerTrackerProvider);
    final settings = ref.watch(settingsControllerProvider);
    final monthlyCount = monthlyCompletedPrayerCount(_now);
    final streakDays = currentPrayerStreakDays(_now);
    final missedCount = missedPrayerCount(_now);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Ambient Glows
          Positioned(
            top: -80,
            right: -60,
            child: GlowOrb(color: AppColors.primary, radius: 260, opacity: 0.14),
          ),
          Positioned(
            bottom: 120,
            left: -80,
            child: GlowOrb(color: AppColors.gold, radius: 220, opacity: 0.08),
          ),

          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppResponsive.horizontalMargin(context),
                92,
                AppResponsive.horizontalMargin(context),
                AppResponsive.bottomScrollPad(context),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DateSummarySection(
                        isWide: isWide,
                        now: _now,
                        dayData: dayData,
                        monthlyCount: monthlyCount,
                        streakDays: streakDays,
                      ),
                      const SizedBox(height: 24),
                      _PrayerTimelineSection(
                        now: _now,
                        prayers: prayers,
                        sunrise: sunrise,
                        trackerState: trackerState,
                        notifyState: settings.perPrayerNotifications,
                        onToggleDone: (name) => ref
                            .read(prayerTrackerProvider.notifier)
                            .toggle(name),
                        onToggleNotify: (name, value) => ref
                            .read(settingsControllerProvider.notifier)
                            .setPrayerNotificationEnabled(name, value),
                      ),
                      const SizedBox(height: 20),
                      _MissedPrayerSection(missedCount: missedCount),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const Positioned(top: 0, left: 0, right: 0, child: _TopAppBar()),

          if (!isWide)
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SharedBottomNavBar(active: NavTab.prayer),
            ),
        ],
      ),
    );
  }
}

class _TopAppBar extends StatelessWidget {
  const _TopAppBar();

  @override
  Widget build(BuildContext context) {
    final settings =
        HiveService.instance.settingsBox.get(HiveKeys.appSettings) as Map?;
    final profileName = (settings?['profileName'] as String?) ?? 'Muslim Daily';
    final profileImageUrl = (settings?['profileImageUrl'] as String?) ?? '';
    return SharedTopAppBar(
      profileName: profileName,
      profileImageUrl: profileImageUrl,
    );
  }
}

// ---------------------------------------------------------------------------
// 3D Bento Date Summary Section
// ---------------------------------------------------------------------------
class _DateSummarySection extends StatelessWidget {
  final bool isWide;
  final DateTime now;
  final PrayerDayData? dayData;
  final int monthlyCount;
  final int streakDays;

  const _DateSummarySection({
    required this.isWide,
    required this.now,
    required this.dayData,
    required this.monthlyCount,
    required this.streakDays,
  });

  @override
  Widget build(BuildContext context) {
    final hijriLabel = dayData?.hijriLabel.isNotEmpty == true
        ? dayData!.hijriLabel
        : 'Loading Hijri date…';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'TODAY',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          hijriLabel,
          style: GoogleFonts.plusJakartaSans(
            fontSize: AppResponsive.scaleFont(context, min: 26, max: 40),
            letterSpacing: -1.0,
            fontWeight: FontWeight.w900,
            color: AppColors.onBackground,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          DateFormat('EEEE, MMMM d, yyyy').format(now),
          style: GoogleFonts.plusJakartaSans(
            fontSize: AppResponsive.scaleFont(context, min: 13, max: 16),
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 18),
        if (isWide)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _BentoCard(
                    icon: Icons.check_circle_outline_rounded,
                    iconColor: AppColors.primary,
                    label: 'This Month',
                    value: '$monthlyCount',
                    subtitle: 'Prayers',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _BentoCard(
                    icon: Icons.local_fire_department_rounded,
                    iconColor: AppColors.gold,
                    label: 'Streak',
                    value: '$streakDays Days',
                    subtitle: 'Consistency',
                    glow: true,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 2,
                  child: _LocationCardContent(dayData: dayData),
                ),
              ],
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _BentoCard(
                        icon: Icons.check_circle_outline_rounded,
                        iconColor: AppColors.primary,
                        label: 'This Month',
                        value: '$monthlyCount',
                        subtitle: 'Prayers',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BentoCard(
                        icon: Icons.local_fire_department_rounded,
                        iconColor: AppColors.gold,
                        label: 'Streak',
                        value: '$streakDays Days',
                        subtitle: 'Keep going!',
                        glow: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _LocationCardContent(dayData: dayData),
            ],
          ),
      ],
    );
  }
}

class _BentoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;
  final bool glow;

  const _BentoCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtitle,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card3D(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      glowColor: glow ? iconColor : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withOpacity(0.18),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                    color: AppColors.onBackground,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationCardContent extends StatelessWidget {
  const _LocationCardContent({required this.dayData});

  final PrayerDayData? dayData;

  @override
  Widget build(BuildContext context) {
    final settings =
        HiveService.instance.settingsBox.get(HiveKeys.appSettings) as Map?;
    final city = dayData?.city.isNotEmpty == true
        ? dayData!.city
        : ((settings?['city'] as String?) ?? 'Dhaka');
    final sunsetLabel = dayData != null
        ? DateFormat('h:mm a').format(dayData!.sunset)
        : '—';

    return Card3D(
      borderRadius: 20,
      padding: const EdgeInsets.all(18),
      onTap: () => showDistrictPicker(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'LOCATION (জেলা)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text(
                      'Change',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.edit_location_alt_rounded,
                      size: 12,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            city,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: AppColors.onBackground,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Sunset: $sunsetLabel • Tap to select from 64 BD Districts',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3D Prayer Timeline Section
// ---------------------------------------------------------------------------
class _PrayerTimelineSection extends StatelessWidget {
  final DateTime now;
  final List<PrayerTimeEntry> prayers;
  final DateTime sunrise;
  final Map<String, bool> trackerState;
  final Map<String, bool> notifyState;
  final void Function(String name) onToggleDone;
  final void Function(String name, bool value) onToggleNotify;

  const _PrayerTimelineSection({
    required this.now,
    required this.prayers,
    required this.sunrise,
    required this.trackerState,
    required this.notifyState,
    required this.onToggleDone,
    required this.onToggleNotify,
  });

  DateTime _getEndTime(int i) {
    if (prayers[i].name == 'Fajr') {
      return sunrise;
    } else if (i < prayers.length - 1) {
      return prayers[i + 1].time;
    } else {
      return prayers.first.time.add(const Duration(days: 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    var activeIndex = -1;
    for (var i = 0; i < prayers.length; i++) {
      final start = prayers[i].time;
      final end = _getEndTime(i);
      if (!now.isBefore(start) && now.isBefore(end)) {
        activeIndex = i;
        break;
      }
    }

    var nextUpcomingIndex = -1;
    if (activeIndex == -1) {
      for (var i = 0; i < prayers.length; i++) {
        if (now.isBefore(prayers[i].time)) {
          nextUpcomingIndex = i;
          break;
        }
      }
      if (nextUpcomingIndex == -1) nextUpcomingIndex = 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Prayer Times (ওয়াক্ত সময়সূচি)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: AppColors.onBackground,
          ),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < prayers.length; i++) ...[
          () {
            final endTime = _getEndTime(i);
            final isCurrent = i == activeIndex;
            final isPast = activeIndex != -1
                ? (i < activeIndex)
                : (nextUpcomingIndex == 0 ? false : i < nextUpcomingIndex);

            if (isCurrent) {
              return _CurrentPrayerRow(
                now: now,
                entry: prayers[i],
                endTime: endTime,
                notify: notifyState[prayers[i].name] ?? true,
                onToggleNotify: (v) => onToggleNotify(prayers[i].name, v),
              );
            } else if (isPast) {
              return _CompletedPrayerRow(
                entry: prayers[i],
                endTime: endTime,
                done: trackerState[prayers[i].name] ?? false,
                onToggleDone: () => onToggleDone(prayers[i].name),
              );
            } else {
              return _UpcomingPrayerRow(
                now: now,
                entry: prayers[i],
                endTime: endTime,
                isNext: (activeIndex == -1 && i == nextUpcomingIndex) ||
                    (activeIndex != -1 && i == activeIndex + 1),
                notify: notifyState[prayers[i].name] ?? true,
                onToggleNotify: (v) => onToggleNotify(prayers[i].name, v),
              );
            }
          }(),
          const SizedBox(height: 12),
          if (prayers[i].name == 'Fajr') ...[
            _SunriseRow(sunrise: sunrise),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}

class _CompletedPrayerRow extends StatelessWidget {
  final PrayerTimeEntry entry;
  final DateTime endTime;
  final bool done;
  final VoidCallback onToggleDone;

  const _CompletedPrayerRow({
    required this.entry,
    required this.endTime,
    required this.done,
    required this.onToggleDone,
  });

  @override
  Widget build(BuildContext context) {
    final rangeText =
        '${DateFormat('h:mm a').format(entry.time)} – ${DateFormat('h:mm a').format(endTime)}';

    return ScaleButton(
      onTap: onToggleDone,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AppColors.surfaceContainer.withOpacity(done ? 0.45 : 0.7),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceVariant.withOpacity(0.5),
              ),
              child: Icon(
                _iconForPrayer(entry.name),
                color: AppColors.onSurfaceVariant.withOpacity(0.6),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: done
                          ? AppColors.onSurfaceVariant.withOpacity(0.5)
                          : AppColors.onBackground,
                      decoration: done ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rangeText,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: done ? AppColors.primary : AppColors.onSurfaceVariant.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: done
                  ? const Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: AppColors.onPrimary,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SunriseRow extends StatelessWidget {
  final DateTime sunrise;
  const _SunriseRow({required this.sunrise});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            AppColors.gold.withOpacity(0.12),
            AppColors.gold.withOpacity(0.04),
          ],
        ),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withOpacity(0.15),
            ),
            child: const Icon(
              Icons.wb_sunny_rounded,
              size: 22,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sunrise (সূর্যোদয়)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${DateFormat('h:mm a').format(sunrise)} • Fajr ends (ফজরের ওয়াক্ত শেষ)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentPrayerRow extends StatelessWidget {
  final DateTime now;
  final PrayerTimeEntry entry;
  final DateTime endTime;
  final bool notify;
  final ValueChanged<bool> onToggleNotify;

  const _CurrentPrayerRow({
    required this.now,
    required this.entry,
    required this.endTime,
    required this.notify,
    required this.onToggleNotify,
  });

  @override
  Widget build(BuildContext context) {
    final remaining =
        endTime.isAfter(now) ? endTime.difference(now) : Duration.zero;
    final rangeText =
        '${DateFormat('h:mm a').format(entry.time)} – ${DateFormat('h:mm a').format(endTime)}';

    return Card3D(
      borderRadius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1E382A), Color(0xFF102218)],
      ),
      glowColor: AppColors.primary,
      border: Border.all(
        color: AppColors.primary.withOpacity(0.55),
        width: 1.5,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 14,
                ),
              ],
            ),
            child: Icon(
              _iconForPrayer(entry.name),
              color: AppColors.onPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onBackground,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'NOW',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w900,
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  rangeText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Ends in ${remaining.inHours > 0 ? '${remaining.inHours}h ' : ''}${remaining.inMinutes.remainder(60)}m',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ScaleButton(
            onTap: () => onToggleNotify(!notify),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: notify
                    ? AppColors.primary.withOpacity(0.2)
                    : AppColors.surfaceContainerHigh,
                shape: BoxShape.circle,
                border: Border.all(
                  color: notify ? AppColors.primary.withOpacity(0.4) : Colors.white10,
                ),
              ),
              child: Icon(
                notify ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                color: notify ? AppColors.primary : AppColors.onSurfaceVariant,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingPrayerRow extends StatelessWidget {
  final DateTime now;
  final PrayerTimeEntry entry;
  final DateTime endTime;
  final bool isNext;
  final bool notify;
  final ValueChanged<bool> onToggleNotify;

  const _UpcomingPrayerRow({
    required this.now,
    required this.entry,
    required this.endTime,
    this.isNext = false,
    required this.notify,
    required this.onToggleNotify,
  });

  @override
  Widget build(BuildContext context) {
    final rangeText =
        '${DateFormat('h:mm a').format(entry.time)} – ${DateFormat('h:mm a').format(endTime)}';
    final remaining =
        entry.time.isAfter(now) ? entry.time.difference(now) : Duration.zero;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isNext
            ? const Color(0xFF14241C)
            : AppColors.surfaceContainer.withOpacity(0.8),
        border: Border.all(
          color: isNext
              ? AppColors.secondary.withOpacity(0.5)
              : Colors.white.withOpacity(0.08),
          width: isNext ? 1.5 : 1,
        ),
        boxShadow: isNext
            ? [
                BoxShadow(
                  color: AppColors.secondary.withOpacity(0.12),
                  blurRadius: 14,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isNext
                  ? AppColors.secondary.withOpacity(0.18)
                  : AppColors.surfaceVariant.withOpacity(0.5),
            ),
            child: Icon(
              _iconForPrayer(entry.name),
              color: isNext ? AppColors.secondary : AppColors.onSurfaceVariant,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isNext ? AppColors.secondary : AppColors.onBackground,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isNext) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'NEXT WAQT',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  rangeText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isNext) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Starts in ${remaining.inHours > 0 ? '${remaining.inHours}h ' : ''}${remaining.inMinutes.remainder(60)}m',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          ScaleButton(
            onTap: () => onToggleNotify(!notify),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: notify
                    ? AppColors.primary.withOpacity(0.15)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                notify
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_off_rounded,
                color: notify
                    ? (isNext ? AppColors.secondary : AppColors.primary)
                    : AppColors.onSurfaceVariant.withOpacity(0.5),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3D Missed Prayer (Qada) Tracker Section
// ---------------------------------------------------------------------------
class _MissedPrayerSection extends StatelessWidget {
  final int missedCount;
  const _MissedPrayerSection({required this.missedCount});

  @override
  Widget build(BuildContext context) {
    return Card3D(
      borderRadius: 22,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.tertiaryContainer.withOpacity(0.15),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: AppColors.tertiaryContainer,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Qada (Missed Prayers)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: AppColors.onBackground,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$missedCount prayers unlogged in the past 30 days',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ScaleButton(
            onTap: () => UiActions.openPrayerTracker(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: AppColors.surfaceContainerHigh,
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Log',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onBackground,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: AppColors.onBackground,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
