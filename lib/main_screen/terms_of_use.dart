import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TermsOfUse extends StatefulWidget {
  const TermsOfUse({Key? key}) : super(key: key);

  @override
  _TermsOfUseState createState() => _TermsOfUseState();
}

class _TermsOfUseState extends State<TermsOfUse> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF6F4F5))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // You can use this to update a loading indicator if desired
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            // Prevent YouTube navigation as an example
            if (request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(
        Uri.parse('https://www.heartfulnessinstitute.org/terms-of-use/'),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4F5),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(15, 40, 15, 15),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Color(0xFF485370),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    'Terms and Conditions',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF485370),
                      fontSize: 28,
                      fontFamily: 'WorkSans',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(width: 30),
              ],
            ),
            const SizedBox(height: 5),
            const Divider(color: Color(0xFF485370)),
            Expanded(
              child: WebViewWidget(controller: _controller),
            ),
          ],
        ),
      ),
    );
  }
}
