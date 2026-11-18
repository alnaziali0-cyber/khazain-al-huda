import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/audio_playback_service.dart';
import '../../core/providers.dart';

typedef AudioTrackLoader = Future<List<Map<String, dynamic>>> Function();

class AudioLibraryScreen extends ConsumerStatefulWidget {
  const AudioLibraryScreen({super.key, this.loadTracks, this.playback});

  final AudioTrackLoader? loadTracks;
  final AppAudioPlayback? playback;

  @override
  ConsumerState<AudioLibraryScreen> createState() => _AudioLibraryScreenState();
}

class _AudioLibraryScreenState extends ConsumerState<AudioLibraryScreen> {
  static const _categories = <({String id, String title, IconData icon})>[
    (id: 'all', title: 'الكل', icon: Icons.library_music_rounded),
    (id: 'quran', title: 'القرآن', icon: Icons.menu_book_rounded),
    (id: 'adhan', title: 'الأذان', icon: Icons.mosque_rounded),
    (id: 'hussainiyat', title: 'الحسينيات', icon: Icons.flag_rounded),
    (id: 'duas', title: 'الأدعية', icon: Icons.volunteer_activism_rounded),
    (id: 'ziyara', title: 'الزيارات', icon: Icons.location_on_rounded),
    (id: 'lectures', title: 'المجالس والمحاضرات', icon: Icons.record_voice_over_rounded),
    (id: 'radio', title: 'الإذاعات', icon: Icons.radio_rounded),
  ];

