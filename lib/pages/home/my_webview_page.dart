import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class MyWebViewPage extends StatefulWidget {
  const MyWebViewPage({super.key});

  @override
  State<MyWebViewPage> createState() => _MyWebViewPageState();
}

class _MyWebViewPageState extends State<MyWebViewPage> {
  late final WebViewController webViewController;

  @override
  void initState() {
    super.initState();

    // สร้าง parameter ที่รองรับได้ทั้ง iOS และ Android
    PlatformWebViewControllerCreationParams params =
        const PlatformWebViewControllerCreationParams();

    late final PlatformWebViewControllerCreationParams finalParams;

    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      // ถ้าเป็น iOS
      finalParams =
          WebKitWebViewControllerCreationParams.fromPlatformWebViewControllerCreationParams(
            params,
          );
    } else if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      // ถ้าเป็น Android
      finalParams =
          AndroidWebViewControllerCreationParams.fromPlatformWebViewControllerCreationParams(
            params,
          );
    } else {
      finalParams = params;
    }

    // สร้าง WebViewController
  webViewController = WebViewController.fromPlatformCreationParams(finalParams)
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (url) {
          // inject JavaScript เพื่อลบ cookie popup
          webViewController.runJavaScript('''
            var cookieBanner = document.querySelector(".cookie-banner, .cookie-consent, #cookie-popup");
            if (cookieBanner) {
              cookieBanner.style.display = "none";
            }
          ''');
        },
      ),
    )
    ..loadRequest(Uri.parse('https://www.rmutl.ac.th/'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('หน้าเว็บไซต์')),
      body: WebViewWidget(controller: webViewController),
    );
  }
}
