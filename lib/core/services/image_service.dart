import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/helpers/log_manager.dart';
import 'package:path_provider/path_provider.dart';

class ImageService {
  static Future<File?> openCameraOrLibarySheet(
    BuildContext context, {
    VoidCallback? onPickStart,
    VoidCallback? onPickEnd,
  }) async {
    print('asas');
    return await showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(top: 10),
              width: 100,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () async {
                      try {
                        onPickStart?.call();
                        final image = await _pickImageFromCamera();
                        Get.back(result: image);
                      } catch (e) {
                        LogManager.error('$e');
                      } finally {
                        onPickEnd?.call();
                      }
                    },
                    icon: Icon(Icons.camera_alt_outlined, size: 30),
                  ),
                  SizedBox(width: 20),
                  IconButton(
                    onPressed: () async {
                      try {
                        onPickStart?.call();
                        final image = await _getImageFromLibery();
                        Get.back(result: image);
                      } catch (e) {
                        LogManager.error('$e');
                      } finally {
                        onPickEnd?.call();
                      }
                    },
                    icon: Icon(Icons.folder_copy_outlined, size: 10 * 3),
                  ),
                  SizedBox(width: 10 * 2),
                ],
              ),
            ),
            SizedBox(height: 10 * 5),
          ],
        );
      },
    );
  }

  static Future<File?> _pickImageFromCamera() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );

      if (image == null) return null;

      final croppedFile = await _cropImage(image!);
      final selected =
          croppedFile == null ? File(image.path) : File(croppedFile.path);

      return await _persistImage(selected);
    } catch (e) {
      print('e.toString : ${e.toString}');
    }
    return null;
  }

  static Future<CroppedFile?> _cropImage(XFile file) async {
    return await ImageCropper().cropImage(
      sourcePath: file.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: AppStrings.cropper.tr,
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
          ],
        ),
        IOSUiSettings(
          title: AppStrings.cropper.tr,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
          ],
        ),
      ],
    );
  }

  static Future<File?> _getImageFromLibery() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return null;

      final croppedFile = await _cropImage(image!);
      final selected =
          croppedFile == null ? File(image.path) : File(croppedFile.path);
      return await _persistImage(selected);
    } catch (e) {
      LogManager.error("$e");
    }
    return null;
  }

  static Future<File> _persistImage(File source) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory('${appDocDir.path}/recipe_images');
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }

    final extension = _fileExtension(source.path);
    final filename = 'img_${DateTime.now().microsecondsSinceEpoch}$extension';
    final destinationPath = '${imageDir.path}/$filename';
    return source.copy(destinationPath);
  }

  static String _fileExtension(String path) {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex < 0) return '.jpg';
    final ext = path.substring(dotIndex);
    if (ext.length > 8) return '.jpg';
    return ext;
  }
}

/**
 * import 'dart:io';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ours_log/common/utilities/app_function.dart';
import 'package:ours_log/common/utilities/app_snackbar.dart';
import 'package:ours_log/common/utilities/string/app_string.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:uuid/uuid.dart';

class ImageController extends GetxController {
  static late Directory directory;

  static ImageController instance = Get.find<ImageController>();

  String get path => directory.path;
  @override
  void onInit() {
    getDirectory();
    super.onInit();
  }

  static getDirectory() async {
    directory = await getApplicationDocumentsDirectory();
  }

  static void requestPermisson() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.hasAccess) {
      return;
    }
  }

  Future<String> saveFile(File file) async {
    String imageName = '${const Uuid().v4()}.png';

    final String path = '${directory.path}/$imageName';
    await file.copy(path);
    return imageName;
  }

  static Future<File?> _pickImageFromCamera() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );

      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      print('e.toString : ${e.toString}');

      AppSnackbar.showNoPermissionSnackBar(
          message: AppString.noCameraPermssionMsg.tr);
    }
    return null;
  }

  static Future<File?> _getImageFromLibery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        return null;
      }
      return File(image.path);
    } catch (e) {
      AppSnackbar.showNoPermissionSnackBar(
          message: AppString.noLibaryPermssion.tr);
    }
    return null;
  }
}

 */
