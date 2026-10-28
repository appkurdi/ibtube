import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const SocialMediaExtractorApp());
}

class SocialMediaExtractorApp extends StatelessWidget {
  const SocialMediaExtractorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Social Media Extractor',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F2027),
        primaryColor: Colors.cyan,
      ),
      home: const DownloadScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  String _statusText = "ئامادەیە بۆ وەرگرتنی لینک...";

  final YoutubeExplode _yt = YoutubeExplode();

  Future<void> _processUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isLoading = true;
      _statusText = "⏳ شیکردنەوەی لینکەکە...";
    });

    final lowerUrl = url.toLowerCase();

    bool isYouTube = lowerUrl.contains('youtube.com') || lowerUrl.contains('youtu.be');
    bool isFacebook = lowerUrl.contains('facebook.com') || lowerUrl.contains('fb.watch');
    bool isInstagram = lowerUrl.contains('instagram.com');
    bool isTikTok = lowerUrl.contains('tiktok.com');
    bool isX = lowerUrl.contains('x.com') || lowerUrl.contains('twitter.com');
    bool isSnapchat = lowerUrl.contains('snapchat.com');

    try {
      if (!isYouTube && !isFacebook && !isInstagram && !isTikTok && !isX && !isSnapchat) {
        setState(() {
          _statusText = "❌ تەنها پشتگیری (یوتیوب، فەیسبووک، ئینستاگرام، تیکتۆک، ئێکس، سناپچات) دەکرێت.";
        });
        return;
      }

      if (isYouTube) {
        await _extractYoutube(url);
        return;
      }

      await _extractUniversal(url);
      
    } catch (e) {
      setState(() {
        _statusText = "❌ کێشەیەک ڕوویدا. دڵنیابە لە لینکەکە.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _extractYoutube(String url) async {
    setState(() {
      _statusText = "⚙️ شیکردنەوەی ڤیدیۆی یوتیوب لەناو ئامێرەکەت...";
    });
    
    var manifest = await _yt.videos.streamsClient.getManifest(url);
    var streamInfo = manifest.muxed.withHighestBitrate();
    
    if (streamInfo != null) {
      setState(() {
        _statusText = "✅ ڤیدیۆی یوتیوب ئامادەیە!";
      });
      await _launchDownload(streamInfo.url.toString());
    } else {
      setState(() {
        _statusText = "❌ هیچ کوالێتییەکی گونجاو بۆ یوتیوب نەدۆزرایەوە.";
      });
    }
  }

  Future<void> _extractUniversal(String url) async {
    setState(() {
      _statusText = "⚙️ هێنانی ڤیدیۆکە لە تۆڕە کۆمەڵایەتییەکە...";
    });

    const targetApi = "https://api.cobalt.tools/api/json";
    final proxyUrl = Uri.parse("https://corsproxy.io/?${Uri.encodeComponent(targetApi)}");

    try {
      final response = await http.post(
        proxyUrl,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          "url": url,
          "vQuality": "720", 
          "filenamePattern": "classic"
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'error') {
          setState(() {
            _statusText = "❌ لینکەکە هەڵەیە یان ڤیدیۆکە تایبەتە (Private).";
          });
        } else {
          setState(() {
            _statusText = "✅ ڤیدیۆکە دۆزرایەوە!";
          });
          await _launchDownload(data['url']);
        }
      } else {
        setState(() {
          _statusText = "❌ نەتوانرا پەیوەندی بە سێرڤەری شیکارکەرەوە بکرێت.";
        });
      }
    } catch (e) {
      setState(() {
        _statusText = "❌ کێشەی هێڵی ئینتەرنێت هەیە.";
      });
    }
  }

  Future<void> _launchDownload(String url) async {
    final Uri videoUri = Uri.parse(url);
    if (await canLaunchUrl(videoUri)) {
      await launchUrl(
        videoUri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      setState(() {
        _statusText = "❌ نەتوانرا پرۆسەی داگرتن دەست پێ بکات.";
      });
    }
  }

  @override
  void dispose() {
    _yt.close();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.video_library, size: 50, color: Colors.cyan),
              const SizedBox(height: 10),
              const Text(
                "SOCIAL MEDIA EXTRACTOR",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.cyan),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              const Text(
                "پشتگیری: یوتیوب، فەیسبووک، ئینستاگرام، تیکتۆک، ئێکس، سناپچات",
                style: TextStyle(fontSize: 12, color: Colors.white70),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _urlController,
                textAlign: TextAlign.right,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "لینکێ ڤیدیۆیێ ل ڤێرە بنڤێسە...",
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isLoading ? null : _processUrl,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text("دۆزینەوە و داگرتن ⬇️", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _statusText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _statusText.contains("❌") ? Colors.red : Colors.greenAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
