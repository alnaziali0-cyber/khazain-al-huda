import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:khazain_al_huda/core/audio_playback_service.dart';
import 'package:khazain_al_huda/features/radio/audio_library_screen.dart';

class _FakePlayback implements AppAudioPlayback {
  @override
  Stream<PlaybackState> get playbackStateStream => const Stream<PlaybackState>.empty();

  @override
  bool get isPlaying => false;

  @override
  Future<void> pause() async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> playLocal({
    required String path,
    required String id,
    required String title,
    String artist = 'خزائن الهدى',
    String album = 'القرآن الكريم',
  }) async {}

  @override
  Future<void> playRemote({
    required Uri uri,
    required String id,
    required String title,
    String artist = 'خزائن الهدى',
    String album = 'المكتبة الصوتية',
  }) async {}

  @override
  Future<void> setLoopMode(LoopMode mode) async {}

  @override
  Future<void> stop() async {}
}

Widget _testApp(Widget child) => ProviderScope(
      overrides: [appAudioPlaybackProvider.overrideWithValue(_FakePlayback())],
      child: MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  testWidgets('shows empty licensed catalogue state', (tester) async {
    await tester.pumpWidget(_testApp(
      AudioLibraryScreen(loadTracks: () async => []),
    ));
    await tester.pumpAndSettle();
    expect(find.text('المكتبة الصوتية'), findsOneWidget);
    expect(find.textContaining('ستظهر هنا فقط الملفات'), findsOneWidget);
    expect(find.textContaining('https://'), findsNothing);
  });

  testWidgets('shows only published tracks returned by the public catalogue',
      (tester) async {
    await tester.pumpWidget(_testApp(AudioLibraryScreen(loadTracks: () async => [
      {
        'id': 7,
        'title': 'أذان تجريبي مرخص',
        'category': 'adhan',
        'source_url': 'https://example.org/audio.mp3',
        'can_download': false,
      }
    ])));
    await tester.pumpAndSettle();
    expect(find.text('أذان تجريبي مرخص'), findsOneWidget);
    expect(find.text('adhan'), findsOneWidget);
    expect(find.byTooltip('تنزيل مرخص'), findsNothing);
  });
}
