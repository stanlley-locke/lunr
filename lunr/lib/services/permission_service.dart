import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<void> requestInitialPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.photos,
      Permission.videos,
      Permission.audio,
      Permission.camera,
      Permission.microphone,
      // For Android 13+
      Permission.manageExternalStorage, 
    ].request();

    // You can handle denied permissions here if needed
    statuses.forEach((permission, status) {
      if (!status.isGranted) {
        print('${permission.toString()} was denied');
      }
    });
  }
}
