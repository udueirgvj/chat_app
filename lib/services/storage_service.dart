// lib/services/storage_service.dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import '../core/constants/app_constants.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  // ─── Upload Profile Image ──────────────────────────
  Future<String> uploadProfileImage({
    required String userId,
    required File file,
  }) async {
    final ext = path.extension(file.path);
    final ref = _storage
        .ref()
        .child(AppConstants.profileImagesPath)
        .child('$userId$ext');

    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await task.ref.getDownloadURL();
  }

  // ─── Upload Chat Image ─────────────────────────────
  Future<String> uploadChatImage({
    required String chatId,
    required File file,
  }) async {
    final fileName = '${_uuid.v4()}${path.extension(file.path)}';
    final ref = _storage
        .ref()
        .child(AppConstants.chatMediaPath)
        .child(chatId)
        .child(fileName);

    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await task.ref.getDownloadURL();
  }

  // ─── Upload Chat File ──────────────────────────────
  Future<Map<String, dynamic>> uploadChatFile({
    required String chatId,
    required File file,
    required String mimeType,
    void Function(double progress)? onProgress,
  }) async {
    final fileName = path.basename(file.path);
    final fileSize = await file.length();
    final ref = _storage
        .ref()
        .child(AppConstants.chatFilesPath)
        .child(chatId)
        .child('${_uuid.v4()}_$fileName');

    final uploadTask = ref.putFile(
      file,
      SettableMetadata(contentType: mimeType),
    );

    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });
    }

    final snapshot = await uploadTask;
    final url = await snapshot.ref.getDownloadURL();

    return {
      'url': url,
      'fileName': fileName,
      'fileSize': fileSize,
    };
  }

  // ─── Upload Audio Message ──────────────────────────
  Future<String> uploadAudioMessage({
    required String chatId,
    required File file,
  }) async {
    final fileName = '${_uuid.v4()}.m4a';
    final ref = _storage
        .ref()
        .child(AppConstants.chatAudioPath)
        .child(chatId)
        .child(fileName);

    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: 'audio/m4a'),
    );
    return await task.ref.getDownloadURL();
  }

  // ─── Delete File ───────────────────────────────────
  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {}
  }
}
