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



class QuranReaderApp extends StatelessWidget {
  const QuranReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: QuranReaderScreen(surahId: 1),
    );
  }
}

class QuranReaderScreen extends StatefulWidget {
  const QuranReaderScreen({super.key, required this.surahId});

  final int surahId;

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
      if (!mounted || detail == null || index == null) {
        return;
      }
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
      if (mounted) {
        setState(() => _audioReady = false);
      }
      return;
    }
    await _player.setAudioSource(
      ConcatenatingAudioSource(children: sources),
      initialIndex: (_currentAyah - 1).clamp(0, sources.length - 1),
    );
    await _player.setSpeed(_playbackSpeed);
    if (mounted) {
      setState(() => _audioReady = true);
    }
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
    if (mounted) {
      setState(() => _currentAyah = numberInSurah);
    }
  }

  Future<void> _togglePlayPause() async {
    if (!_audioReady) {
      return;
    }
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
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _setLoopMode(LoopMode mode) async {
    _loopMode = mode;
    await _player.setLoopMode(mode);
    if (mounted) {
      setState(() {});
    }
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
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load this Surah right now.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final detail = snapshot.data;
          if (detail == null) {
            return const Center(child: Text('Surah not available'));
          }

          return Stack(
            children: [
              Positioned.fill(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalMargin,
                    96,
                    horizontalMargin,
                    170,
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
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          for (final ayah in detail.ayahs) ...[
                            _AyahCard(
                              surah: detail.surah,
                              ayah: ayah,
                              isCurrent: ayah.numberInSurah == _currentAyah,
                              onTap: () => _playAyah(ayah.numberInSurah),
                            ),
                            if (ayah.numberInSurah !=
                                detail.ayahs.last.numberInSurah)
                              const SizedBox(height: AppSpacing.lg),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _TopHeader(detail: detail, currentAyah: _currentAyah),
              ),
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

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.blurSigma = 24,
    this.tint = const Color(0x990E1511),
    this.borderRadius,
    this.border,
    this.boxShadow,
  });

  final Widget child;
  final double blurSigma;
  final Color tint;
  final BorderRadius? borderRadius;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: tint,
            borderRadius: borderRadius,
            border:
                border ??
                Border.all(color: Colors.white.withOpacity(0.1), width: 1),
            boxShadow: boxShadow,
          ),
          child: child,
        ),
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
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    final horizontalMargin = isDesktop
        ? AppSpacing.marginDesktop
        : AppSpacing.marginMobile;

    return GlassSurface(
      blurSigma: 24,
      tint: AppColors.surface.withOpacity(0.6),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalMargin,
            vertical: 16,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _IconCircleButton(
                    icon: Icons.arrow_back,
                    tooltip: 'Go Back',
                    onTap: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        UiActions.openByLabel(context, 'Quran');
                      }
                    },
                  ),
                  Column(
                    children: [
                      Text(
                        detail.surah.name,
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'AYAH $currentAyah OF ${detail.ayahs.length}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          letterSpacing: 0.65,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  _IconCircleButton(
                    icon: Icons.tune,
                    tooltip: 'Settings',
                    onTap: () => UiActions.openSettings(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconCircleButton extends StatelessWidget {
  const _IconCircleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: AppColors.onSurfaceVariant, size: 22),
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Text(
        'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيم',
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: GoogleFonts.libreCaslonText(
          fontSize: 40,
          height: 1.5,
          color: AppColors.onSurface,
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
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isCurrent
                ? AppColors.surfaceVariant.withOpacity(0.35)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrent
                  ? AppColors.primary.withOpacity(0.4)
                  : Colors.white.withOpacity(0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _VerseBadge(number: '${ayah.numberInSurah}'),
                  Row(
                    children: [
                      _MiniIconButton(
                        icon: Icons.bookmark_border,
                        onTap: () => UiActions.bookmarkSurah(
                          context,
                          id: surah.id,
                          name: surah.name,
                          arabic: surah.arabic,
                          verses: surah.verses,
                          place: surah.place,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _MiniIconButton(
                        icon: Icons.share,
                        onTap: () => UiActions.shareText(
                          context,
                          '${surah.name} ${ayah.numberInSurah}\n${ayah.arabicText}\n${ayah.englishTranslation}',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  ayah.arabicText,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.libreCaslonText(
                    fontSize: isDesktop ? 34 : 30,
                    height: 1.8,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.only(left: 16),
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: AppColors.surfaceVariant, width: 2),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ayah.englishTranslation,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          height: 1.55,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        ayah.banglaTranslation,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          height: 1.6,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
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

class _VerseBadge extends StatelessWidget {
  const _VerseBadge({required this.number});

  final String number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Text(
        number,
        style: GoogleFonts.inter(fontSize: 16, color: AppColors.primary),
      ),
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  const _MiniIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
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
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.marginMobile,
          ),
          child: GlassSurface(
            blurSigma: 40,
            tint: AppColors.surface.withOpacity(0.8),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: StreamBuilder<PlayerState>(
                stream: player.playerStateStream,
                builder: (context, snapshot) {
                  final playing = snapshot.data?.playing ?? false;
                  return Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              detail.reciterName,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.65,
                                color: AppColors.onSurface,
                              ),
                            ),
                            Text(
                              detail.surah.name.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                letterSpacing: 1,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Back 15s',
                        onPressed: audioReady ? onSeekBack : null,
                        icon: const Icon(Icons.replay_10),
                        color: AppColors.onSurfaceVariant,
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                        child: IconButton(
                          tooltip: playing ? 'Pause' : 'Play',
                          onPressed: audioReady ? onPlayPause : null,
                          icon: Icon(
                            playing ? Icons.pause : Icons.play_arrow,
                            size: 28,
                          ),
                          color: AppColors.onPrimary,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Forward 15s',
                        onPressed: audioReady ? onSeekForward : null,
                        icon: const Icon(Icons.forward_10),
                        color: AppColors.onSurfaceVariant,
                      ),
                      if (isWide) ...[
                        PopupMenuButton<double>(
                          tooltip: 'Playback speed',
                          initialValue: playbackSpeed,
                          onSelected: onSetSpeed,
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 0.75, child: Text('0.75x')),
                            PopupMenuItem(value: 1.0, child: Text('1.0x')),
                            PopupMenuItem(value: 1.25, child: Text('1.25x')),
                            PopupMenuItem(value: 1.5, child: Text('1.5x')),
                          ],
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '${playbackSpeed.toStringAsFixed(playbackSpeed == 1 ? 1 : 2)}x',
                              style: GoogleFonts.inter(
                                color: AppColors.onSurfaceVariant,
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
                                ? Icons.repeat
                                : Icons.repeat_on,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ] else
                        const SizedBox(width: 8),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
