import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:just_audio/just_audio.dart' as ja;

// see: https://github.com/ryanheise/just_audio/blob/minor/just_audio/example/lib/example_playlist.dart

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}

class AudioPlayerHandlerImpl extends BaseAudioHandler with SeekHandler {
  final ja.AudioPlayer _player = ja.AudioPlayer();
  List<MediaItem> _queue = [];

  bool _isPlaying = false;
  ja.ProcessingState _processingState = ja.ProcessingState.idle;
  Duration _position = Duration.zero;
  Duration _bufferedPosition = Duration.zero;
  Duration? _currentTrackDuration;
  int? _currentIndexInPlayer;

  final List<StreamSubscription> _handlerSubscriptions = []; // To manage subscriptions

  AudioPlayerHandlerImpl() {
    _handlerSubscriptions.addAll([
      _player.playerStateStream.listen((state) {
        _isPlaying = state.playing;
        _processingState = state.processingState;
        _broadcastState();
      }),
      _player.positionStream.listen((pos) {
        _position = pos;
        _broadcastState();
      }),
      _player.bufferedPositionStream.listen((pos) {
        _bufferedPosition = pos;
        _broadcastState();
      }),
      _player.durationStream.listen((dur) {
        _currentTrackDuration = dur;
        // Potentially update MediaItem duration here too
        final currentMediaItem = mediaItem.value;
        if (currentMediaItem != null && currentMediaItem.duration != dur) {
          mediaItem.add(currentMediaItem.copyWith(duration: dur));
        }
        _broadcastState();
      }),
      _player.currentIndexStream.listen((index) {
        _currentIndexInPlayer = index;
        if (index != null && index < _queue.length) {
          mediaItem.add(_queue[index]);
        } else {
          mediaItem.add(null);
        }
        // When index changes, reset position for the new track and update duration
        _position = Duration.zero; // just_audio might do this, but good to be explicit
        _currentTrackDuration = mediaItem.value?.duration; // Get duration from new MediaItem
        _broadcastState();
      }),
      // Add listeners for _player.loopModeStream and _player.shuffleModeEnabledStream
      // if you want them to also trigger _broadcastState.
    ]);
  }

  void _broadcastState() {
    playbackState.add(PlaybackState(
      controls: [ /* Your control logic based on _player.hasNext etc. */ ],
      systemActions: { /* Your system actions */ },
      androidCompactActionIndices: const [0, 1, 3], // Example
      processingState: _mapJustAudioProcessingState(_processingState),
      playing: _isPlaying,
      updatePosition: _position, // From _player.positionStream
      bufferedPosition: _bufferedPosition,
      speed: _player.speed, // _player.speed is a property, not a stream here
      queueIndex: _currentIndexInPlayer,
      repeatMode: _mapJustAudioLoopModeToAudioService(_player.loopMode),
      shuffleMode: _player.shuffleModeEnabled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
      // errorMessage and errorCode need to be set from try/catch blocks in your action methods
    ));
  }

