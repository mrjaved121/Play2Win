import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../constants/asset_paths.dart';

/// Sound effects the game can trigger. Keeping this as an enum (rather
/// than passing raw asset strings around the app) means call sites read
/// as `audio.playSfx(SfxType.win)` and the asset mapping lives in one
/// place ([JustAudioService._sfxAsset]).
enum SfxType {
  buttonClick,
  spin,
  reelStop,
  win,
  bigWin,
  jackpot,
  coinCollect,
}

/// Abstraction over audio playback so presentation/game code never talks
/// to `just_audio` directly. Swappable for a fake in widget tests.
abstract class AudioService {
  Future<void> init();

  Future<void> playSfx(SfxType type);
  Future<void> playMusic();
  Future<void> stopMusic();
  Future<void> pauseMusic();

  bool get isMusicEnabled;
  bool get isSfxEnabled;
  void setMusicEnabled(bool enabled);
  void setSfxEnabled(bool enabled);

  Future<void> dispose();
}

/// `just_audio`-backed implementation.
///
/// Uses a small round-robin pool of [AudioPlayer]s for SFX so overlapping
/// sounds (e.g. rapid reel stops) don't cut each other off, and a
/// dedicated looping player for background music.
class JustAudioService implements AudioService {
  JustAudioService({int sfxPoolSize = 4})
      : _sfxPool = List<AudioPlayer>.generate(
          sfxPoolSize,
          (_) => AudioPlayer(),
        );

  final AudioPlayer _musicPlayer = AudioPlayer();
  final List<AudioPlayer> _sfxPool;
  int _sfxPoolIndex = 0;

  bool _musicEnabled = true;
  bool _sfxEnabled = true;
  bool _initialized = false;

  @override
  bool get isMusicEnabled => _musicEnabled;

  @override
  bool get isSfxEnabled => _sfxEnabled;

  @override
  Future<void> init() async {
    if (_initialized) return;
    await _musicPlayer.setLoopMode(LoopMode.one);
    _initialized = true;
  }

  static String _sfxAsset(SfxType type) => switch (type) {
        SfxType.buttonClick => AssetPaths.sfxButtonClick,
        SfxType.spin => AssetPaths.sfxSpin,
        SfxType.reelStop => AssetPaths.sfxReelStop,
        SfxType.win => AssetPaths.sfxWin,
        SfxType.bigWin => AssetPaths.sfxBigWin,
        SfxType.jackpot => AssetPaths.sfxJackpot,
        SfxType.coinCollect => AssetPaths.sfxCoinCollect,
      };

  @override
  Future<void> playSfx(SfxType type) async {
    if (!_sfxEnabled) return;
    final AudioPlayer player = _sfxPool[_sfxPoolIndex];
    _sfxPoolIndex = (_sfxPoolIndex + 1) % _sfxPool.length;
    try {
      await player.setAsset(_sfxAsset(type));
      await player.seek(Duration.zero);
      unawaited(player.play());
    } catch (error) {
      // SFX are non-critical; a missing/corrupt asset shouldn't crash a spin.
      debugPrint('AudioService: failed to play $type — $error');
    }
  }

  @override
  Future<void> playMusic() async {
    if (!_musicEnabled) return;
    try {
      if (_musicPlayer.audioSource == null) {
        await _musicPlayer.setAsset(AssetPaths.musicBackground);
      }
      await _musicPlayer.play();
    } catch (error) {
      debugPrint('AudioService: failed to play background music — $error');
    }
  }

  @override
  Future<void> stopMusic() => _musicPlayer.stop();

  @override
  Future<void> pauseMusic() => _musicPlayer.pause();

  @override
  void setMusicEnabled(bool enabled) {
    _musicEnabled = enabled;
    if (!enabled) {
      unawaited(pauseMusic());
    } else {
      unawaited(playMusic());
    }
  }

  @override
  void setSfxEnabled(bool enabled) => _sfxEnabled = enabled;

  @override
  Future<void> dispose() async {
    await _musicPlayer.dispose();
    for (final AudioPlayer player in _sfxPool) {
      await player.dispose();
    }
  }
}
