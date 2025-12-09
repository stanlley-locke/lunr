import 'package:equatable/equatable.dart';

class UserSettings extends Equatable {
  final bool pushNotifications;
  final bool messageNotifications;
  final bool groupNotifications;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool autoDownloadMedia;
  final bool backupEnabled;
  final String theme;
  final String language;

  const UserSettings({
    this.pushNotifications = true,
    this.messageNotifications = true,
    this.groupNotifications = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.autoDownloadMedia = true,
    this.backupEnabled = false,
    this.theme = 'light',
    this.language = 'en',
    this.wallpaper = 'default',
    this.fontSize = 14,
    this.mediaVisibility = true,
  });

  final String wallpaper;
  final int fontSize;
  final bool mediaVisibility;

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      pushNotifications: json['push_notifications'] ?? true,
      messageNotifications: json['message_notifications'] ?? true,
      groupNotifications: json['group_notifications'] ?? true,
      soundEnabled: json['sound_enabled'] ?? true,
      vibrationEnabled: json['vibration_enabled'] ?? true,
      autoDownloadMedia: json['auto_download_media'] ?? true,
      backupEnabled: json['backup_enabled'] ?? false,
      theme: json['theme'] ?? 'light',
      language: json['language'] ?? 'en',
      wallpaper: json['wallpaper'] ?? 'default',
      fontSize: json['font_size'] ?? 14,
      mediaVisibility: json['media_visibility'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'push_notifications': pushNotifications,
      'message_notifications': messageNotifications,
      'group_notifications': groupNotifications,
      'sound_enabled': soundEnabled,
      'vibration_enabled': vibrationEnabled,
      'auto_download_media': autoDownloadMedia,
      'backup_enabled': backupEnabled,
      'theme': theme,
      'language': language,
    };
  }

  UserSettings copyWith({
    bool? pushNotifications,
    bool? messageNotifications,
    bool? groupNotifications,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? autoDownloadMedia,
    bool? backupEnabled,
    String? theme,
    String? language,
  }) {
    return UserSettings(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      messageNotifications: messageNotifications ?? this.messageNotifications,
      groupNotifications: groupNotifications ?? this.groupNotifications,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      autoDownloadMedia: autoDownloadMedia ?? this.autoDownloadMedia,
      backupEnabled: backupEnabled ?? this.backupEnabled,
      theme: theme ?? this.theme,
      language: language ?? this.language,
    );
  }

  bool get isDarkTheme => theme == 'dark';

  @override
  List<Object?> get props => [
    pushNotifications, messageNotifications, groupNotifications,
    soundEnabled, vibrationEnabled, autoDownloadMedia,
    backupEnabled, theme, language
  ];
}