import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:downloads_path_provider_28/downloads_path_provider_28.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gpspro/arguments/ReportArguments.dart';
import 'package:gpspro/services/APIService.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class ReportRoutePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _ReportRoutePageState();
}

class _ReportRoutePageState extends State<ReportRoutePage> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  static ReportArguments? args;
  StreamController<int>? _postsController;
  Timer? _timer;
  bool isLoading = true;
  static var httpClient = new HttpClient();
  File? file;
  String? url;

  @override
  void initState() {
    _postsController = new StreamController();
    getReport();
    super.initState();
  }

  getReport() {
    _timer = new Timer.periodic(Duration(seconds: 1), (timer) {
      if (args != null) {
        timer.cancel();
        API.getReport(
                args!.id.toString(), args!.fromDate, args!.toDate, args!.type)
            .then((value) => {
                  url = value!.url,
                  _downloadFile(value.url!, "general")
                  // launch(value.url),
                  //
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
      // String dir = (await getApplicationDocumentsDirectory()).path;
      // File pdffile = new File('$dir/$filename-$randomNumber.pdf');
      // //Navigator.pop(context); // Load from assets
      // file = pdffile;
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

  Future<File?> _downloadFile(String url, String filename) async {
    Random random = new Random();
    int randomNumber = random.nextInt(100);
    var request = await httpClient.getUrl(Uri.parse(url));
    var response = await request.close();
    var bytes = await consolidateHttpClientResponseBytes(response);
    String dir = (await getApplicationDocumentsDirectory()).path;
    print(dir);
    File pdffile = new File('$dir/$filename-$randomNumber.pdf');
    //Navigator.pop(context); // Load from assets
    file = pdffile;
    _postsController!.add(1);
    await file!.writeAsBytes(bytes);
    return file;
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

  @override
  Widget build(BuildContext context) {
    args = ModalRoute.of(context)!.settings.arguments as ReportArguments;
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              title: Text(
                args!.name,
                style: TextStyle(color: CustomColor.secondaryColor),
                overflow: TextOverflow.ellipsis,
              ),
              iconTheme: IconThemeData(
                color: CustomColor.secondaryColor, //change your color here
              ),
            ),
            floatingActionButton: new FloatingActionButton(
              child: const Icon(Icons.download_rounded),
              elevation: 0,
              onPressed: () {
                downloadReport(url!, "general");
              },
            ),
            body: loadReport()));
  }

  Widget loadReport() {
    return StreamBuilder<int>(
        stream: _postsController!.stream,
        builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
          if (snapshot.hasData) {
            return SfPdfViewer.file(
              file!,
              key: _pdfViewerKey,
            );
          } else if (isLoading) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else {
            return Center(
              child: Text(('noData')),
            );
          }
        });
  }
}
