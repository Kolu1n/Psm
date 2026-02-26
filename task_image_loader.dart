import 'package:cloud_firestore/cloud_firestore.dart';

class TaskImageLoader {
  static final Map<String, String> _imageCache = {};

  static Future<String?> getImageBase64(String? imageRef) async {
    if (imageRef == null || imageRef.isEmpty) return null;

    if (_imageCache.containsKey(imageRef)) {
      return _imageCache[imageRef];
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('task_images')
          .doc(imageRef)
          .get();

      if (doc.exists) {
        final imageBase64 = doc.data()?['imageBase64'] as String?;
        if (imageBase64 != null) {
          _imageCache[imageRef] = imageBase64;
          return imageBase64;
        }
      }
      return null;
    } catch (e) {
      print('Ошибка загрузки изображения: $e');
      return null;
    }
  }

  static void clearCache() {
    _imageCache.clear();
  }

  static void removeFromCache(String imageRef) {
    _imageCache.remove(imageRef);
  }
}