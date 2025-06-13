import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

class play_video_bedtime_screen extends StatefulWidget {
  final String title;
  final String url;
  final int week;
  final int day;

  const play_video_bedtime_screen({
    Key? key,
    required this.title,
    required this.url,
    required this.week,
    required this.day,
  }) : super(key: key);

  @override
  _play_video_bedtime_screen createState() => _play_video_bedtime_screen();
}

class _play_video_bedtime_screen extends State<play_video_bedtime_screen> {
  final AudioPlayer _player = AudioPlayer();
  late Stream<DurationState> _durationState;
  DateTime? _sessionStart;
  late Duration _audioDuration;
  bool _loading = true;
  String? _userId;
  final DateFormat _formatter = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _initAudio();
  }

  Future<void> _initAudio() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id') ?? '';

    await _player.setAsset(widget.url);
    _audioDuration = _player.duration ?? Duration.zero;

    _durationState =
        Rx.combineLatest2<Duration, PlaybackEvent, DurationState>(
          _player.positionStream,
          _player.playbackEventStream,
              (pos, evt) => DurationState(
            progress: pos,
            buffered: evt.bufferedPosition,
            total: evt.duration,
          ),
        );

    _player.playingStream.listen((isPlaying) {
      if (isPlaying) {
        _sessionStart ??= DateTime.now();
      } else if (_sessionStart != null) {
        _recordSession(_sessionStart!, DateTime.now());
        _sessionStart = null;
      }
    });

    setState(() => _loading = false);
  }

  Future<void> _recordSession(DateTime start, DateTime end) async {
    final rawSec = end.difference(start).inSeconds;
    final maxSec = _audioDuration.inSeconds + 10;
    final listened = rawSec.clamp(0, maxSec);
    final dayKey = _formatter.format(start);
    final docId = '$_userId\_$dayKey';
    final docRef = FirebaseFirestore.instance
        .collection('listeningStats')
        .doc(docId);

    await docRef.set({
      'userId': _userId,
      'date':   dayKey,
    }, SetOptions(merge: true));

    // now increment bedtimeSec instead of generic durationSec
    await docRef.update({
      'bedtimeSec': FieldValue.increment(listened),
    });
  }

  @override
  void dispose() {
    if (_sessionStart != null) {
      _recordSession(_sessionStart!, DateTime.now());
    }
    _player.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    _player.stop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F4F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF6F4F5),
          title: Text(
            widget.title,
            style: const TextStyle(
              fontFamily: 'WorkSans',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
            ),
          ),
          elevation: 0,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Transform.translate(
                    offset: const Offset(0, -8),
                    child: StreamBuilder<PlayerState>(
                      stream: _player.playerStateStream,
                      builder: (ctx, snap) {
                        final ps = snap.data;
                        final processing = ps?.processingState;
                        final playing = ps?.playing;
                        if (processing == ProcessingState.loading ||
                            processing == ProcessingState.buffering) {
                          return const CircularProgressIndicator();
                        } else if (playing != true) {
                          return IconButton(
                            icon: const Icon(Icons.play_arrow, size: 48),
                            onPressed: () => _player.play(),
                          );
                        } else if (processing != ProcessingState.completed) {
                          return IconButton(
                            icon: const Icon(Icons.pause, size: 48),
                            onPressed: () => _player.pause(),
                          );
                        } else {
                          return IconButton(
                            icon: const Icon(Icons.replay, size: 48),
                            onPressed: () => _player.seek(Duration.zero),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StreamBuilder<DurationState>(
                      stream: _durationState,
                      builder: (ctx, snap) {
                        final state = snap.data;
                        return ProgressBar(
                          progress: state?.progress ?? Duration.zero,
                          buffered: state?.buffered ?? Duration.zero,
                          total:    state?.total    ?? Duration.zero,
                          onSeek:   (pos) => _player.seek(pos),
                          baseBarColor:     const Color(0xFFE0E0E0),
                          bufferedBarColor: const Color(0xFFE0E0E0),
                          progressBarColor: const Color(0xFF0F75BC),
                          thumbColor:       const Color(0xFF0F75BC),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Letting go of the stresses and strains of the day is vital to restful sleep. This practice also involves a gentle affirmation to become a better version of yourself. Connecting to the depths of your heart just before falling asleep helps you wake up refreshed in the morning. For best results, please be consistent with your daily practice. Have a good night’s sleep!',
                style: TextStyle(
                  fontFamily: 'WorkSans',
                  fontSize: 17,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DurationState {
  final Duration progress;
  final Duration buffered;
  final Duration? total;
  const DurationState({
    required this.progress,
    required this.buffered,
    required this.total,
  });
}