// Subhankar added this screen
import 'package:eClassify/app/routes.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/api.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';

class QRCodeScannerScreen extends StatefulWidget {
  const QRCodeScannerScreen({super.key});

  static Route route(RouteSettings routeSettings) {
    return MaterialPageRoute(
      builder: (_) => const QRCodeScannerScreen(),
    );
  }

  @override
  _QRCodeScannerScreenState createState() => _QRCodeScannerScreenState();
}

class _QRCodeScannerScreenState extends State<QRCodeScannerScreen> with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    detectionTimeoutMs: 500,
    detectionSpeed: DetectionSpeed.normal,
  );
  bool _isFlashOn = false;
  bool _isFrontCamera = false;
  bool _isScanning = true;
  bool _isPermissionGranted = false;
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutSine),
    );

    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.camera.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) {
        HelperUtils.showSnackBarMessageWithAction(
          context,
          "cameraPermissionDenied".translate(context),
          type: MessageType.error,
          actionLabel: "Open Settings",
          actionCallback: () => openAppSettings(),
        );
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) Navigator.pop(context);
      }
    } else {
      setState(() => _isPermissionGranted = true);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (!_isScanning) return;
    _isScanning = false;

    await Vibration.vibrate(duration: 100);

    final String? scannedUrl = capture.barcodes.first.rawValue;
    if (scannedUrl == null || !scannedUrl.contains('/seller/')) {
      if (mounted) {
        HelperUtils.showSnackBarMessage(
          context,
          "invalidQRCode".translate(context),
          type: MessageType.error,
        );
      }
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _isScanning = true);
      return;
    }

    try {
      final uri = Uri.parse(scannedUrl);
      final sellerId = uri.pathSegments[1];
      final response = await Api.get(
        url: "${Api.validateSellerQRApi}/$sellerId",
        useBaseUrl: true,
      );

      if (response['error'] == false) {
        if (mounted) {
          Navigator.pushNamed(
            context,
            Routes.sellerProfileScreen,
            arguments: {"sellerId": int.parse(sellerId)},
          );
        }
      } else {
        if (mounted) {
          HelperUtils.showSnackBarMessage(
            context,
            response['message'],
            type: MessageType.error,
          );
        }
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) setState(() => _isScanning = true);
      }
    } catch (e) {
      if (mounted) {
        HelperUtils.showSnackBarMessage(
          context,
          "errorValidatingQR".translate(context),
          type: MessageType.error,
        );
      }
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _isScanning = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "scanQRCode".translate(context),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        leading: IconButton(
          icon: UiUtils.getSvg(
            AppIcons.arrowLeft,
            color: context.color.textDefaultColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: context.color.territoryColor.withOpacity(0.95),
      ),
      body: _isPermissionGranted
          ? Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            fit: BoxFit.cover,
          ),
          // Vignette overlay
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.8,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.6),
                ],
              ),
            ),
          ),
          Center(
            child: _ScannerFrame(
              glowAnimation: _glowAnimation,
            ),
          ),
          Positioned(
            top: 30,
            left: 0,
            right: 0,
            child: Text(
              "scanQRInstruction".translate(context),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildControlButton(
                  icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                  label: "Flash",
                  onTap: () {
                    setState(() {
                      _isFlashOn = !_isFlashOn;
                      _controller.toggleTorch();
                    });
                  },
                ),
                const SizedBox(width: 40),
                _buildControlButton(
                  icon: Icons.cameraswitch,
                  label: "Camera",
                  onTap: () {
                    setState(() {
                      _isFrontCamera = !_isFrontCamera;
                      _controller.switchCamera();
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      )
          : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 60,
              color: context.color.territoryColor,
            ),
            const SizedBox(height: 20),
            Text(
              "cameraPermissionRequired".translate(context),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: context.color.textDefaultColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.color.secondaryColor.withOpacity(0.95),
              shape: BoxShape.circle,
              border: Border.all(
                color: context.color.territoryColor.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: context.color.territoryColor,
              size: 30,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label.translate(context),
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 5,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScannerFrame extends StatelessWidget {
  final Animation<double> glowAnimation;

  const _ScannerFrame({
    required this.glowAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glowAnimation,
      builder: (context, _) {
        return Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.color.territoryColor.withOpacity(0.9),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: context.color.territoryColor.withOpacity(glowAnimation.value * 0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Corner indicators
              for (var alignment in [
                Alignment.topLeft,
                Alignment.topRight,
                Alignment.bottomLeft,
                Alignment.bottomRight,
              ])
                Align(
                  alignment: alignment,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: context.color.territoryColor.withOpacity(0.9),
                          width: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft ? 3 : 0,
                        ),
                        top: BorderSide(
                          color: context.color.territoryColor.withOpacity(0.9),
                          width: alignment == Alignment.topLeft || alignment == Alignment.topRight ? 3 : 0,
                        ),
                        right: BorderSide(
                          color: context.color.territoryColor.withOpacity(0.9),
                          width: alignment == Alignment.topRight || alignment == Alignment.bottomRight ? 3 : 0,
                        ),
                        bottom: BorderSide(
                          color: context.color.territoryColor.withOpacity(0.9),
                          width: alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight ? 3 : 0,
                        ),
                      ),
                    ),
                  ),
                ),
              // Scanning wave effect
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AnimatedBuilder(
                  animation: glowAnimation,
                  builder: (context, _) {
                    return Stack(
                      children: [
                        Positioned(
                          top: 0,
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  context.color.territoryColor.withOpacity(glowAnimation.value * 0.1),
                                  Colors.transparent,
                                  context.color.territoryColor.withOpacity(glowAnimation.value * 0.1),
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// HelperUtils class with both methods
class HelperUtils {
  static dynamic showSnackBarMessage(BuildContext context, String message,
      {int messageDuration = 3,
        MessageType? type,
        bool? isFloating,
        VoidCallback? onClose}) async {
    var snackBar = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: CustomText(message),
        behavior: (isFloating ?? false) ? SnackBarBehavior.floating : null,
        backgroundColor: type?.value,
        duration: Duration(seconds: messageDuration),
      ),
    );
    var snackBarClosedReason = await snackBar.closed;
    if (SnackBarClosedReason.values.contains(snackBarClosedReason)) {
      onClose?.call();
    }
  }

  static dynamic showSnackBarMessageWithAction(
      BuildContext context,
      String message, {
        int messageDuration = 3,
        MessageType? type,
        bool? isFloating,
        VoidCallback? onClose,
        String? actionLabel,
        VoidCallback? actionCallback,
      }) async {
    var snackBar = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: CustomText(message),
        behavior: (isFloating ?? false) ? SnackBarBehavior.floating : null,
        backgroundColor: type?.value,
        duration: Duration(seconds: messageDuration),
        action: actionLabel != null && actionCallback != null
            ? SnackBarAction(
          label: actionLabel,
          onPressed: actionCallback,
          textColor: Colors.white,
        )
            : null,
      ),
    );
    var snackBarClosedReason = await snackBar.closed;
    if (SnackBarClosedReason.values.contains(snackBarClosedReason)) {
      onClose?.call();
    }
  }
}