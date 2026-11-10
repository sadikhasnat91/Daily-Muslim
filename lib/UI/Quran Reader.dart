// quran_reader_screen.dart
//
// Muslim Daily – World-Class 3D Animated Quran Reader & Audio Player screen.
// Responsive for phone, tablet, and desktop with Arabic typography and continuous recitation.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:islam/core/navigation/ui_actions.dart';
import 'package:islam/core/storage/hive_service.dart';
import 'package:islam/core/ui/app_theme_tokens.dart';
import 'package:islam/features/quran/data/quran_repository.dart';
import 'package:islam/features/quran/domain/quran_surah_detail.dart';
import 'package:islam/features/quran/domain/surah.dart';
import 'package:just_audio/just_audio.dart';

class QuranReaderScreen extends StatefulWidget {
  final int surahId;
  const QuranReaderScreen({super.key, required this.surahId});

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  final QuranRepository _repository = QuranRepository(HiveService.instance);
  late final AudioPlayer _player;
  late Future<QuranSurahDetail> _detailFuture;
  QuranSurahDetail? _detail;
  int _currentAyah = 1;
  bool _audioReady = false;
  double _playbackSpeed = 1;
  LoopMode _loopMode = LoopMode.off;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _detailFuture = _loadDetail();
    _player.currentIndexStream.listen((index) async {
      final detail = _detail;
      if (!mounted || detail == null || index == null) return;
      final ayah = detail.ayahs[index];
      setState(() => _currentAyah = ayah.numberInSurah);
      await _repository.updateRecentAyah(
        surah: detail.surah,
        ayahNumber: ayah.numberInSurah,
      );
    });
  }

  Future<QuranSurahDetail> _loadDetail() async {
    final detail = await _repository.loadSurahDetail(widget.surahId);
    _detail = detail;
    final recent = _repository.getRecent();
    final currentAyah = (recent?['id'] as int?) == detail.surah.id
        ? (recent?['ayahNumber'] as int?) ?? 1
        : 1;
    _currentAyah = currentAyah.clamp(
      1,
      detail.ayahs.isEmpty ? 1 : detail.ayahs.length,
    );
    await _repository.updateRecentAyah(
      surah: detail.surah,
      ayahNumber: _currentAyah,
    );
    await _configureAudio(detail);
    return detail;
  }

  Future<void> _configureAudio(QuranSurahDetail detail) async {
    final sources = detail.ayahs
        .where((ayah) => ayah.audioUrl.isNotEmpty)
        .map((ayah) => AudioSource.uri(Uri.parse(ayah.audioUrl)))
        .toList(growable: false);
    if (sources.isEmpty) {
      if (mounted) setState(() => _audioReady = false);
      return;
    }
    await _player.setAudioSource(
      ConcatenatingAudioSource(children: sources),
      initialIndex: (_currentAyah - 1).clamp(0, sources.length - 1),
    );
    await _player.setSpeed(_playbackSpeed);
    if (mounted) setState(() => _audioReady = true);
  }

  Future<void> _playAyah(int numberInSurah) async {
    final targetIndex = numberInSurah - 1;
    if (_audioReady) {
      await _player.seek(Duration.zero, index: targetIndex);
      await _player.play();
    }
    final detail = _detail;
    if (detail != null) {
      await _repository.updateRecentAyah(
        surah: detail.surah,
        ayahNumber: numberInSurah,
      );
    }
    if (mounted) setState(() => _currentAyah = numberInSurah);
  }

  Future<void> _togglePlayPause() async {
    if (!_audioReady) return;
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> _seekBy(Duration delta) async {
    final position = _player.position + delta;
    await _player.seek(position < Duration.zero ? Duration.zero : position);
  }

  Future<void> _setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    await _player.setSpeed(speed);
    if (mounted) setState(() {});
  }

  Future<void> _setLoopMode(LoopMode mode) async {
    _loopMode = mode;
    await _player.setLoopMode(mode);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    final horizontalMargin = isDesktop
        ? AppSpacing.marginDesktop
        : AppSpacing.marginMobile;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<QuranSurahDetail>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load this Surah right now.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(color: AppColors.onSurface),
                ),
              ),
            );
          }
          final detail = snapshot.data;
          if (detail == null) {
            return const Center(child: Text('Surah not available'));
          }

          if (detail.ayahs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.wifi_off_rounded,
                      size: 64,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Internet Connection',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This Surah has not been cached offline yet. Please connect to the internet to load and read it.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Button3D(
                      label: 'Retry Loading',
                      icon: Icons.refresh_rounded,
                      onTap: () {
                        setState(() {
                          _detailFuture = _loadDetail();
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          return Stack(
            children: [
              // Ambient Glow Orbs
              Positioned(
                top: -80,
                right: -60,
                child: GlowOrb(color: AppColors.primary, radius: 260, opacity: 0.12),
              ),
              Positioned(
                bottom: 120,
                left: -80,
                child: GlowOrb(color: AppColors.gold, radius: 220, opacity: 0.08),
              ),

              // Main Ayahs List
              Positioned.fill(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalMargin,
                    100,
                    horizontalMargin,
                    180,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 860),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (detail.surah.id != 9) const _Bismillah(),
                          Text(
                            detail.englishNameTranslation,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 28),
                          for (final ayah in detail.ayahs) ...[
                            _AyahCard(
                              surah: detail.surah,
                              ayah: ayah,
                              isCurrent: ayah.numberInSurah == _currentAyah,
                              onTap: () => _playAyah(ayah.numberInSurah),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 3D Glass Top Header
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _TopHeader(detail: detail, currentAyah: _currentAyah),
              ),

              // 3D Floating Audio Dock
              Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: _FloatingAudioPlayer(
                  player: _player,
                  detail: detail,
                  audioReady: _audioReady,
                  playbackSpeed: _playbackSpeed,
                  loopMode: _loopMode,
                  onPlayPause: _togglePlayPause,
                  onSeekBack: () => _seekBy(const Duration(seconds: -15)),
                  onSeekForward: () => _seekBy(const Duration(seconds: 15)),
                  onSetSpeed: _setPlaybackSpeed,
                  onSetLoopMode: _setLoopMode,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.detail, required this.currentAyah});

  final QuranSurahDetail detail;
  final int currentAyah;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppResponsive.horizontalMargin(context),
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: AppColors.background.withOpacity(0.8),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.08),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ScaleButton(
                  onTap: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      UiActions.openByLabel(context, 'Quran');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh.withOpacity(0.8),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.onSurface,
                      size: 20,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      detail.surah.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: AppColors.onBackground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'AYAH $currentAyah OF ${detail.ayahs.length}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                ScaleButton(
                  onTap: () => UiActions.openSettings(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh.withOpacity(0.8),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.onSurface,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Bismillah extends StatelessWidget {
  const _Bismillah();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.amiri(
            fontSize: 38,
            fontWeight: FontWeight.bold,
            color: AppColors.gold,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}

class _AyahCard extends StatelessWidget {
  const _AyahCard({
    required this.surah,
    required this.ayah,
    required this.isCurrent,
    required this.onTap,
  });

  final Surah surah;
  final QuranAyahDetail ayah;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return ScaleButton(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: isCurrent
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1B3225), Color(0xFF101E17)],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF14201A), Color(0xFF0E1612)],
                ),
          border: Border.all(
            color: isCurrent
                ? AppColors.primary.withOpacity(0.55)
                : Colors.white.withOpacity(0.07),
            width: isCurrent ? 1.5 : 1,
          ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    offset: const Offset(0, 6),
                    blurRadius: 14,
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 3D Ayah badge
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isCurrent
                        ? AppColors.primaryGradient
                        : null,
                    color: isCurrent ? null : AppColors.surfaceVariant.withOpacity(0.6),
                    border: Border.all(
                      color: isCurrent ? Colors.white.withOpacity(0.3) : Colors.white10,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${ayah.numberInSurah}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isCurrent ? AppColors.onPrimary : AppColors.primary,
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    ScaleButton(
                      onTap: () => UiActions.bookmarkSurah(
                        context,
                        id: surah.id,
                        name: surah.name,
                        arabic: surah.arabic,
                        verses: surah.verses,
                        place: surah.place,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.bookmark_border_rounded,
                          size: 18,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ScaleButton(
                      onTap: () => UiActions.shareText(
                        context,
                        '${surah.name} ${ayah.numberInSurah}\n${ayah.arabicText}\n${ayah.englishTranslation}',
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.share_rounded,
                          size: 18,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Arabic text
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                ayah.arabicText,
                textAlign: TextAlign.right,
                style: GoogleFonts.amiri(
                  fontSize: isDesktop ? 34 : 28,
                  height: 2.0,
                  fontWeight: FontWeight.bold,
                  color: isCurrent ? const Color(0xFFFFFFFF) : AppColors.onBackground,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // English Translation
            Container(
              padding: const EdgeInsets.only(left: 14),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: isCurrent ? AppColors.primary : AppColors.surfaceVariant,
                    width: 3,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ayah.englishTranslation,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      height: 1.6,
                      color: AppColors.onBackground,
                    ),
                  ),
                  if (ayah.banglaTranslation.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      ayah.banglaTranslation,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        height: 1.6,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingAudioPlayer extends StatelessWidget {
  const _FloatingAudioPlayer({
    required this.player,
    required this.detail,
    required this.audioReady,
    required this.playbackSpeed,
    required this.loopMode,
    required this.onPlayPause,
    required this.onSeekBack,
    required this.onSeekForward,
    required this.onSetSpeed,
    required this.onSetLoopMode,
  });

  final AudioPlayer player;
  final QuranSurahDetail detail;
  final bool audioReady;
  final double playbackSpeed;
  final LoopMode loopMode;
  final Future<void> Function() onPlayPause;
  final Future<void> Function() onSeekBack;
  final Future<void> Function() onSeekForward;
  final Future<void> Function(double speed) onSetSpeed;
  final Future<void> Function(LoopMode mode) onSetLoopMode;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 720;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.55),
                  blurRadius: 36,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.12),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1712).withOpacity(0.88),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                      width: 1,
                    ),
                  ),
                  child: StreamBuilder<PlayerState>(
                    stream: player.playerStateStream,
                    builder: (context, snapshot) {
                      final playing = snapshot.data?.playing ?? false;
                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  detail.reciterName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onBackground,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  detail.surah.name.toUpperCase(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    letterSpacing: 0.8,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Rewind 15s',
                            onPressed: audioReady ? onSeekBack : null,
                            icon: const Icon(Icons.replay_10_rounded),
                            color: AppColors.onSurfaceVariant,
                            iconSize: 22,
                          ),
                          ScaleButton(
                            onTap: audioReady ? onPlayPause : null,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.primaryGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.4),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                size: 28,
                                color: AppColors.onPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Forward 15s',
                            onPressed: audioReady ? onSeekForward : null,
                            icon: const Icon(Icons.forward_10_rounded),
                            color: AppColors.onSurfaceVariant,
                            iconSize: 22,
                          ),
                          if (isWide) ...[
                            PopupMenuButton<double>(
                              tooltip: 'Playback speed',
                              initialValue: playbackSpeed,
                              onSelected: onSetSpeed,
                              itemBuilder: (context) => const [
                                PopupMenuItem(value: 0.75, child: Text('0.75x')),
                                PopupMenuItem(value: 1.0, child: Text('1.0x (Normal)')),
                                PopupMenuItem(value: 1.25, child: Text('1.25x')),
                                PopupMenuItem(value: 1.5, child: Text('1.5x')),
                              ],
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  '${playbackSpeed.toStringAsFixed(playbackSpeed == 1 ? 1 : 2)}x',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            PopupMenuButton<LoopMode>(
                              tooltip: 'Repeat',
                              initialValue: loopMode,
                              onSelected: onSetLoopMode,
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: LoopMode.off,
                                  child: Text('Repeat off'),
                                ),
                                PopupMenuItem(
                                  value: LoopMode.one,
                                  child: Text('Repeat ayah'),
                                ),
                                PopupMenuItem(
                                  value: LoopMode.all,
                                  child: Text('Repeat surah'),
                                ),
                              ],
                              icon: Icon(
                                loopMode == LoopMode.off
                                    ? Icons.repeat_rounded
                                    : Icons.repeat_on_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
