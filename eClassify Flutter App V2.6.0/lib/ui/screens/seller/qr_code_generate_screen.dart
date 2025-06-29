// Subhankar added this screen
import 'dart:io';
import 'dart:ui' as ui;
import 'package:animate_do/animate_do.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:eClassify/ui/screens/widgets/blurred_dialog_box.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/api.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/rendering.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;

class QRCodeGenerateScreen extends StatefulWidget {
  final int sellerId;
  final String sellerName;
  final String? sellerPhone;
  final String? profilePicture;
  final bool isVerified;

  const QRCodeGenerateScreen({
    super.key,
    required this.sellerId,
    required this.sellerName,
    this.sellerPhone,
    this.profilePicture,
    this.isVerified = false,
  });

  static Route route(RouteSettings routeSettings) {
    Map arguments = routeSettings.arguments as Map;
    return MaterialPageRoute(
      builder: (_) => QRCodeGenerateScreen(
        sellerId: arguments['sellerId'],
        sellerName: arguments['sellerName'],
        sellerPhone: arguments['sellerPhone'],
        profilePicture: arguments['profilePicture'],
        isVerified: arguments['isVerified'] ?? false,
      ),
    );
  }

  @override
  _QRCodeGenerateScreenState createState() => _QRCodeGenerateScreenState();
}

class _QRCodeGenerateScreenState extends State<QRCodeGenerateScreen> {
  bool _isLoading = false;
  final GlobalKey _qrCardKey = GlobalKey();
  final MethodChannel _channel = const MethodChannel('com.bissow.dev_app/media_scan');

  Future<ui.Image?> _loadLogoImage(BuildContext context) async {
    try {
      final data = await DefaultAssetBundle.of(context).load('assets/images/logo.png');
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      debugPrint("Logo load error: $e");
      return null;
    }
  }

  Future<Uint8List> _generateQRImage(String data, BuildContext context) async {
    try {
      final qrValidationResult = QrValidator.validate(
        data: data,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
      );
      if (!qrValidationResult.isValid) {
        throw Exception("Invalid QR code data");
      }

      final qrCode = qrValidationResult.qrCode!;
      final logoImage = await _loadLogoImage(context);
      final painter = QrPainter.withQr(
        qr: qrCode,
        embeddedImage: logoImage,
        embeddedImageStyle: const QrEmbeddedImageStyle(size: Size(40, 40)),
        emptyColor: Colors.white,
        gapless: true,
      );

      final byteData = await painter.toImageData(300);
      if (byteData == null) {
        throw Exception("Failed to convert QR code to image");
      }
      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint("QR image generation error: $e");
      throw Exception("errorGeneratingQR");
    }
  }

