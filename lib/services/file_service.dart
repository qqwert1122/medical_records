import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class FileService {
  static const String _imageFolder = 'images';

  // 앱 내부 저장소 디렉토리 가져오기
  Future<Directory> _getAppDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory(path.join(appDir.path, _imageFolder));

    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }

    return imageDir;
  }

  // 단일 이미지를 앱 내부 저장소에 복사
  Future<String> saveImageToAppStorage(String imagePath) async {
    try {
      final File sourceFile = File(imagePath);

      if (!await sourceFile.exists()) {
        throw Exception('원본 파일이 존재하지 않습니다: $imagePath');
      }

      final Directory appDir = await _getAppDirectory();
      final String fileName =
          '${const Uuid().v4()}.${path.extension(imagePath).substring(1)}';
      final String newPath = path.join(appDir.path, fileName);

      final File newFile = await sourceFile.copy(newPath);
      return newFile.path;
    } catch (e) {
      throw Exception('이미지 저장 실패: $e');
    }
  }

  // 여러 이미지를 앱 내부 저장소에 복사
  Future<List<String>> saveImagesToAppStorage(List<String> imagePaths) async {
    List<String> savedPaths = [];

    for (String imagePath in imagePaths) {
      try {
        final String savedPath = await saveImageToAppStorage(imagePath);
        savedPaths.add(savedPath);
      } catch (e) {
        print('이미지 저장 실패: $imagePath, 에러: $e');
        // 실패한 이미지는 건너뛰고 계속 진행
        continue;
      }
    }

    return savedPaths;
  }

  Future<List<String>> getStoredImageNames() async {
    final directory = await getApplicationDocumentsDirectory();
    final dir = Directory(directory.path);
    final files =
        dir
            .listSync(recursive: true)
            .where(
              (file) =>
                  file is File &&
                  (file.path.endsWith('.jpg') ||
                      file.path.endsWith('.png') ||
                      file.path.endsWith('.jpeg')),
            )
            .map((file) => path.basename(file.path))
            .toList();
    return files;
  }

  // 이미지 파일 삭제
  Future<bool> deleteImage(String imagePath) async {
    try {
      final File file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('이미지 삭제 실패: $imagePath, 에러: $e');
      return false;
    }
  }

  // 여러 이미지 파일 삭제
  Future<void> deleteImages(List<String> imagePaths) async {
    for (String imagePath in imagePaths) {
      await deleteImage(imagePath);
    }
  }

  // 파일 존재 여부 확인
  Future<bool> fileExists(String filePath) async {
    return await File(filePath).exists();
  }

  // 앱 내부 저장소 정리 (사용하지 않는 이미지 삭제)
  Future<void> cleanupUnusedImages(List<String> usedImagePaths) async {
    try {
      final Directory appDir = await _getAppDirectory();
      final List<FileSystemEntity> files = appDir.listSync();

      for (FileSystemEntity file in files) {
        if (file is File) {
          if (!usedImagePaths.contains(file.path)) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      print('이미지 정리 실패: $e');
    }
  }
}
