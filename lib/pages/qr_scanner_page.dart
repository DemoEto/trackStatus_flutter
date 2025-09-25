import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../routes/app_route.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _scanned = false; // กันซ้ำ

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MobileScanner(
        controller: _controller,
        onDetect: (capture) {
          if (_scanned) return; // กันซ้ำ
          _scanned = true;

          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            final String? code = barcode.rawValue;
            if (code != null) {
              // หยุดกล้องทันที
              _controller.stop();
              
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(code)),
              );
              if (code == "AppRoutes.qrCheckin") {
                // ไปหน้า /qrCheckin
                context.push(AppRoutes.qrCheckinScan);
              } 
              else {
                // ถ้าไม่เจอ path ให้แจ้งเตือนและไป home
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ไม่พบเส้นทาง ไปหน้าแรกแทน')),
                );
                context.go(AppRoutes.home); // ใช้ go() เพื่อ replace ไป home
              }
            }
          }
        },
      ),
    );
  }
}