  Future<Uint8List> _captureQRCard() async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      final boundary = _qrCardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception("Failed to find render boundary");
      }
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception("Failed to convert card to image");
      }
      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint("Card capture error: $e");
      throw Exception("errorCapturingImage");
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrUrl = HelperUtils.nativeDeepLinkUrl("seller", widget.sellerId.toString());

    return Scaffold(
      backgroundColor: context.color.backgroundColor,
      appBar: AppBar(
        title: Text(
          "qrCodeTitle".translate(context),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.blue),
        ),
        leading: IconButton(
          icon: UiUtils.getSvg(AppIcons.arrowLeft, color: context.color.textDefaultColor),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: context.color.secondaryColor,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                children: [
                  FadeInDown(
                    duration: const Duration(milliseconds: 600),
                    child: _buildQRCard(context, qrUrl),
                  ),
                  const SizedBox(height: 30),
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    child: _buildActionButtons(context, qrUrl),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: SpinKitFadingCircle(
                  color: context.color.territoryColor,
                  size: 60.0,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQRCard(BuildContext context, String qrUrl) {
    return RepaintBoundary(
      key: _qrCardKey,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              context.color.secondaryColor,
              context.color.secondaryColor.withOpacity(0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: context.color.textDefaultColor.withOpacity(0.2),
              blurRadius: 16,
              spreadRadius: 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            decoration: BoxDecoration(
              color: context.color.secondaryColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: widget.profilePicture != null && widget.profilePicture!.isNotEmpty
                          ? UiUtils.getImage(
                        widget.profilePicture!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      )
                          : UiUtils.getSvg(
                        AppIcons.defaultPersonLogo,
                        width: 60,
                        height: 60,
                        color: context.color.territoryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.sellerName,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.color.textDefaultColor,
                              ),
                            ),
                            if (widget.isVerified)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: UiUtils.getSvg(
                                  AppIcons.verifiedIcon,
                                  width: 20,
                                  height: 20,
                                  color: context.color.territoryColor,
                                ),
                              ),
                          ],
                        ),
                        if (widget.sellerPhone != null && widget.sellerPhone!.isNotEmpty)
                          Text(
                            widget.sellerPhone!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: context.color.textDefaultColor.withOpacity(0.7),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: context.color.territoryColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: QrImageView(
                    data: qrUrl,
                    version: QrVersions.auto,
                    size: 240.0,
                    backgroundColor: Colors.white,
                    gapless: false,
                    eyeStyle: const QrEyeStyle(eyeShape:QrEyeShape.square, color: Colors.blueAccent),
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.circle, // or QrDataModuleShape.square
                      color: Colors.blue,
                    ),
                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                    padding: const EdgeInsets.all(8),
                    embeddedImage: const AssetImage('assets/images/logo.png'),
                    embeddedImageStyle: const QrEmbeddedImageStyle(
                      size: Size(90, 90),
                      // color: Colors.blue, // Apply a blue tint
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "scanToViewProfile".translate(context),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.color.textDefaultColor.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, String qrUrl) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: [
        _buildActionButton(
          context,
          icon: Icons.share,
          label: "share".translate(context),
          onTap: () => _showShareOptions(context, qrUrl),
          color: context.color.territoryColor,
        ),
        _buildActionButton(
          context,
          icon: Icons.save,
          label: "save".translate(context),
          onTap: () => _showSaveOptions(context, qrUrl),
          color: context.color.territoryColor,
        ),
        _buildActionButton(
          context,
          icon: Icons.print,
          label: "print".translate(context),
          onTap: () => _printQRCode(context, qrUrl),
          color: context.color.territoryColor,
        ),
        _buildActionButton(
          context,
          icon: Icons.copy,
          label: "copyLink".translate(context),
          onTap: () => _copyLink(context, qrUrl),
          color: context.color.territoryColor,
        ),
      ],
    );
  }

  Widget _buildActionButton(
      BuildContext context, {
        required IconData icon,
        required String label,
        required VoidCallback onTap,
        required Color color,
      }) {
    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
        onTap: () async {
          if (!_isLoading) {
            if (await Vibration.hasVibrator() ?? false) {
              Vibration.vibrate(duration: 50);
            }
            onTap();
          }
        },
        child: ElasticIn(
          duration: const Duration(milliseconds: 300),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.2),
                      color.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                  semanticLabel: label,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.color.textDefaultColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showShareOptions(BuildContext parentContext, String qrUrl) async {
    final result = await showModalBottomSheet<String>(
      context: parentContext,
      backgroundColor: parentContext.color.secondaryColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.image, color: parentContext.color.territoryColor),
              title: Text("shareAsImage".translate(context)),
              onTap: () => Navigator.pop(context, 'image'),
            ),
            ListTile(
              leading: Icon(Icons.picture_as_pdf, color: parentContext.color.territoryColor),
              title: Text("shareAsPDF".translate(context)),
              onTap: () => Navigator.pop(context, 'pdf'),
            ),
            ListTile(
              leading: Icon(Icons.link, color: parentContext.color.territoryColor),
              title: Text("shareLink".translate(context)),
              onTap: () => Navigator.pop(context, 'link'),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      if (result == 'image') {
        _shareQRCode(parentContext, qrUrl, asImage: true);
      } else if (result == 'pdf') {
        _shareQRCode(parentContext, qrUrl, asImage: false);
      } else if (result == 'link') {
        _shareLink(parentContext, qrUrl);
      }
    }
  }

  Future<void> _showSaveOptions(BuildContext parentContext, String qrUrl) async {
    final result = await showModalBottomSheet<String>(
      context: parentContext,
      backgroundColor: parentContext.color.secondaryColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.image, color: parentContext.color.territoryColor),
              title: Text("saveAsImage".translate(context)),
              onTap: () => Navigator.pop(context, 'image'),
            ),
            ListTile(
              leading: Icon(Icons.picture_as_pdf, color: parentContext.color.territoryColor),
              title: Text("saveAsPDF".translate(context)),
              onTap: () => Navigator.pop(context, 'pdf'),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      if (result == 'image') {
        _saveQRCode(parentContext, qrUrl, asImage: true);
      } else if (result == 'pdf') {
        _saveQRCode(parentContext, qrUrl, asImage: false);
      }
    }
  }

  Future<void> _shareQRCode(BuildContext context, String qrUrl, {required bool asImage}) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final directory = await getTemporaryDirectory();
      final fileName = 'Bissow_QR_${widget.sellerId}_${DateTime.now().millisecondsSinceEpoch}.${asImage ? 'png' : 'pdf'}';
      final filePath = '${directory.path}/$fileName';
      File file = File(filePath);

      if (asImage) {
        final image = await _captureQRCard();
        await file.writeAsBytes(image);
      } else {
        final qrImage = await _generateQRImage(qrUrl, context);
        final pdf = await _generatePDF(qrImage, context.color.territoryColor);
        await file.writeAsBytes(await pdf.save());
      }

      if (!await file.exists()) {
        if (mounted) {
          _showErrorDialog(context, "errorWritingFile".translate(context));
        }
        return;
      }

      await Share.shareXFiles(
        [XFile(filePath)],
        text: "${"shareQRMessage".translate(context)} $qrUrl",
        subject: "${widget.sellerName}'s Profile",
      );
    } catch (e) {
      if (mounted) {
        _showErrorDialog(context, e.toString().contains("errorCapturingImage") ? "errorCapturingImage".translate(context) : "errorSharing".translate(context));
      }
      debugPrint("Share error: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _shareLink(BuildContext context, String qrUrl) async {
    if (!mounted) return;
    try {
      await Share.share(
        "${"shareQRMessage".translate(context)} $qrUrl",
        subject: "${widget.sellerName}'s Profile",
      );
    } catch (e) {
      if (mounted) {
        _showErrorDialog(context, "errorSharing".translate(context));
      }
      debugPrint("Share link error: $e");
    }
  }

  Future<void> _saveQRCode(BuildContext context, String qrUrl, {required bool asImage}) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // Request storage permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        if (Platform.isAndroid && await _isAndroidBelow11()) Permission.manageExternalStorage,
      ].request();

      bool permissionDenied = statuses[Permission.storage]?.isDenied == true ||
          statuses[Permission.storage]?.isPermanentlyDenied == true ||
          (Platform.isAndroid &&
              await _isAndroidBelow11() &&
              statuses[Permission.manageExternalStorage]?.isDenied == true) ||
          (Platform.isAndroid &&
              await _isAndroidBelow11() &&
              statuses[Permission.manageExternalStorage]?.isPermanentlyDenied == true);

      if (permissionDenied) {
        if (mounted) {
          _showErrorDialog(context, "storagePermissionDenied".translate(context));
        }
        if (statuses[Permission.storage]?.isPermanentlyDenied == true ||
            (Platform.isAndroid &&
                await _isAndroidBelow11() &&
                statuses[Permission.manageExternalStorage]?.isPermanentlyDenied == true)) {
          await openAppSettings();
        }
        return;
      }

      // Generate file content
      Uint8List fileBytes;
      if (asImage) {
        fileBytes = await _captureQRCard();
      } else {
        final qrImage = await _generateQRImage(qrUrl, context);
        final pdf = await _generatePDF(qrImage, context.color.territoryColor);
        fileBytes = await pdf.save();
      }

      // Generate unique file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'Bissow_QR_${widget.sellerId}_$timestamp.${asImage ? 'png' : 'pdf'}';
      String? filePath;
      bool isPublicStorage = true;

      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;
        debugPrint("Android SDK: $sdkInt");

        if (sdkInt >= 29) {
          // Android 10+ (API 29+): Use MediaStore
          try {
            final uri = await _saveToMediaStore(fileBytes, fileName, asImage);
            debugPrint("MediaStore URI: $uri");
            // Attempt to get file path for logging (not for validation)
            filePath = await _getFilePathFromUri(uri) ?? uri;
            debugPrint("Saved via MediaStore to: $filePath");
          } catch (e) {
            debugPrint("MediaStore save error: $e");
            throw Exception("Failed to save to MediaStore");
          }
        } else {
          // Android 9 or below: Use public directory
          String publicPath = '/storage/emulated/0/${asImage ? 'Pictures' : 'Documents'}/Bissow';
          Directory directory = Directory(publicPath);
          debugPrint("Attempting public directory: $publicPath");

          await directory.create(recursive: true);
          debugPrint("Directory created/exists: ${directory.path}");

          filePath = '$publicPath/$fileName';
          File file = File(filePath);
          await file.writeAsBytes(fileBytes);

          // Verify file exists
          if (!await file.exists()) {
            throw Exception("File not created at $filePath");
          }

          // Trigger media scan
          try {
            await _channel.invokeMethod('scanFile', {'path': filePath});
            debugPrint("Media scan triggered for: $filePath");
          } catch (e) {
            debugPrint("Media scan error: $e");
          }
        }
      } else if (Platform.isIOS) {
        // iOS: Use Documents directory
        Directory directory = await getApplicationDocumentsDirectory();
        String subfolder = asImage ? 'Pictures/Bissow' : 'Documents/Bissow';
        directory = Directory('${directory.path}/$subfolder');
        debugPrint("iOS directory: ${directory.path}");

        await directory.create(recursive: true);
        filePath = '${directory.path}/$fileName';
        File file = File(filePath);
        await file.writeAsBytes(fileBytes);

        // Verify file exists
        if (!await file.exists()) {
          throw Exception("File not created at $filePath");
        }
        isPublicStorage = false;
      } else {
        // Fallback to temporary directory
        Directory directory = await getTemporaryDirectory();
        filePath = '${directory.path}/$fileName';
        File file = File(filePath);
        await file.writeAsBytes(fileBytes);

        // Verify file exists
        if (!await file.exists()) {
          throw Exception("File not created at $filePath");
        }
        isPublicStorage = false;
      }

      // Notify user of success
      if (mounted) {
        String message = "${"savedSuccessfully".translate(context)}: $fileName\n";
        if (isPublicStorage) {
          message += asImage
              ? "checkPicturesFolder".translate(context)
              : "checkDownloadsFolder".translate(context);
        } else {
          message += "fileInAppStorage".translate(context);
        }
        _showSuccessDialog(context, message);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(context, e.toString().contains("errorCapturingImage")
            ? "errorCapturingImage".translate(context)
            : "errorSaving".translate(context));
      }
      debugPrint("Save error: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String?> _getFilePathFromUri(String uri) async {
    try {
      return await _channel.invokeMethod('getFilePathFromUri', {'uri': uri});
    } catch (e) {
      debugPrint("Error getting file path from URI: $e");
      return null;
    }
  }

  Future<String> _saveToMediaStore(Uint8List bytes, String fileName, bool asImage) async {
    try {
      final Map<String, dynamic> args = {
        'bytes': bytes,
        'fileName': fileName,
        'isImage': asImage,
      };
      final String? uri = await _channel.invokeMethod('saveToMediaStore', args);
      if (uri == null) {
        throw Exception("MediaStore returned null URI");
      }
      return uri;
    } catch (e) {
      debugPrint("MediaStore save error: $e");
      throw e;
    }
  }

  Future<void> _printQRCode(BuildContext context, String qrUrl) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final qrImage = await _generateQRImage(qrUrl, context);
      final pdf = await _generatePDF(qrImage, context.color.territoryColor);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );

      if (mounted) {
        _showSuccessDialog(context, "printedSuccessfully".translate(context));
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(context, "errorPrinting".translate(context));
      }
      debugPrint("Print error: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _copyLink(BuildContext context, String qrUrl) async {
    if (!mounted) return;
    try {
      await Clipboard.setData(ClipboardData(text: qrUrl));
      if (mounted) {
        _showSuccessDialog(context, "linkCopied".translate(context));
      }
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 50);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(context, "errorCopyingLink".translate(context));
      }
      debugPrint("Copy link error: $e");
    }
  }

  Future<pw.Document> _generatePDF(Uint8List qrImage, Color territoryColor) async {
    final pdf = pw.Document();
    final pdfImage = pw.MemoryImage(qrImage);
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    Uint8List? logoBytes;
    try {
      logoBytes = (await DefaultAssetBundle.of(context).load('assets/images/logo.png')).buffer.asUint8List();
    } catch (e) {
      debugPrint("Logo load error: $e");
    }
    final logoImage = logoBytes != null ? pw.MemoryImage(logoBytes) : null;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context pwContext) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(territoryColor.value),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  if (logoImage != null) ...[
                    pw.Image(logoImage, width: 40, height: 40),
                    pw.SizedBox(width: 12),
                  ],
                  pw.Text(
                    "Bissow.com",
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 24,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),
            pw.Text(
              widget.sellerName,
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 28,
                color: PdfColors.black,
              ),
            ),
            if (widget.sellerPhone != null && widget.sellerPhone!.isNotEmpty)
              pw.Text(
                widget.sellerPhone!,
                style: pw.TextStyle(font: font, fontSize: 18, color: PdfColors.grey800),
              ),
            if (widget.isVerified)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 8),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      "Verified Seller",
                      style: pw.TextStyle(font: font, fontSize: 16, color: PdfColors.green),
                    ),
                  ],
                ),
              ),
            pw.SizedBox(height: 32),
            pw.Image(pdfImage, width: 300, height: 300),
            pw.SizedBox(height: 24),
            pw.Text(
              "Scan to view ${widget.sellerName}'s profile on Bissow",
              style: pw.TextStyle(font: font, fontSize: 16, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 32),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              color: PdfColors.grey200,
              child: pw.Text(
                "Powered by Bissow | www.bissow.com",
                style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey600),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );

    return pdf;
  }

  void _showSuccessDialog(BuildContext context, String message) {
    if (!mounted) return;
    UiUtils.showBlurredDialoge(
      context,
      dialoge: BlurredDialogBox(
        title: "success".translate(context),
        content: Text(message, textAlign: TextAlign.center),
        svgImagePath: AppIcons.verifiedIcon,
        svgImageColor: context.color.territoryColor,
        showCancelButton: false,
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    if (!mounted) return;
    UiUtils.showBlurredDialoge(
      context,
      dialoge: BlurredDialogBox(
        title: "error".translate(context),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: 40),
            const SizedBox(width: 8),
            Expanded(child: Text(message, textAlign: TextAlign.center)),
          ],
        ),
        svgImagePath: null,
        svgImageColor: null,
        showCancelButton: false,
      ),
    );
  }

  // Helper method to check Android version
  Future<bool> _isAndroidBelow11() async {
    if (Platform.isAndroid) {
      final version = await DeviceInfoPlugin().androidInfo;
      return version.version.sdkInt < 30; // Android 11 is API 30
    }
    return false;
  }
}