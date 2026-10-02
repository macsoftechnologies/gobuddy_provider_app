import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class UniversalVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const UniversalVideoPlayer({super.key, required this.videoUrl});

  @override
  State<UniversalVideoPlayer> createState() => _UniversalVideoPlayerState();
}

class _UniversalVideoPlayerState extends State<UniversalVideoPlayer> {
  VideoPlayerController? _videoController;
  bool _videoAvailable = true;
  bool _videoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    _videoController = VideoPlayerController.network(widget.videoUrl);

    try {
      await _videoController!.initialize();
      _videoController!.play();
      // Update slider periodically
      _videoController!.addListener(() {
        setState(() {});
      });
      setState(() {
        _videoInitialized = true;
      });
    } catch (e) {
      setState(() {
        _videoAvailable = false;
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    if (!_videoAvailable) {
      return Scaffold(
        body: const Center(
          child: Text(
            "Video unavailable",
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _videoController != null && _videoInitialized
            ? LayoutBuilder(
                builder: (context, constraints) {
                  final _ = constraints.maxHeight; // videoHeight
                  final videoWidth = constraints.maxWidth;

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Video player
                      SizedBox(
                        width: videoWidth,
                        height: 400,
                        child: AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        ),
                      ),
                      // Progress seeker on top
                      Positioned(
                       bottom: 0,
                        left: 16,
                        right: 16,
                        child: Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 2,
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6),
                              ),
                              child: Slider(
                                activeColor: Colors.blue,
                                inactiveColor: Colors.white.withOpacity(0.3),
                                min: 0,
                                max: _videoController!.value.duration.inMilliseconds
                                    .toDouble(),
                                value: _videoController!.value.position.inMilliseconds
                                    .toDouble()
                                    .clamp(
                                        0,
                                        _videoController!.value.duration.inMilliseconds
                                            .toDouble()),
                                onChanged: (value) {
                                  _videoController!.seekTo(
                                    Duration(milliseconds: value.toInt()),
                                  );
                                },
                              ),
                            ),
                            // Time labels
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(
                                      _videoController!.value.position),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                                Text(
                                  _formatDuration(
                                      _videoController!.value.duration),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Center Play/Pause button
                      if (!_videoController!.value.isPlaying)
                        GestureDetector(
                          onTap: () => _videoController!.play(),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 64,
                          ),
                        ),
                    ],
                  );
                },
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
