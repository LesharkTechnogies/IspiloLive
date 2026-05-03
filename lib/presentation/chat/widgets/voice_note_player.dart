import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

class VoiceNotePlayer extends StatefulWidget {
  final String mediaPath;
  final int? durationMs;
  final bool isSentByMe;
  final ColorScheme colorScheme;
  final Color contentColor;

  const VoiceNotePlayer({
    super.key,
    required this.mediaPath,
    this.durationMs,
    required this.isSentByMe,
    required this.colorScheme,
    required this.contentColor,
  });

  @override
  State<VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<VoiceNotePlayer> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isDownloaded = false;
  String? _localPath;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudio();

    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          if (state.processingState == ProcessingState.completed) {
            _isPlaying = false;
            _audioPlayer.seek(Duration.zero);
            _audioPlayer.pause();
          }
        });
      }
    });

    _audioPlayer.positionStream.listen((pos) {
      if (mounted) {
        setState(() {
          _position = pos;
        });
      }
    });

    _audioPlayer.durationStream.listen((dur) {
      if (mounted && dur != null) {
        setState(() {
          _duration = dur;
        });
      }
    });
  }

  Future<void> _initAudio() async {
    final isRemote = widget.mediaPath.startsWith('http');
    
    if (!isRemote) {
      _isDownloaded = true;
      _localPath = widget.mediaPath;
      if (File(_localPath!).existsSync()) {
        try {
          await _audioPlayer.setFilePath(_localPath!);
        } catch (e) {
          debugPrint('Error setting local audio file: $e');
        }
      }
    } else {
      // Check if we have it locally already
      final docsDir = await getApplicationDocumentsDirectory();
      final fileName = widget.mediaPath.split('/').last.split('?').first;
      final targetPath = '${docsDir.path}/$fileName';
      
      if (File(targetPath).existsSync()) {
        _isDownloaded = true;
        _localPath = targetPath;
        try {
          await _audioPlayer.setFilePath(_localPath!);
        } catch (e) {
          debugPrint('Error setting cached audio file: $e');
        }
      } else {
        _isDownloaded = false;
        try {
          await _audioPlayer.setUrl(widget.mediaPath);
        } catch (e) {
          debugPrint('Error setting remote audio url: $e');
        }
      }
    }
    
    if (mounted) setState(() {});
  }

  Future<void> _downloadAudio() async {
    if (_isDownloaded) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final fileName = widget.mediaPath.split('/').last.split('?').first;
      final targetPath = '${docsDir.path}/$fileName';
      
      await Dio().download(widget.mediaPath, targetPath);
      
      if (mounted) {
        setState(() {
          _isDownloaded = true;
          _localPath = targetPath;
          _isLoading = false;
        });
        await _audioPlayer.setFilePath(_localPath!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio downloaded successfully')),
        );
      }
    } catch (e) {
      debugPrint('Error downloading audio: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to download audio')),
        );
      }
    }
  }

  void _togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    if (d.inHours > 0) {
      return "${d.inHours}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final displayDuration = _duration.inMilliseconds > 0 
        ? _duration 
        : Duration(milliseconds: widget.durationMs ?? 0);
        
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _togglePlay,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: widget.contentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: widget.contentColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 2.0,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                  activeTrackColor: widget.contentColor,
                  inactiveTrackColor: widget.contentColor.withValues(alpha: 0.3),
                  thumbColor: widget.contentColor,
                ),
                child: Slider(
                  min: 0.0,
                  max: _duration.inMilliseconds > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
                  value: _position.inMilliseconds.toDouble().clamp(0.0, _duration.inMilliseconds > 0 ? _duration.inMilliseconds.toDouble() : 1.0),
                  onChanged: (value) {
                    _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: widget.contentColor.withValues(alpha: 0.8),
                      ),
                    ),
                    Text(
                      _formatDuration(displayDuration),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: widget.contentColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!_isDownloaded && widget.mediaPath.startsWith('http'))
          IconButton(
            icon: _isLoading 
                ? SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(
                      strokeWidth: 2, 
                      color: widget.contentColor
                    )
                  )
                : Icon(Icons.download, color: widget.contentColor),
            onPressed: _isLoading ? null : _downloadAudio,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.only(left: 4),
          ),
      ],
    );
  }
}
