import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:just_audio/just_audio.dart' as ja; // Aliased just_audio

class AudioPlayerHandlerImpl extends BaseAudioHandler with SeekHandler {
  final ja.AudioPlayer _player = ja.AudioPlayer();
  List<MediaItem> _queue = [];
  // Callback to notify AppState about playback progression for history
  // This is one way; another is for AppState to actively listen and decide when to save.
  // For simplicity, we'll let AppState manage history updates by observing playbackState and mediaItem.
  // Function(MediaItem mediaItem, Duration position)? onProgressUpdateForHistory;
  AudioPlayerHandlerImpl() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    _player.currentIndexStream.listen((index) {
      if (index != null && _queue.isNotEmpty && index < _queue.length) {
        mediaItem.add(_queue[index]);
      }
    });

    _player.durationStream.listen((duration) {
      final currentMediaItem = mediaItem.value;
      if (currentMediaItem != null && currentMediaItem.duration != duration) {
        final newCopy = currentMediaItem.copyWith(duration: duration);
        mediaItem.add(newCopy);
      }
    });

  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    await _player.setShuffleModeEnabled(shuffleMode != AudioServiceShuffleMode.none);
    playbackState.add(playbackState.value.copyWith(shuffleMode: shuffleMode));
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    ja.LoopMode mode = ja.LoopMode.off;
    if(repeatMode == AudioServiceRepeatMode.one) mode = ja.LoopMode.one;
    if(repeatMode == AudioServiceRepeatMode.all || repeatMode == AudioServiceRepeatMode.group) mode = ja.LoopMode.all;
    await _player.setLoopMode(mode);
    playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));
  }

  @override
  Future<void> updateQueue(List<MediaItem> newQueue) async {
    _queue = newQueue;
    queue.add(_queue);
  }

  Future<void> setQueue(List<MediaItem> newQueue) async {
    _queue = newQueue;
    queue.add(_queue);
    if (_queue.isNotEmpty) {
      final audioSources = _queue.map((item) {
        Uri? artUri;
        if (item.artUri != null && item.artUri.toString().isNotEmpty) {
          try { artUri = Uri.parse(item.artUri.toString()); } catch (e) { debugPrint("Invalid artUri for ${item.title}: ${item.artUri} - $e");}
        }
        return ja.AudioSource.uri(Uri.parse(item.id), tag: item.copyWith(artUri: artUri));
      }).toList();
      try {
        await _player.setAudioSource(ja.ConcatenatingAudioSource(children: audioSources), initialIndex: 0, preload: true);
      } catch (e) {
        debugPrint("Error setting audio source: $e");
        mediaItem.add(null);
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.error,
          playing: false,
          errorMessage: e.toString(),
          errorCode: (e is ja.PlayerException) ? e.code : null,
        ));
      }
    } else {
      await _player.stop();
      mediaItem.add(null);
    }
  }

  @override
  Future<void> addQueueItem(MediaItem item) async {
    _queue.add(item);
    queue.add(_queue);
    if (_player.audioSource is ja.ConcatenatingAudioSource) {
      Uri? artUri;
      if (item.artUri != null && item.artUri.toString().isNotEmpty) {
        try { artUri = Uri.parse(item.artUri.toString()); } catch (e) { debugPrint("Invalid artUri for ${item.title}: ${item.artUri} - $e");}
      }
      await (_player.audioSource as ja.ConcatenatingAudioSource).add(ja.AudioSource.uri(Uri.parse(item.id), tag: item.copyWith(artUri: artUri)));
    } else {
      await setQueue([item]);
    }
  }

  @override
  Future<void> play() async {
    if (_player.audioSource != null) {
      try {
        await _player.play();
      } catch (e) {
        debugPrint("Error on play: $e");
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.error,
          playing: false,
          errorMessage: e.toString(),
          errorCode: (e is ja.PlayerException) ? e.code : null,
        ));
      }
    } else if (_queue.isNotEmpty) {
      await setQueue(_queue);
      if (_player.audioSource != null && playbackState.value.processingState != AudioProcessingState.error) {
        try {
          await _player.play();
        } catch (e) {
          debugPrint("Error on play after setQueue: $e");
          playbackState.add(playbackState.value.copyWith(
            processingState: AudioProcessingState.error,
            playing: false,
            errorMessage: e.toString(),
            errorCode: (e is ja.PlayerException) ? e.code : null,
          ));
        }
      }
    }
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    // AppState will listen to playbackState change and log history if needed
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    await _player.seekToNext();
    if (playbackState.value.playing && !_player.playing) await _player.play().catchError((e) => debugPrint("Error playing next: $e"));
  }

  @override
  Future<void> skipToPrevious() async {
    await _player.seekToPrevious();
    if (playbackState.value.playing && !_player.playing) await _player.play().catchError((e) => debugPrint("Error playing previous: $e"));
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _queue.length) return;
    await _player.seek(Duration.zero, index: index);
    if (playbackState.value.playing && !_player.playing) await _player.play().catchError((e) => debugPrint("Error playing item $index: $e"));
  }

  @override
  Future<void> stop() async {
    // AppState will listen to playbackState change (going to idle/stopped) and log history
    await _player.stop();
    mediaItem.add(null);
  }

  PlaybackState _transformEvent(ja.PlaybackEvent event) {
    final audioProcessingState = const {
      ja.ProcessingState.idle: AudioProcessingState.idle,
      ja.ProcessingState.loading: AudioProcessingState.loading,
      ja.ProcessingState.buffering: AudioProcessingState.buffering,
      ja.ProcessingState.ready: AudioProcessingState.ready,
      ja.ProcessingState.completed: AudioProcessingState.completed,
    }[event.processingState] ?? AudioProcessingState.idle;

    String? effectiveErrorMessage = playbackState.value.errorMessage;
    int? effectiveErrorCode = playbackState.value.errorCode;

    if (audioProcessingState != AudioProcessingState.error) {
      effectiveErrorMessage = null;
      effectiveErrorCode = null;
    }

    // When processingState becomes completed, ensure current mediaItem & position are logged to history by AppState
    // AppState's listener for playbackState handles this.

    return PlaybackState(
      controls: [
        _player.hasPrevious ? MediaControl.skipToPrevious : MediaControl.rewind,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        _player.hasNext ? MediaControl.skipToNext : MediaControl.fastForward,
      ],
      systemActions: const {
        MediaAction.seek, MediaAction.seekForward, MediaAction.seekBackward,
        MediaAction.setShuffleMode, MediaAction.setRepeatMode,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: audioProcessingState,
      playing: _player.playing,
      updatePosition: event.updatePosition,
      bufferedPosition: event.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
      repeatMode: const {
        ja.LoopMode.off: AudioServiceRepeatMode.none,
        ja.LoopMode.one: AudioServiceRepeatMode.one,
        ja.LoopMode.all: AudioServiceRepeatMode.all,
      }[_player.loopMode] ?? AudioServiceRepeatMode.none,
      shuffleMode: _player.shuffleModeEnabled
          ? AudioServiceShuffleMode.all
          : AudioServiceShuffleMode.none,
      errorMessage: effectiveErrorMessage,
      errorCode: effectiveErrorCode,
    );
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'dispose') {
      await _player.dispose();
      super.customAction(name, extras);
    }
  }
}