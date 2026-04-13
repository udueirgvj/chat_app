// lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  static const String appName = 'ChatApp';

  // ─── Firestore Collections ─────────────────────────
  static const String usersCollection    = 'users';
  static const String chatsCollection    = 'chats';
  static const String messagesCollection = 'messages';

  // ─── Storage Paths ─────────────────────────────────
  static const String profileImagesPath = 'profile_images';
  static const String chatMediaPath     = 'chat_media';
  static const String chatFilesPath     = 'chat_files';
  static const String chatAudioPath     = 'chat_audio';

  // ─── SharedPreferences Keys ────────────────────────
  static const String spUserId    = 'user_id';
  static const String spDarkMode  = 'dark_mode';
  static const String spFontSize  = 'font_size';

  // ─── Message Types ─────────────────────────────────
  static const String msgText  = 'text';
  static const String msgImage = 'image';
  static const String msgVideo = 'video';
  static const String msgFile  = 'file';
  static const String msgAudio = 'audio';

  // ─── Limits ────────────────────────────────────────
  static const int maxImageSizeMB  = 10;
  static const int maxFileSizeMB   = 50;
  static const int maxAudioSec     = 300;
  static const int messagePageSize = 30;
}
