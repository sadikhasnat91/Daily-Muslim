// district_selection_sheet.dart
//
// Muslim Daily – World-Class 3D Animated Bangladesh District Selection Sheet.
// 64 districts with Bengali & English search, division pills, auto GPS location detection.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:islam/core/ui/app_theme_tokens.dart';
import 'package:islam/features/location/data/bd_districts.dart';
import 'package:islam/features/location/data/location_detection_service.dart';
import 'package:islam/features/settings/presentation/settings_controller.dart';

Future<void> showDistrictPicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const DistrictSelectionSheet(),
  );
}

class DistrictSelectionSheet extends ConsumerStatefulWidget {
  const DistrictSelectionSheet({super.key});

  @override
  ConsumerState<DistrictSelectionSheet> createState() => _DistrictSelectionSheetState();
}

class _DistrictSelectionSheetState extends ConsumerState<DistrictSelectionSheet> {
  final _searchController = TextEditingController();
  String _query = '';
  String _selectedDivision = 'All';
  bool _isDetecting = false;

  final _divisions = const [
    ('All', 'সব'),
    ('Dhaka', 'ঢাকা'),
    ('Chattogram', 'চট্টগ্রাম'),
    ('Sylhet', 'সিলেট'),
    ('Rajshahi', 'রাজশাহী'),
    ('Khulna', 'খুলনা'),
    ('Barishal', 'বরিশাল'),
    ('Rangpur', 'রংপুর'),
    ('Mymensingh', 'ময়মনসিংহ'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _autoDetect() async {
    setState(() => _isDetecting = true);
    final detected = await LocationDetectionService.instance.detectLocation();
    if (!mounted) return;
    setState(() => _isDetecting = false);

    if (detected != null) {
      await ref.read(settingsControllerProvider.notifier).setLocation(
            city: detected.city,
            latitude: detected.lat,
            longitude: detected.lng,
            country: detected.country,
            countryCode: detected.countryCode,
            timezone: detected.timezone,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'লোকেশন আপডেট হয়েছে: ${detected.city} (${detected.country})',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'স্বয়ংক্রিয় লোকেশন পাওয়া যায়নি। তালিকা থেকে জেলা নির্বাচন করুন।',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentSettings = ref.watch(settingsControllerProvider);
    final currentCity = currentSettings.city.trim().toLowerCase();

    final filtered = kAllBangladeshDistricts.where((d) {
      if (_selectedDivision != 'All' && d.divisionEn != _selectedDivision) {
        return false;
      }
      if (_query.isEmpty) return true;
      final q = _query.trim().toLowerCase();
      return d.nameEn.toLowerCase().contains(q) ||
          d.nameBn.contains(q) ||
          d.divisionEn.toLowerCase().contains(q) ||
          d.divisionBn.contains(q);
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 40,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Drag Handle
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),

              // Title Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'জেলা নির্বাচন করুন (Bangladesh)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onBackground,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Select your district to align exact prayer waqt times',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.onSurfaceVariant),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3D Auto-detect Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ScaleButton(
                  onTap: _isDetecting ? null : _autoDetect,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E382A), Color(0xFF102018)],
                      ),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.15),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isDetecting)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(AppColors.primary),
                            ),
                          )
                        else
                          const Icon(
                            Icons.my_location_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _isDetecting ? 'লোকেশন খোঁজা হচ্ছে...' : 'বর্তমান লোকেশন অটো-ডিটেক্ট করুন',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Search Box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  style: GoogleFonts.plusJakartaSans(color: AppColors.onBackground),
                  decoration: InputDecoration(
                    hintText: 'জেলার নাম খুঁজুন (যেমন: ঢাকা, চট্টগ্রাম, Sylhet...)',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: AppColors.onSurfaceVariant.withOpacity(0.7),
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surfaceContainer,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Division Filter Chips
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _divisions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final div = _divisions[idx];
                    final isSelected = _selectedDivision == div.$1;
                    return ScaleButton(
                      onTap: () => setState(() => _selectedDivision = div.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: isSelected
                              ? AppColors.primaryGradient
                              : null,
                          color: isSelected ? null : AppColors.surfaceContainerHigh,
                          border: Border.all(
                            color: isSelected
                                ? Colors.white.withOpacity(0.2)
                                : Colors.white.withOpacity(0.06),
                          ),
                        ),
                        child: Text(
                          '${div.$2} (${div.$1})',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Districts List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'কোনো জেলা পাওয়া যায়নি',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: Colors.white.withOpacity(0.06),
                        ),
                        itemBuilder: (context, index) {
                          final d = filtered[index];
                          final isSelected = currentCity == d.nameEn.toLowerCase() ||
                              currentCity == d.nameBn.toLowerCase();

                          String offsetText;
                          if (d.offsetMinutesFromDhaka == 0) {
                            offsetText = 'ঢাকার সময়';
                          } else if (d.offsetMinutesFromDhaka > 0) {
                            offsetText = '+${d.offsetMinutesFromDhaka} মি. পর';
                          } else {
                            offsetText = '${d.offsetMinutesFromDhaka} মি. আগে';
                          }

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            tileColor: isSelected
                                ? AppColors.primary.withOpacity(0.12)
                                : null,
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: isSelected ? AppColors.primaryGradient : null,
                                color: isSelected ? null : AppColors.surfaceContainer,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white.withOpacity(0.2)
                                      : Colors.white10,
                                ),
                              ),
                              child: Icon(
                                Icons.location_on_rounded,
                                size: 18,
                                color: isSelected ? AppColors.onPrimary : AppColors.primary,
                              ),
                            ),
                            title: Text(
                              '${d.nameBn} (${d.nameEn})',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? AppColors.primary : AppColors.onBackground,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              'বিভাগ: ${d.divisionBn} • $offsetText',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.primary,
                                  )
                                : const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 18,
                                    color: Colors.white24,
                                  ),
                            onTap: () async {
                              await ref.read(settingsControllerProvider.notifier).setLocation(
                                    city: d.nameEn,
                                    latitude: d.latitude,
                                    longitude: d.longitude,
                                    country: 'Bangladesh',
                                    countryCode: 'BD',
                                    timezone: 'Asia/Dhaka',
                                  );
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'লোকেশন সেট করা হয়েছে: ${d.nameBn} (${d.nameEn})',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    backgroundColor: AppColors.primary,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
