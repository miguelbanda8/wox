import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:downloads_path_provider_28/downloads_path_provider_28.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gpspro/arguments/ReportArguments.dart';
import 'package:gpspro/services/APIService.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class ReportFuelPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _ReportFuelPageState();
}

class _ReportFuelPageState extends State<ReportFuelPage> {
  static ReportArguments? args;
  StreamController<int>? _postsController;
  Timer? _timer;
  Timer? _timer2;
  bool isLoading = true;
  static var httpClient = new HttpClient();
  File? file;
  late WebViewController _controller;
  String? url;

  @override
  void initState() {
    _postsController = new StreamController();
    getReport();
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
    WebViewController.fromPlatformCreationParams(params);
    // #enddocregion platform_features

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('WebView is loading (progress : $progress%)');
          },
          onPageStarted: (String url) {
            debugPrint('Page started loading: $url');
          },
          onPageFinished: (String url) {
            debugPrint('Page finished loading: $url');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}
          ''');
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              debugPrint('blocking navigation to ${request.url}');
              return NavigationDecision.prevent;
            }
            debugPrint('allowing navigation to ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'Toaster',
        onMessageReceived: (JavaScriptMessage message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        },
      );

    // #docregion platform_features
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
    // #enddocregion platform_features

    _controller = controller;
    setState(() {

    });
    super.initState();
  }

  Future<File?> _downloadFile(String url, String filename) async {
    Random random = new Random();
    int randomNumber = random.nextInt(100);
    var request = await httpClient.getUrl(Uri.parse(url));
    var response = await request.close();
    var bytes = await consolidateHttpClientResponseBytes(response);
    String dir = (await getApplicationDocumentsDirectory()).path;
    File pdffile = new File('$dir/$filename-$randomNumber.html');
    //Navigator.pop(context); // Load from assets
    file = pdffile;
    await file!.writeAsBytes(bytes);
    _loadHtmlFromAssets();
    return file;
  }

  getReport() {
    _timer = new Timer.periodic(Duration(seconds: 1), (timer) {
      if (args != null) {
        timer.cancel();
        API.getReportHtml(
                args!.id.toString(), args!.fromDate, args!.toDate, args!.type)
            .then((value) => {
              url = value!.url,
              _downloadFile(value.url!, "work"),
            });
      }
    });
  }

  downloadReport(String url, String filename) async{
    Random random = new Random();
    int randomNumber = random.nextInt(100);
    print(url);
    if (url != null) {
      var request = await httpClient.getUrl(Uri.parse(url));
      var response = await request.close();
      var bytes = await consolidateHttpClientResponseBytes(response);
      writeFile(bytes, filename+DateTime.now().millisecond.toString()+".pdf");
      _postsController!.add(1);
      await file!.writeAsBytes(bytes);
      Fluttertoast.showToast(
          msg: ("excelDownloaded").tr(),
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black54,
          textColor: Colors.white,
          fontSize: 16.0);
      return file;
    } else {
      isLoading = false;
      _postsController!.add(0);
      setState(() {});
    }
  }

  Future<void> writeToFile(Uint8List data, String path) {
    final buffer = data.buffer;
    return new File(path).writeAsBytes(
        buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }

  Future<File> writeFile(Uint8List data, String name) async {
    // storage permission ask
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
    // the downloads folder path
    Directory? tempDir = await DownloadsPathProvider.downloadsDirectory;
    String tempPath = tempDir!.path;
    var filePath = tempPath + '/$name';
    //

    // the data
    var bytes = ByteData.view(data.buffer);
    final buffer = bytes.buffer;
    // save the data in the path
    return File(filePath).writeAsBytes(buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }

  _loadHtmlFromAssets() async {
    setState(() {
      isLoading = false;
      _postsController!.add(1);
    });
    String fileHtmlContents = await file!.readAsString();

    _controller.loadHtmlString(Uri.dataFromString(fileHtmlContents,
        mimeType: 'text/html', encoding: Encoding.getByName('utf-8'))
        .toString());
  }

  @override
  void dispose() {
    _timer!.cancel();
    _timer2!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    args = ModalRoute.of(context)!.settings.arguments as ReportArguments;

    return Scaffold(
        appBar: AppBar(
          title: Text(args!.name,
              style: TextStyle(color: CustomColor.secondaryColor)),
          iconTheme: IconThemeData(
            color: CustomColor.secondaryColor, //change your color here
          ),
        ),
        floatingActionButton: new FloatingActionButton(
          child: const Icon(Icons.download_rounded),
          elevation: 0,
          onPressed: () {
            downloadReport(url!, "work");
          },
        ),
        body: StreamBuilder<int>(
            stream: _postsController!.stream,
            builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
              if (snapshot.data == 1) {
               return WebViewWidget(controller: _controller!);
              } else if (isLoading) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              } else if (snapshot.data == 0) {
                return Center(
                  child: Text(('noData')),
                );
              } else {
                return Center(
                  child: Text(('noData')),
                );
              }
            }));;
  }
}
