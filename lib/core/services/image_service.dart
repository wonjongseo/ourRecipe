import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:our_recipe/core/common/app_functions.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/helpers/log_manager.dart';
import 'package:our_recipe/core/services/icloud/app_data_path_service.dart';
import 'package:uuid/uuid.dart';

class ImageService {
  /// 카메라/앨범 선택 바텀시트를 열고 선택된 이미지를 반환한다.
  static Future<File?> openCameraOrLibarySheet(
    BuildContext context, {
    VoidCallback? onPickStart,
    VoidCallback? onPickEnd,
  }) async {
    return await AppFunctions.showBottomSheet(
      context: context,
      child: Padding(
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
    );
  }

  /// 카메라로 촬영한 원본 이미지를 가져온다.
  static Future<File?> _pickImageFromCamera() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );

      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      LogManager.error("$e");
    }
    return null;
  }

  /// 공통 크롭 UI.
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

  /// 선택된 원본 이미지를 사용자가 원할 때만 크롭한다.
  static Future<File?> cropSelectedImage(File file) async {
    try {
      if (!await file.exists()) return null;
      final croppedFile = await _cropImage(XFile(file.path));
      if (croppedFile == null) return null;
      return File(croppedFile.path);
    } catch (e) {
      LogManager.error("$e");
    }
    return null;
  }

  /// 앱 로컬 데이터 경로에 이미지를 저장하고 최종 절대경로를 반환한다.
  static Future<String> saveFile(File file) async {
    final imageName = '${const Uuid().v4()}.png';
    final dataDirPath = await AppDataPathService.getRecipeImagesDirectoryPath();
    final targetPath = '$dataDirPath/$imageName';
    await file.copy(targetPath);
    return targetPath;
  }

  /// 저장된 이미지(절대경로 또는 파일명)를 삭제한다.
  static Future<void> deleteSavedFile(String? pathOrName) async {
    if (pathOrName == null) return;
    final value = pathOrName.trim();
    if (value.isEmpty) return;
    try {
      final imageDirPath = await AppDataPathService.getRecipeImagesDirectoryPath();
      final target = p.isAbsolute(value)
          ? File(value)
          : File(p.join(imageDirPath, value));

      // 앱 로컬 저장소 밖의 절대경로는 삭제하지 않는다.
      // 화면에 남아 있던 오래된 외부 경로를 실수로 지우지 않기 위한 안전장치다.
      if (p.isAbsolute(target.path) && !p.isWithin(imageDirPath, target.path)) {
        final legacyPath = p.join(
          await AppDataPathService.getAppDataDirectoryPath(),
          p.basename(target.path),
        );
        if (target.path != legacyPath) {
          LogManager.warning(
            '[iCloud][Image] skipped delete outside image storage: ${target.path}',
          );
          return;
        }
      }

      if (await target.exists()) {
        await target.delete();
      }
    } catch (e) {
      LogManager.error('deleteSavedFile failed: $e');
    }
  }

  /// 앨범에서 원본 이미지를 가져온다.
  static Future<File?> _getImageFromLibery() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      LogManager.error("$e");
    }
    return null;
  }
}
