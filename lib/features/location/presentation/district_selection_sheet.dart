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
            content: Text('লোকেশন আপডেট হয়েছে: ${detected.city} (${detected.country})'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('স্বয়ংক্রিয় লোকেশন পাওয়া যায়নি। তালিকা থেকে জেলা নির্বাচন করুন।'),
            backgroundColor: Colors.redAccent,
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            children: [
              // Drag Handle
              const SizedBox(height: 12),
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
                            'জেলা নির্বাচন করুন',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Select your district in Bangladesh',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.onSurfaceVariant),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Auto-detect Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isDetecting ? null : _autoDetect,
                    icon: _isDetecting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location, size: 18),
                    label: Text(
                      _isDetecting ? 'লোকেশন খোঁজা হচ্ছে...' : 'বর্তমান লোকেশন অটো-ডিটেক্ট করুন',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Search Box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  style: GoogleFonts.inter(color: AppColors.onSurface),
                  decoration: InputDecoration(
                    hintText: 'জেলার নাম খুঁজুন (যেমন: ঢাকা, চট্টগ্রাম, Sylhet...)',
                    hintStyle: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 20),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
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
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

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
                    return FilterChip(
                      selected: isSelected,
                      showCheckmark: false,
                      label: Text('${div.$2} (${div.$1})'),
                      labelStyle: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? Colors.black : AppColors.onSurfaceVariant,
                      ),
                      backgroundColor: AppColors.surfaceContainer,
                      selectedColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      side: BorderSide.none,
                      onSelected: (val) {
                        setState(() => _selectedDivision = div.$1);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Districts List
              Expanded(
                child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'কোনো জেলা পাওয়া যায়নি',
                        style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          tileColor: isSelected ? AppColors.primary.withOpacity(0.12) : null,
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.surfaceContainer,
                            ),
                            child: Icon(
                              Icons.location_on,
                              size: 18,
                              color: isSelected ? Colors.black : AppColors.primary,
                            ),
                          ),
                          title: Text(
                            '${d.nameBn} (${d.nameEn})',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? AppColors.primary : AppColors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            'বিভাগ: ${d.divisionBn} • $offsetText',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: AppColors.primary)
                              : const Icon(Icons.chevron_right, size: 18, color: Colors.white24),
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
                                  content: Text('লোকেশন সেট করা হয়েছে: ${d.nameBn} (${d.nameEn})'),
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

