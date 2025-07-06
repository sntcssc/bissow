// ignore_for_file: unnecessary_getters_setters, file_names

import 'dart:async';
import 'dart:io';

import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pro_image_editor/core/models/editor_callbacks/pro_image_editor_callbacks.dart';
import 'dart:typed_data';

import 'package:pro_image_editor/features/main_editor/main_editor.dart';

class PickImage {
  final ImagePicker _picker = ImagePicker();
  final StreamController _imageStreamController = StreamController.broadcast();

  Stream get imageStream => _imageStreamController.stream;

  StreamSink get _sink => _imageStreamController.sink;
  StreamSubscription? subscription;
  File? _pickedFile;

  File? get pickedFile => _pickedFile;

  set pickedFile(File? pickedFile) {
    _pickedFile = pickedFile;
  }

  /// Pick image(s) with optional editing
  Future<void> pick({
    ImageSource? source,
    bool? pickMultiple,
    int? imageLimit,
    int? maxLength,
    required BuildContext context,
    bool enableEditing = false, // Parameter for enabling editing
  }) async {
    try {
      if (pickMultiple ?? false) {
        List<XFile> list = await _picker.pickMultiImage(
          imageQuality: Constant.uploadImageQuality,
          requestFullMetadata: true,
        );

        if (imageLimit != null &&
            maxLength != null &&
            (list.length + maxLength) > imageLimit) {
          HelperUtils.showSnackBarMessage(
            context,
            "max5ImagesAllowed".translate(context),
          );
          return;
        } else {
          List<File> templistFile = [];
          for (var image in list) {
            File? myImage = File(image.path);

            // Apply editing if enabled
            if (enableEditing) {
              myImage = await _editImage(context, myImage);
              if (myImage == null) {
                // User canceled editing
                continue;
              }
            }

            // Compress if necessary
            if (await myImage.length() > Constant.maxSizeInBytes) {
              myImage = await HelperUtils.compressImageFile(myImage);
            }
            templistFile.add(myImage);
          }

          _sink.add({
            "error": "",
            "file": templistFile,
          });
        }
      } else {
        final XFile? pickedFile = await _picker.pickImage(
          source: source ?? ImageSource.gallery,
          imageQuality: Constant.uploadImageQuality,
          preferredCameraDevice: CameraDevice.rear,
        );
        if (pickedFile != null) {
          File? file = File(pickedFile.path);

          // Apply editing if enabled
          if (enableEditing) {
            file = await _editImage(context, file);
            if (file == null) {
              // User canceled editing
              _sink.add({
                "error": "Editing canceled",
                "file": [],
              });
              return;
            }
          }

          // Compress if necessary
          if (await file.length() > Constant.maxSizeInBytes) {
            file = await HelperUtils.compressImageFile(file);
          }

          _sink.add({
            "error": "",
            "file": [file], // Wrapped in a list for consistency
          });
        }
      }
    } catch (error) {
      _sink.add({
        "error": error.toString(),
        "file": [],
      });
    }
  }

  /// Helper method to edit an image using pro_image_editor
  Future<File?> _editImage(BuildContext context, File image) async {
    try {
      // Open the pro_image_editor with the image file
      final Uint8List? editedImageData = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProImageEditor.file(
            image,
            callbacks: ProImageEditorCallbacks(
              onImageEditingComplete: (Uint8List bytes) async {
                Navigator.pop(context, bytes); // Return edited image data
              },
              // onCloseEditor: (editorMode) {
              //   Navigator.pop(context, null); // Return null if editor is closed without saving
              // },
            ),
            // Optional: Customize editor settings
          ),
        ),
      );

      if (editedImageData != null) {
        // Save edited image to a temporary file
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/edited_image_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await tempFile.writeAsBytes(editedImageData);
        return tempFile;
      }
      return null; // Return null if editing is canceled
    } catch (e) {
      HelperUtils.showSnackBarMessage(context, "Error editing image: $e");
      return null;
    }
  }

  /// This widget will listen changes in UI, it is wrapper around Stream builder
  Widget listenChangesInUI(
      dynamic Function(
          BuildContext context,
          List<File>? images,
          ) ondata,
      ) {
    return StreamBuilder(
      stream: imageStream,
      builder: ((context, AsyncSnapshot snapshot) {
        if (snapshot.hasData &&
            snapshot.connectionState == ConnectionState.active) {
          List<File>? files;
          if (snapshot.data['file'] is List) {
            files = (snapshot.data['file'] as List).cast<File>();
          } else if (snapshot.data['file'] is File) {
            files = [snapshot.data['file'] as File];
          }

          pickedFile = files?.isNotEmpty == true ? files![0] : null;

          return ondata.call(context, files);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return ondata.call(context, null);
        }
        return ondata.call(context, null);
      }),
    );
  }

  void listener(void Function(dynamic)? onData) {
    subscription = imageStream.listen((data) {
      if ((subscription?.isPaused == false)) {
        onData?.call(data['file']);
      }
    });
  }

  void pauseSubscription() {
    subscription?.pause();
  }

  void resumeSubscription() {
    subscription?.resume();
  }

  void clearImage() {
    pickedFile = null;
    _sink.add({"file": []});
  }

  void dispose() {
    if (!_imageStreamController.isClosed) {
      _imageStreamController.close();
    }
  }
}

enum PickImageStatus { initial, waiting, done, error }
