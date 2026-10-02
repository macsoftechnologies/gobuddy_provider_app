import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gobuddy/models/my_tutorials.dart';
import 'package:gobuddy/utils/my_colors.dart';
import 'package:gobuddy/utils/util_class.dart';
import 'package:url_launcher/url_launcher.dart';

class MyTutorialsScreen extends StatefulWidget {
  const MyTutorialsScreen({super.key});

  @override
  State<MyTutorialsScreen> createState() => _MyTutorialsScreenState();
}

class _MyTutorialsScreenState extends State<MyTutorialsScreen> {
  GetTutorialsModel? tutorialsModel;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getTutorials();
  }

  Future<void> _getTutorials() async {
    if (!await UtilClass.checkInternet()) {
      UtilClass.showAlertDialog(
        context: context,
        message: "No Internet Connection",
      );
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
      UtilClass.showAlertDialog(context: context, message: e.toString());
    }

    setState(() => isLoading = false);
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
              itemCount: tutorialsModel!.tutorials.length,
              itemBuilder: (context, index) {
                final tutorial = tutorialsModel!.tutorials[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔹 Thumbnail + Overlay
                      GestureDetector(
                        onTap: () async {
                          final rawUrl = tutorial.videoLink.trim();
                          if (rawUrl.isEmpty) return;

                          String formattedUrl = rawUrl;
                          if (!rawUrl.startsWith("http://") && !rawUrl.startsWith("https://")) {
                            formattedUrl = "https://www.youtube.com/watch?v=$rawUrl";
                          }

                          final uri = Uri.tryParse(formattedUrl);
                          if (uri != null) {
                            try {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } catch (e) {
                              debugPrint("Error opening tutorial video: $e");
                            }
                          }
                        },
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              child: Image.asset(
                                'assets/images/gb.png',
                                height: 190,
                                width: double.infinity,
                                fit: BoxFit.contain,
                              ),
                            ),
                            Positioned.fill(
                              child: Container(
                                alignment: Alignment.center,
                                color: Colors.black.withOpacity(0.25),
                                child: const Icon(
                                  Icons.play_circle_fill,
                                  size: 64,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
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

