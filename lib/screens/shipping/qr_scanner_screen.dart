import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shopsnports/core/theme/app_colors.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  bool _hasScanned = false;
  String? _lastScanned;
  bool _torchEnabled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_hasScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final String? code = barcode.rawValue;

    if (code == null || code.isEmpty || code == _lastScanned) return;

    setState(() {
      _hasScanned = true;
      _lastScanned = code;
    });

    // Process the scanned code
    _processScannedCode(code);
  }

  void _processScannedCode(String code) {
    // Check if it's a tracking number pattern
    // Common patterns: SHP-XXXXX, TRK-XXXXX, or numeric codes
    final trackingPatterns = [
      RegExp(r'^(SHP|TRK|SHIP|TRACK)-?[A-Z0-9]{6,20}$', caseSensitive: false),
      RegExp(r'^[A-Z0-9]{8,20}$', caseSensitive: false),
      RegExp(r'^\d{10,20}$'), // Pure numeric like 1234567890
    ];

    bool isTracking = false;
    for (final pattern in trackingPatterns) {
      if (pattern.hasMatch(code.trim())) {
        isTracking = true;
        break;
      }
    }

    // Check if it's a deep link (contains :// or myapp://)
    final isDeepLink = code.contains('://') || code.startsWith('myapp://');

    if (isTracking) {
      // Return the tracking number
      Navigator.pop(context, {'type': 'tracking', 'code': code.trim()});
    } else if (isDeepLink) {
      // Return the deep link for processing
      Navigator.pop(context, {'type': 'deeplink', 'code': code.trim()});
    } else {
      // General QR code - return as-is
      Navigator.pop(context, {'type': 'general', 'code': code.trim()});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR/Barcode'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _torchEnabled ? Icons.flash_on : Icons.flash_off,
            ),
            onPressed: () {
              _controller.toggleTorch();
              setState(() => _torchEnabled = !_torchEnabled);
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcode,
          ),
          // Overlay with scanning frame
          CustomPaint(
            painter: _ScannerOverlayPainter(),
            child: const SizedBox.expand(),
          ),
          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Position the QR code or barcode within the frame',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          // Manual entry button
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.keyboard, color: Colors.white),
                label: const Text(
                  'Enter manually',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double scanAreaSize = size.width * 0.7;
    final double left = (size.width - scanAreaSize) / 2;
    final double top = (size.height - scanAreaSize) / 2;
    final double right = left + scanAreaSize;
    final double bottom = top + scanAreaSize;

    // Draw darkened overlay outside scan area
    final Paint darkPaint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    // Top
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, top), darkPaint);
    // Bottom
    canvas.drawRect(Rect.fromLTRB(0, bottom, size.width, size.height), darkPaint);
    // Left
    canvas.drawRect(Rect.fromLTRB(0, top, left, bottom), darkPaint);
    // Right
    canvas.drawRect(Rect.fromLTRB(right, top, size.width, bottom), darkPaint);

    // Draw scan area border
    final Paint borderPaint = Paint()
      ..color = AppColors.accentYellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final RRect scanArea = RRect.fromLTRBR(left, top, right, bottom, const Radius.circular(12));
    canvas.drawRRect(scanArea, borderPaint);

    // Draw corner accents
    final Paint cornerPaint = Paint()
      ..color = AppColors.accentYellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    const double cornerLength = 30;

    // Top-left corner
    canvas.drawLine(Offset(left, top + cornerLength), Offset(left, top), cornerPaint);
    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), cornerPaint);

    // Top-right corner
    canvas.drawLine(Offset(right - cornerLength, top), Offset(right, top), cornerPaint);
    canvas.drawLine(Offset(right, top), Offset(right, top + cornerLength), cornerPaint);

    // Bottom-left corner
    canvas.drawLine(Offset(left, bottom - cornerLength), Offset(left, bottom), cornerPaint);
    canvas.drawLine(Offset(left, bottom), Offset(left + cornerLength, bottom), cornerPaint);

    // Bottom-right corner
    canvas.drawLine(Offset(right - cornerLength, bottom), Offset(right, bottom), cornerPaint);
    canvas.drawLine(Offset(right, bottom - cornerLength), Offset(right, bottom), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
