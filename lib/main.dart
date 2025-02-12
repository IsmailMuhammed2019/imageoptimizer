import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const ImageOptimizationScreen(),
    );
  }
}

class ImageOptimizationScreen extends StatefulWidget {
  const ImageOptimizationScreen({super.key});

  @override
  _ImageOptimizationScreenState createState() =>
      _ImageOptimizationScreenState();
}

class _ImageOptimizationScreenState extends State<ImageOptimizationScreen> {
  final List<File> images = [];
  final ImagePicker _picker = ImagePicker();

  Future<File> _downloadAndCompressImage(String url) async {
    final response = await http.get(Uri.parse(url));
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${url.split('/').last}');
    await file.writeAsBytes(response.bodyBytes);

    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      '${dir.path}/compressed_${url.split('/').last}',
      quality: 80,
    );

    return compressedFile != null ? compressedFile as File : file;
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      final dir = await getTemporaryDirectory();
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        pickedFile.path,
        '${dir.path}/compressed_${pickedFile.name}',
        quality: 80,
      );
      if (compressedFile != null) {
        setState(() {
          images.add(File(compressedFile.path));
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Image Optimization Demo',
          textAlign: TextAlign.center,
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _pickImage(ImageSource.camera),
                  child: const Text('Take Photo'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  child: const Text('Upload Photo'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Expanded(
              child: ListView.builder(
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final imageSize = images[index].lengthSync();
                  final imageSizeInKB = (imageSize / 1024).toStringAsFixed(2);

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            images[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text('Size: $imageSizeInKB KB'),
                        const SizedBox(height: 40),
                        ElevatedButton(
                          onPressed: () {
                            final xFile = XFile(images[index].path);
                            Share.shareXFiles([xFile],
                                text: 'Share the image to compare the size!');
                          },
                          child: const Text('Share'),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
