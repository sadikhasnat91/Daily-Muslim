// prayer_times_screen.dart
//
// Muslim Daily – Prayer Times screen.
// Responsive for phone, tablet, and desktop.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:islam/core/navigation/ui_actions.dart';
import 'package:islam/core/storage/hive_keys.dart';
import 'package:islam/core/storage/hive_service.dart';
import 'package:islam/core/time/timezone_helper.dart';
import 'package:islam/core/ui/app_theme_tokens.dart';
import 'package:islam/features/prayer/data/prayer_repository.dart';
import 'package:islam/features/prayer/domain/prayer_day_data.dart';
import 'package:islam/features/prayer/domain/prayer_time_entry.dart';
import 'package:islam/features/prayer/presentation/prayer_controller.dart';
import 'package:islam/features/settings/domain/app_settings.dart';
import 'package:islam/features/settings/presentation/settings_controller.dart';

/// Icon shown for each of the five daily prayers.
IconData _iconForPrayer(String name) {
  switch (name) {
    case 'Fajr':
      return Icons.nights_stay;
    case 'Dhuhr':
      return Icons.light_mode;
    case 'Asr':
      return Icons.wb_twilight;
    case 'Maghrib':
      return Icons.wb_sunny;
    case 'Isha':
    default:
      return Icons.mode_night;
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
    final settings =
        HiveService.instance.settingsBox.get(HiveKeys.appSettings) as Map?;
    return (settings?['timezone'] as String?) ?? 'Asia/Riyadh';
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
    final fallbackDay = PrayerRepository.calculatePrayerDayForSettings(
      date: _now,
      settings: AppSettings.defaults,
    );
    return fallbackDay.prayers;
  }

  @override
  Widget build(BuildContext context) {
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
                      const SizedBox(height: AppSpacing.lg),
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
                      const SizedBox(height: AppSpacing.md),
                      _MissedPrayerSection(missedCount: missedCount),
                      const SizedBox(height: AppSpacing.xl),
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

// ---------------------------------------------------------------------------
// Top app bar
// ---------------------------------------------------------------------------
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
// Date & summary section (headline + bento grid)
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
        : null;

    final headlineFontSize = AppResponsive.scaleFont(context, min: 28, max: 48);
    // Bento card height – smaller on compact phones
    final bentoHeight = AppResponsive.isSmall(context) ? 130.0 : 160.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.md),
        Text(
          'TODAY',
          style: GoogleFonts.inter(
            fontSize: 13,
            letterSpacing: 0.65,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          hijriLabel ?? 'Loading Hijri date…',
          style: GoogleFonts.inter(
            fontSize: headlineFontSize,
            height: 1.17,
            letterSpacing: -0.96,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('EEEE, MMMM d, yyyy').format(now),
          style: GoogleFonts.inter(
            fontSize: AppResponsive.scaleFont(context, min: 14, max: 18),
            height: 1.55,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (isWide)
          SizedBox(
            height: bentoHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _BentoCard(
                    icon: Icons.task_alt,
                    iconColor: AppColors.primary,
                    label: 'This Month',
                    value: '$monthlyCount',
                    subtitle: 'Prayers Offered',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _BentoCard(
                    icon: Icons.local_fire_department,
                    iconColor: AppColors.secondary,
                    label: 'Streak',
                    valueWidgets: _streakSpans(streakDays),
                    subtitle: 'Keep it up!',
                    glow: true,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
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
              SizedBox(
                height: bentoHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _BentoCard(
                        icon: Icons.task_alt,
                        iconColor: AppColors.primary,
                        label: 'This Month',
                        value: '$monthlyCount',
                        subtitle: 'Prayers Offered',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _BentoCard(
                        icon: Icons.local_fire_department,
                        iconColor: AppColors.secondary,
                        label: 'Streak',
                        valueWidgets: _streakSpans(streakDays),
                        subtitle: 'Keep it up!',
                        glow: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 110),
                child: _LocationCardContent(dayData: dayData),
              ),
            ],
          ),
      ],
    );
  }
}

List<InlineSpan> _streakSpans(int days) {
  return [
    TextSpan(
      text: '$days ',
      style: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      ),
    ),
    TextSpan(
      text: days == 1 ? 'Day' : 'Days',
      style: GoogleFonts.inter(fontSize: 16, color: AppColors.onSurfaceVariant),
    ),
  ];
}

class _BentoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? value;
  final List<InlineSpan>? valueWidgets;
  final String subtitle;
  final bool glow;

  const _BentoCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.value,
    this.valueWidgets,
    required this.subtitle,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: BorderRadius.circular(12),
      tint: AppColors.surface.withOpacity(glow ? 0.65 : 0.6),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: iconColor),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      letterSpacing: 0.65,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (value != null)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value!,
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                if (valueWidgets != null)
                  RichText(text: TextSpan(children: valueWidgets)),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
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
        HiveService.instance.settingsBox.get('app_settings') as Map?;
    final city = dayData?.city ?? (settings?['city'] as String?) ?? 'Makkah';
    final sunsetLabel = dayData != null
        ? DateFormat('h:mm a').format(dayData!.sunset)
        : '—';

    return GlassSurface(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            bottom: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LOCATION',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        letterSpacing: 0.65,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            city,
                            style: GoogleFonts.inter(
                              fontSize: AppResponsive.scaleFont(
                                context,
                                min: 16,
                                max: 24,
                              ),
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  'Sunset: $sunsetLabel',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Prayer timeline section
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

  @override
  Widget build(BuildContext context) {
    var currentIndex = -1;
    for (var i = 0; i < prayers.length; i++) {
      if (!prayers[i].time.isAfter(now)) {
        currentIndex = i;
      }
    }
    if (currentIndex == -1) currentIndex = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Prayer Times',
          style: GoogleFonts.inter(
            fontSize: AppResponsive.scaleFont(context, min: 18, max: 24),
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < prayers.length; i++) ...[
          if (i == currentIndex)
            _CurrentPrayerRow(
              now: now,
              entry: prayers[i],
              notify: notifyState[prayers[i].name] ?? true,
              onToggleNotify: (v) => onToggleNotify(prayers[i].name, v),
            )
          else if (i < currentIndex)
            _CompletedPrayerRow(
              entry: prayers[i],
              done: trackerState[prayers[i].name] ?? false,
              onToggleDone: () => onToggleDone(prayers[i].name),
            )
          else
            _UpcomingPrayerRow(
              entry: prayers[i],
              notify: notifyState[prayers[i].name] ?? true,
              onToggleNotify: (v) => onToggleNotify(prayers[i].name, v),
            ),
          const SizedBox(height: AppSpacing.sm),
          if (prayers[i].name == 'Fajr') ...[
            _SunriseRow(sunrise: sunrise),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ],
    );
  }
}

class _CompletedPrayerRow extends StatelessWidget {
  final PrayerTimeEntry entry;
  final bool done;
  final VoidCallback onToggleDone;

  const _CompletedPrayerRow({
    required this.entry,
    required this.done,
    required this.onToggleDone,
  });

  @override
  Widget build(BuildContext context) {
    final nameFontSize = AppResponsive.scaleFont(context, min: 18, max: 24);

    return Opacity(
      opacity: done ? 0.6 : 0.85,
      child: GlassSurface(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onToggleDone,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceContainer,
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Icon(
                        _iconForPrayer(entry.name),
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.name,
                          style: GoogleFonts.inter(
                            fontSize: nameFontSize,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          DateFormat('h:mm a').format(entry.time),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Icon(
                  done ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: done ? AppColors.primary : AppColors.tertiaryContainer,
                ),
              ],
            ),
          ),
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
    return Opacity(
      opacity: 0.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 8,
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white24,
                  ),
                  child: SizedBox(width: 8, height: 8),
                ),
              ),
            ),
            Text(
              'Sunrise ${DateFormat('h:mm a').format(sunrise)}',
              style: GoogleFonts.inter(
                fontSize: 13,
                letterSpacing: 0.65,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentPrayerRow extends StatelessWidget {
  final DateTime now;
  final PrayerTimeEntry entry;
  final bool notify;
  final ValueChanged<bool> onToggleNotify;

  const _CurrentPrayerRow({
    required this.now,
    required this.entry,
    required this.notify,
    required this.onToggleNotify,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = AppResponsive.isWide(context);
    final target = entry.time;
    final isOngoing = !target.isAfter(now);
    final remaining = isOngoing ? Duration.zero : target.difference(now);
    final remainingH = remaining.inHours.toString().padLeft(2, '0');
    final remainingM = remaining.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final remainingS = remaining.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final nameFontSize = AppResponsive.scaleFont(context, min: 18, max: 24);

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 30,
                ),
              ],
            ),
            child: GlassSurface(
              tint: AppColors.surface.withOpacity(0.6),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      color: AppColors.primary.withOpacity(0.05),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 4, color: AppColors.primary),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary.withOpacity(0.2),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.3),
                                  ),
                                ),
                                child: Icon(
                                  _iconForPrayer(entry.name),
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            entry.name,
                                            style: GoogleFonts.inter(
                                              fontSize: nameFontSize,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          child: Text(
                                            'NOW',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              letterSpacing: 1,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      DateFormat('h:mm a').format(target),
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            if (isWide) ...[
                              Padding(
                                padding: const EdgeInsets.only(
                                  right: AppSpacing.md,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      isOngoing ? 'Status' : 'Time remaining',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                    Text(
                                      isOngoing
                                          ? 'Ongoing'
                                          : '$remainingH:$remainingM:$remainingS',
                                      style: GoogleFonts.inter(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.onSurface,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            _PrayerToggle(
                              value: notify,
                              onChanged: onToggleNotify,
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              notify
                                  ? Icons.notifications_active
                                  : Icons.notifications_off,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UpcomingPrayerRow extends StatelessWidget {
  final PrayerTimeEntry entry;
  final bool notify;
  final ValueChanged<bool> onToggleNotify;

  const _UpcomingPrayerRow({
    required this.entry,
    required this.notify,
    required this.onToggleNotify,
  });

  @override
  Widget build(BuildContext context) {
    final nameFontSize = AppResponsive.scaleFont(context, min: 18, max: 24);

    return GlassSurface(
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceContainer,
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Icon(
                    _iconForPrayer(entry.name),
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      style: GoogleFonts.inter(
                        fontSize: nameFontSize,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      DateFormat('h:mm a').format(entry.time),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                _PrayerToggle(value: notify, onChanged: onToggleNotify),
                if (!notify) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.notifications_off,
                    color: AppColors.onSurfaceVariant.withOpacity(0.5),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Pill-style on/off toggle.
class _PrayerToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _PrayerToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 48,
        height: 24,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(999),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 300),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Missed prayer (Qada) tracker section
// ---------------------------------------------------------------------------
class _MissedPrayerSection extends StatelessWidget {
  final int missedCount;
  const _MissedPrayerSection({required this.missedCount});

  @override
  Widget build(BuildContext context) {
    final isWide = AppResponsive.isWide(context);

    final icon = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.tertiaryContainer.withOpacity(0.1),
      ),
      child: const Icon(Icons.history, color: AppColors.tertiaryContainer),
    );

    final textBlock = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Qada (Missed Prayers)',
            style: GoogleFonts.inter(
              fontSize: AppResponsive.scaleFont(context, min: 16, max: 24),
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Keep track of your missed prayers and log them as you complete them.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );

    final remainingBadge = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            '$missedCount',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: AppColors.tertiaryContainer,
            ),
          ),
          Text(
            'Remaining',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );

    final viewLogButton = OutlinedButton(
      onPressed: () => UiActions.openPrayerTracker(context),
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.surfaceContainerHigh,
        side: const BorderSide(color: Colors.white10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'View Log',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward, size: 14, color: AppColors.onSurface),
        ],
      ),
    );

    return GlassSurface(
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: isWide
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        icon,
                        const SizedBox(width: AppSpacing.md),
                        textBlock,
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  remainingBadge,
                  const SizedBox(width: AppSpacing.sm),
                  viewLogButton,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      icon,
                      const SizedBox(width: AppSpacing.md),
                      textBlock,
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [remainingBadge, viewLogButton],
                  ),
                ],
              ),
      ),
    );
  }
}