  AudioProcessingState _mapJustAudioProcessingState(ja.ProcessingState processingState) {
    switch (processingState) {
      case ja.ProcessingState.idle:
        return AudioProcessingState.idle;
      case ja.ProcessingState.loading:
        return AudioProcessingState.loading;
      case ja.ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ja.ProcessingState.ready:
        return AudioProcessingState.ready;
      case ja.ProcessingState.completed:
        return AudioProcessingState.completed;
      default:
      // This case should ideally not be reached if all just_audio states are handled.
      // You might want to log an unexpected state or default to idle/error.
        debugPrint("Unknown just_audio ProcessingState: $processingState");
        return AudioProcessingState.idle; // Or AudioProcessingState.error
    }
  }

// You would also need a similar mapping for LoopMode if you haven't defined it yet:
  AudioServiceRepeatMode _mapJustAudioLoopModeToAudioService(ja.LoopMode loopMode) {
    switch (loopMode) {
      case ja.LoopMode.off:
        return AudioServiceRepeatMode.none;
      case ja.LoopMode.one:
        return AudioServiceRepeatMode.one;
      case ja.LoopMode.all:
        return AudioServiceRepeatMode.all;
      default:
        return AudioServiceRepeatMode.none;
    }
  }

// And the inverse for setting it on the player:
  ja.LoopMode _mapAudioServiceRepeatModeToJustAudio(AudioServiceRepeatMode repeatMode) {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        return ja.LoopMode.off;
      case AudioServiceRepeatMode.one:
        return ja.LoopMode.one;
      case AudioServiceRepeatMode.all:
        return ja.LoopMode.all;
      case AudioServiceRepeatMode.group: // just_audio doesn't have a direct 'group' equivalent
        return ja.LoopMode.all; // Map 'group' to 'all' or 'off' based on desired behavior
      default:
        return ja.LoopMode.off;
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    await _player.setShuffleModeEnabled(shuffleMode != AudioServiceShuffleMode.none);
    playbackState.add(playbackState.value.copyWith(shuffleMode: shuffleMode));
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    ja.LoopMode mode = ja.LoopMode.off;
    if (repeatMode == AudioServiceRepeatMode.one) mode = ja.LoopMode.one;
    if (repeatMode == AudioServiceRepeatMode.all || repeatMode == AudioServiceRepeatMode.group) mode = ja.LoopMode.all;
    await _player.setLoopMode(mode);
    playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));
  }

  @override
  Future<void> updateQueue(List<MediaItem> newQueue) async {
    _queue = newQueue;
    queue.add(_queue); // Broadcast the updated queue
  }

  Future<void> setQueue(List<MediaItem> newQueue) async {
    _queue = newQueue;
    queue.add(_queue); // Broadcast the new queue

    if (_queue.isNotEmpty) {
      final audioSources = _queue.map((item) {
        Uri? artUri;
        if (item.artUri != null && item.artUri.toString().isNotEmpty) {
          try {
            artUri = Uri.parse(item.artUri.toString());
          } catch (e) {
            debugPrint("Invalid artUri for ${item.title}: ${item.artUri} - $e");
          }
        }
        // Ensure item.id is a valid URI string for ja.AudioSource.uri
        return ja.AudioSource.uri(Uri.parse(item.id), tag: item.copyWith(artUri: artUri));
      }).toList();

      try {
        await _player.setAudioSource(ja.ConcatenatingAudioSource(children: audioSources), initialIndex: 0, preload: true);
      } catch (e) {
        debugPrint("Error setting audio source: $e");
        mediaItem.add(null); // Clear current media item on error
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.error,
          playing: false,
          errorMessage: e.toString(),
          errorCode: (e is ja.PlayerException) ? e.code : null,
        ));
      }
    } else {
      await _player.stop(); // Stop player if queue is empty
      mediaItem.add(null);  // Clear current media item
    }
  }

  @override
  Future<void> addQueueItem(MediaItem item) async {
    _queue.add(item);
    queue.add(_queue); // Broadcast updated queue

    if (_player.audioSource is ja.ConcatenatingAudioSource) {
      Uri? artUri;
      if (item.artUri != null && item.artUri.toString().isNotEmpty) {
        try {
          artUri = Uri.parse(item.artUri.toString());
        } catch (e) {
          debugPrint("Invalid artUri for ${item.title}: ${item.artUri} - $e");
        }
      }
      await (_player.audioSource as ja.ConcatenatingAudioSource).add(ja.AudioSource.uri(Uri.parse(item.id), tag: item.copyWith(artUri: artUri)));
    } else {
      // If no existing source or not a concatenating one, set a new queue with this item.
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
          playing: false, // Ensure playing is false on error
          errorMessage: e.toString(),
          errorCode: (e is ja.PlayerException) ? e.code : null,
        ));
      }
    } else if (_queue.isNotEmpty) {
      // If no audio source but queue exists, try to set it and then play.
      await setQueue(_queue); // This will set the audio source
      // Check if setting the source was successful before playing
      if (_player.audioSource != null && playbackState.value.processingState != AudioProcessingState.error) {
        try {
          await _player.play();
        } catch (e) {
          debugPrint("Error on play after setQueue: $e");
          playbackState.add(playbackState.value.copyWith(
            processingState: AudioProcessingState.error,
            playing: false, // Ensure playing is false on error
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
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    await _player.seekToNext();
    // Optional Enhancement: If _player.play() fails here, consider updating playbackState to an error.
    if (playbackState.value.playing && !_player.playing) {
      await _player.play().catchError((e) {
        debugPrint("Error playing next: $e");
        // Example: playbackState.add(playbackState.value.copyWith(processingState: AudioProcessingState.error, errorMessage: e.toString()));
      });
    }
  }

  @override
  Future<void> skipToPrevious() async {
    await _player.seekToPrevious();
    // Optional Enhancement: If _player.play() fails here, consider updating playbackState to an error.
    if (playbackState.value.playing && !_player.playing) {
      await _player.play().catchError((e) {
        debugPrint("Error playing previous: $e");
        // Example: playbackState.add(playbackState.value.copyWith(processingState: AudioProcessingState.error, errorMessage: e.toString()));
      });
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _queue.length) return;
    await _player.seek(Duration.zero, index: index);
    // Optional Enhancement: If _player.play() fails here, consider updating playbackState to an error.
    if (playbackState.value.playing && !_player.playing) {
      await _player.play().catchError((e) {
        debugPrint("Error playing item $index: $e");
        // Example: playbackState.add(playbackState.value.copyWith(processingState: AudioProcessingState.error, errorMessage: e.toString()));
      });
    }
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    mediaItem.add(null);
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'dispose') {
      await _player.dispose();
    }
  }
}