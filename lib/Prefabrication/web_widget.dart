part of 'prefabrication.dart';

/// templete
/// ```{
///   "url" : "https:///xxxx",
///   "title": "网页名字"
/// }```
class WebWidget extends StatefulWidget {
  final String url;
  final String title;

  const WebWidget({super.key, required this.url, required this.title});

  @override
  State<WebWidget> createState() => WebWidgetState();
}

class WebWidgetState extends State<WebWidget> {
  InAppWebViewController? webViewController;
  bool loadFailed = false;

  @override
  void dispose() {
    webViewController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_outlined, color: Colors.lightBlue),
        ),
        title: Text(widget.title),
      ),
      body: loadFailed
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 12),
            const Text(
              "网页无法访问",
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  loadFailed = false;
                });
                webViewController?.reload();
              },
              child: const Text("重试"),
            ),
          ],
        ),
      )
          : InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(widget.url)),
        onWebViewCreated: (controller) {
          webViewController = controller;
        },
        onLoadStart: (controller, url) {
          debugPrint("开始加载: $url");
        },
        onLoadStop: (controller, url) async {
          debugPrint("加载完成: $url");
        },
        onLoadError: (controller, url, code, message) {
          debugPrint("加载失败: $url, code: $code, msg: $message");
          setState(() {
            loadFailed = true;
          });
        },
        onLoadHttpError: (controller, url, statusCode, description) {
          debugPrint("HTTP 错误: $url, code: $statusCode");
          setState(() {
            loadFailed = true;
          });
        },
        initialSettings: InAppWebViewSettings(
          cacheEnabled: true,
          clearCache: false,
        ),
      ),
    );
  }
}