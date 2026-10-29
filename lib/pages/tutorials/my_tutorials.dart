import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gobuddy/models/my_tutorials.dart';
import 'package:gobuddy/utils/my_colors.dart';
import 'package:gobuddy/utils/util_class.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class MyTutorialsScreen extends StatefulWidget {
  const MyTutorialsScreen({super.key});

  @override
  State<MyTutorialsScreen> createState() => _MyTutorialsScreenState();
}

class _MyTutorialsScreenState extends State<MyTutorialsScreen> {
  GetTutorialsModel? tutorialsModel;
  bool isLoading = true;
  int? _playingIndex;
  YoutubePlayerController? _youtubeController;

  @override
  void initState() {
    super.initState();
    _getTutorials();
  }

  @override
  void dispose() {
    _youtubeController?.close();
    super.dispose();
  }

  String _extractVideoId(String rawUrl) {
    String clean = rawUrl.trim();
    if (clean.isEmpty) return "";
    if (clean.contains('youtu.be/')) {
      clean = clean.split('youtu.be/').last.split('?').first;
    } else if (clean.contains('watch?v=')) {
      clean = clean.split('watch?v=').last.split('&').first;
    } else if (clean.contains('embed/')) {
      clean = clean.split('embed/').last.split('?').first;
    } else {
      clean = clean.split('?').first.trim();
    }
    return clean;
  }

  void _playVideo(int index, String rawUrl) {
    final videoId = _extractVideoId(rawUrl);
    if (videoId.isEmpty) {
      if (mounted) {
        UtilClass.showAlertDialog(
          context: context,
          message: "Invalid video link",
        );
      }
      return;
    }

    if (_playingIndex == index && _youtubeController != null) {
      return;
    }

    _youtubeController?.pauseVideo();
    _youtubeController?.close();

    final newController = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        showControls: true,
      ),
    );

    setState(() {
      _playingIndex = index;
      _youtubeController = newController;
    });
  }

  Future<void> _getTutorials() async {
    if (!await UtilClass.checkInternet()) {
      if (mounted) {
        UtilClass.showAlertDialog(
          context: context,
          message: "No Internet Connection",
        );
      }
      return;
    }

    try {
      final response = await Dio().get(
        'https://dev.gobuddyindia.com/api/tutorial',
        options: Options(headers: {'Accept': 'application/json'}),
      );

      final jsonResponse = response.data is String
          ? jsonDecode(response.data)
          : response.data;

      tutorialsModel = GetTutorialsModel.fromJson(jsonResponse);
    } catch (e) {
      if (mounted) {
        UtilClass.showAlertDialog(context: context, message: e.toString());
      }
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tutorials", style: TextStyle(color: Colors.white)),
        backgroundColor: MyColors.appThemeLight,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: tutorialsModel?.tutorials.length ?? 0,
              itemBuilder: (context, index) {
                final tutorial = tutorialsModel!.tutorials[index];
                final videoId = _extractVideoId(tutorial.videoLink);
                final isPlaying = _playingIndex == index && _youtubeController != null;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔹 Video Player OR Thumbnail (Plays in the same place)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: isPlaying
                            ? YoutubePlayer(
                                controller: _youtubeController!,
                                aspectRatio: 16 / 9,
                              )
                            : GestureDetector(
                                onTap: () => _playVideo(index, tutorial.videoLink),
                                child: Stack(
                                  children: [
                                    SizedBox(
                                      height: 190,
                                      width: double.infinity,
                                      child: videoId.isNotEmpty
                                          ? Image.network(
                                              'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  Image.asset(
                                                'assets/images/gb.png',
                                                fit: BoxFit.contain,
                                              ),
                                            )
                                          : Image.asset(
                                              'assets/images/gb.png',
                                              fit: BoxFit.contain,
                                            ),
                                    ),
                                    Positioned.fill(
                                      child: Container(
                                        alignment: Alignment.center,
                                        color: Colors.black.withValues(alpha: 0.3),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.5),
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          child: const Icon(
                                            Icons.play_arrow_rounded,
                                            size: 54,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),

                      // 🔹 Title Row (Green Tick)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tutorial.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 🔹 Description
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          tutorial.description,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

