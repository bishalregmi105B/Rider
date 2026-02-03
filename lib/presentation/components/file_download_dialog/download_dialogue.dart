import 'dart:io';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/environment.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../../../core/utils/my_color.dart';
import '../../../core/utils/my_strings.dart';
import '../../../core/utils/style.dart';
import '../snack_bar/show_custom_snackbar.dart';

class DownloadingDialog extends StatefulWidget {
  final String url;
  final String fileName;

  const DownloadingDialog({
    super.key,
    required this.url,
    required this.fileName,
  });

  @override
  DownloadingDialogState createState() => DownloadingDialogState();
}

class DownloadingDialogState extends State<DownloadingDialog> {
  int _total = 0, _received = 0;

  String _getTimestamp() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  String _getFileExtension(String url) {
    final extension = url.split('.').last;
    return extension.contains('/') ? 'pdf' : extension;
  }

  Future<Directory> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      return Directory('/storage/emulated/0/Download');
    } else {
      return await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    }
  }

  Future<void> _downloadFile() async {
    try {
      Dio dio = Dio();
      String fileExtension = _getFileExtension(widget.url);
      String dynamicFileName = '${widget.fileName}_${_getTimestamp()}.$fileExtension';
      Directory dir = await _getDownloadDirectory();
      String fullPath = '${dir.path}/$dynamicFileName';

      await dio.download(
        widget.url,
        fullPath,
        options: Options(
          headers: {"dev-token": Environment.devToken},
        ),
        onReceiveProgress: (received, total) {
          setState(() {
            _received = received;
            _total = total;
          });
        },
      );

      Get.back();
      CustomSnackBar.success(
        successList: [MyStrings.fileDownloadedSuccess],
      );
    } catch (e) {
      Get.back();
      CustomSnackBar.error(errorList: [MyStrings.requestFail]);
    }
  }

  @override
  void initState() {
    super.initState();
    _downloadFile();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: MyColor.getCardBgColor(),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Center(
            child: Padding(
              padding: EdgeInsets.all(10),
              child: SpinKitThreeBounce(
                color: MyColor.primaryColor,
                size: 20.0,
              ),
            ),
          ),
          if (_total > 0)
            Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  '${MyStrings.downloading.tr} ${_received ~/ 1024}/${_total ~/ 1024} ${'KB'.tr}',
                  style: regularDefault,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