  late Future<List<Map<String, dynamic>>> _tracks;
  late Future<List<Map<String, dynamic>>> _quranSurahs;
  late final AppAudioPlayback _playback;
  StreamSubscription<PlaybackState>? _playerSubscription;
  String _selectedCategory = 'all';
  int? _playingId;
  bool _isPlaying = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _tracks = _loadTracks();
    _quranSurahs = _loadQuranSurahs();
    _playback = widget.playback ?? ref.read(appAudioPlaybackProvider);
    _playerSubscription = _playback.playbackStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state.playing;
        if (state.processingState == AudioProcessingState.completed) {
          _playingId = null;
          _isPlaying = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _playerSubscription?.cancel();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadQuranSurahs() async {
    final raw = await rootBundle.loadString('assets/data/quran/audio_surahs_manifest.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final items = decoded['items'];
    if (items is! List) return const [];
    return items.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }

  Future<List<Map<String, dynamic>>> _loadTracks() async {
    if (widget.loadTracks != null) return widget.loadTracks!();
    final response = await ref.read(apiProvider).get<Map<String, dynamic>>(
          '/api/v1/public/catalog/audio',
          queryParameters: {'limit': 100, 'offset': 0},
        );
    final raw = response.data?['items'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }

  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> tracks) {
    if (_selectedCategory == 'all') return tracks;
    return tracks.where((track) => _normaliseCategory(track['category']) == _selectedCategory).toList();
  }

  String _normaliseCategory(Object? value) {
    final category = (value ?? '').toString().toLowerCase().trim();
    if (['quran', 'quran_recitation', 'tilawa'].contains(category)) return 'quran';
    if (['adhan', 'azan'].contains(category)) return 'adhan';
    if (['hussainiyat', 'latmiyat', 'nohay', 'qasida', 'mourning'].contains(category)) return 'hussainiyat';
    if (['dua', 'duas', 'munajat'].contains(category)) return 'duas';
    if (['ziyara', 'ziyarat', 'visit'].contains(category)) return 'ziyara';
    if (['lecture', 'lectures', 'majlis', 'majalis'].contains(category)) return 'lectures';
    if (category == 'radio') return 'radio';
    return category;
  }

  Future<void> _play(Map<String, dynamic> track) async {
    final id = track['id'] as int?;
    final url = track['source_url'] as String?;
    if (id == null || url == null || Uri.tryParse(url)?.scheme != 'https') return;
    try {
      if (_playingId == id) {
        if (_playback.isPlaying) {
          await _playback.pause();
        } else {
          await _playback.play();
        }
        return;
      }
      final title = (track['title'] ?? 'تسجيل صوتي').toString();
      await _playback.playRemote(
        uri: Uri.parse(url),
        id: id.toString(),
        title: title,
        artist: (track['reciter'] ?? 'خزائن الهدى').toString(),
        album: 'المكتبة الصوتية',
      );
      if (!mounted) return;
      setState(() => _playingId = id);
    } catch (_) {
      _message('تعذر تشغيل التسجيل. تحقق من الاتصال ومصدر الصوت.');
    }
  }

  Future<void> _download(Map<String, dynamic> track) async {
    final id = track['id'] as int?;
    final url = track['download_url'] as String?;
    if (id == null || track['can_download'] != true || url == null || Uri.tryParse(url)?.scheme != 'https') {
      _message('هذا التسجيل غير مرخص للتنزيل.');
      return;
    }
    try {
      final directory = await getApplicationDocumentsDirectory();
      final audioDirectory = Directory('${directory.path}/licensed_audio');
      await audioDirectory.create(recursive: true);
      final extension = _extensionFor(track['mime_type']?.toString());
      final file = File('${audioDirectory.path}/track_$id$extension');
      await ref.read(apiProvider).download(url, file.path,
          options: Options(receiveTimeout: const Duration(minutes: 5)));
      if (!mounted) return;
      _message('تم تنزيل التسجيل المصرح به للاستماع دون اتصال.');
    } catch (_) {
      _message('تعذر تنزيل التسجيل حالياً.');
    }
  }

  String _extensionFor(String? mime) => switch (mime) {
        'audio/mp4' => '.m4a',
        'audio/aac' => '.aac',
        'audio/ogg' => '.ogg',
        'audio/wav' => '.wav',
        'audio/flac' => '.flac',
        _ => '.mp3',
      };

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _tracks,
      builder: (context, snapshot) {
        final allTracks = snapshot.data ?? const <Map<String, dynamic>>[];
        final visibleTracks = _filter(allTracks);
        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
            child: Row(children: [
              Icon(Icons.headphones_rounded, color: theme.colorScheme.primary, size: 30),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('المكتبة الصوتية', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                Text('تسجيلات منشورة بعد التحقق من حقوقها', style: theme.textTheme.bodySmall),
              ])),
              IconButton(onPressed: () => setState(() => _tracks = _loadTracks()), icon: const Icon(Icons.refresh_rounded), tooltip: 'تحديث'),
            ]),
          ),
          SizedBox(height: 48, child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = _categories[index];
              final selected = _selectedCategory == category.id;
              return ChoiceChip(
                selected: selected,
                avatar: Icon(category.icon, size: 17),
                label: Text(category.title),
                onSelected: (_) => setState(() => _selectedCategory = category.id),
              );
            },
          )),
          const SizedBox(height: 8),
          Expanded(child: Builder(builder: (context) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return _empty('تعذر الاتصال بمكتبة الصوتيات. تحقق من إعداد API_BASE_URL ثم أعد المحاولة.');
            if (visibleTracks.isEmpty && _selectedCategory == 'quran') {
              return _buildQuranSurahIndex();
            }
            if (visibleTracks.isEmpty) {
              final categoryTitle = _categories.firstWhere((item) => item.id == _selectedCategory).title;
              return _empty(_selectedCategory == 'all'
                  ? 'المكتبة جاهزة لاستقبال التسجيلات. ستظهر هنا فقط الملفات التي وثّق المشرف حقوق بثها.'
                  : 'لا توجد تسجيلات منشورة ومرخصة في قسم $categoryTitle حالياً.');
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
              itemCount: visibleTracks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 7),
              itemBuilder: (context, index) {
                final track = visibleTracks[index];
                final id = track['id'] as int?;
                final playing = id != null && id == _playingId && _isPlaying;
                final canDownload = track['can_download'] == true && track['download_url'] is String;
                return Card(child: ListTile(
                  leading: CircleAvatar(child: Icon(playing ? Icons.graphic_eq_rounded : Icons.music_note_rounded)),
                  title: Text((track['title'] ?? 'تسجيل صوتي').toString(), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text([
                    if ((track['reciter'] ?? '').toString().isNotEmpty) track['reciter'].toString(),
                    if ((track['category'] ?? '').toString().isNotEmpty) track['category'].toString(),
                    if (track['duration_seconds'] is int) _duration(track['duration_seconds'] as int),
                  ].join(' · ')),
                  trailing: Wrap(spacing: 0, children: [
                    IconButton(tooltip: playing ? 'إيقاف مؤقت' : 'تشغيل', onPressed: () => _play(track), icon: Icon(playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded, size: 30)),
                    if (canDownload) IconButton(tooltip: 'تنزيل مرخص', onPressed: () => _download(track), icon: const Icon(Icons.download_rounded)),
                  ]),
                ));
              },
            );
          })),
          if (_playingId != null)
            SafeArea(top: false, child: Material(color: theme.colorScheme.surfaceContainerHighest, child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                const Icon(Icons.equalizer_rounded),
                const SizedBox(width: 10),
                const Expanded(child: Text('يُشغّل الآن', style: TextStyle(fontWeight: FontWeight.w700))),
                IconButton(onPressed: () => _isPlaying ? _playback.pause() : _playback.play(), icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded)),
                IconButton(onPressed: () async { await _playback.stop(); if (mounted) setState(() => _playingId = null); }, icon: const Icon(Icons.close_rounded)),
              ]),
            )))
        ]);
      },
    );
  }

  Widget _buildQuranSurahIndex() => FutureBuilder<List<Map<String, dynamic>>>(
        future: _quranSurahs,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return _empty('تعذر تحميل فهرس السور.');
          }
          final surahs = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
            itemCount: surahs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 5),
            itemBuilder: (context, index) {
              final surah = surahs[index];
              final number = surah['number'];
              final name = (surah['name_ar'] ?? '').toString();
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('$number')),
                  title: Text('سورة $name', style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('${surah['ayah_count']} آية · التلاوة بانتظار تسجيل مرخص'),
                  trailing: const Icon(Icons.lock_clock_outlined),
                ),
              );
            },
          );
        },
      );

  Widget _empty(String message) => Center(child: Padding(
    padding: const EdgeInsets.all(28),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.library_music_outlined, size: 46),
      const SizedBox(height: 14),
      Text(message, textAlign: TextAlign.center, style: const TextStyle(height: 1.6)),
    ]),
  ));

  String _duration(int seconds) => '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}
