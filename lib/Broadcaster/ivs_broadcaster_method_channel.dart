import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ivs_broadcaster/helpers/enums.dart';
import 'package:permission_handler/permission_handler.dart';

import 'ivs_broadcaster_platform_interface.dart';

class MethodChannelIvsBroadcaster extends IvsBroadcasterPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('ivs_broadcaster');
  final eventChannel = const EventChannel("ivs_broadcaster_event");

  StreamSubscription? eventStream;

  @override
  Future<void> changeCamera(CameraType cameraType) async {
    try {
      await methodChannel.invokeMethod<void>('changeCamera', <String, dynamic>{
        'type': cameraType.index.toString(),
      });
    } catch (e) {
      throw Exception("Unable to change the camera [Change Camera]");
    }
  }

  @override
  Future<bool> requestPermissions() async {
    try {
      final persissions = [
        Permission.camera,
        Permission.microphone,
      ];
      await persissions.request();
      final cameraPermission = await Permission.camera.status;
      final microphonePermission = await Permission.microphone.status;
      if (cameraPermission.isGranted && microphonePermission.isGranted) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> startBroadcast({
    required String url,
    required String streamKey,
    CameraType cameraType = CameraType.BACK
  }) async {
    try {
      await methodChannel.invokeMethod("startBroadcast");
    } catch (e) {
      try {
        final permissionStatus = await requestPermissions();
        if (!permissionStatus) {
          throw Exception(
            "Please Grant Camera and Microphone Permsission [Start Broadcast]",
          );
        }
        if (url.isEmpty || streamKey.isEmpty) {
          throw Exception('url or streamKey is empty [Start Broadcast]');
        }
        await methodChannel.invokeMethod<void>('startBroadcast', <String, dynamic>{
          'url': url,
          'streamKey': streamKey,
          'cameraType': cameraType.index.toString()
        });
        eventStream?.cancel();
//        eventStream = eventChannel
//            .receiveBroadcastStream()
//            .listen(onData, onError: onError);
      } catch (e) {
        throw Exception("$e [Start Broadcast]");
      }
      throw throw Exception("$e [Start Broadcast]");
    }
  }

  @override
  Future<void> startPreview({
    required String url,
    required String streamKey,
    IvsQuality quality = IvsQuality.q720,
    CameraType cameraType = CameraType.BACK,
    void Function(dynamic)? onData,
    void Function(dynamic)? onError,
  }) async {
    try {
      final permissionStatus = await requestPermissions();
      if (!permissionStatus) {
        throw Exception(
          "Please Grant Camera and Microphone Permsission [Start Preview]",
        );
      }
      if (url.isEmpty || streamKey.isEmpty) {
        throw Exception('url or streamKey is empty [Start Preview]');
      }
      await methodChannel.invokeMethod<void>('startPreview', <String, dynamic>{
        'url': url,
        'streamKey': streamKey,
        'cameraType': cameraType.index.toString(),
        "quality": quality.description
      });
      eventStream?.cancel();
      eventStream = eventChannel
          .receiveBroadcastStream()
          .listen(onData, onError: onError);
    } catch (e) {
      throw Exception("$e [Start Preview]");
    }
  }

  @override
  Future<void> stopBroadcast() async {
    try {
      await methodChannel.invokeMethod<void>('stopBroadcast');
    } catch (e) {
      throw Exception("$e [Stop Broadcast]");
    }
  }

  @override
  Future<dynamic> zoomCamera(double zoomValue) async {
    try {
      return await methodChannel
          .invokeMethod<void>("zoomCamera", <String, dynamic>{
        'zoom': zoomValue,
      });
    } catch (e) {
      throw Exception("$e [Zoom Camera]");
    }
  }
}
