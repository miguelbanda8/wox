import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gpspro/Config.dart';
import 'package:gpspro/model/About.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AboutPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  List<AboutModel> aboutList = [];

  @override
  void initState() {
    super.initState();
    if (aboutList.isEmpty) {
      aboutList.add(AboutModel(("termsAndCondition").tr(), TERMS_AND_CONDITIONS));
      aboutList.add(AboutModel(("privacyPolicy").tr(), PRIVACY_POLICY));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("about".tr()),
        backgroundColor: CustomColor.primaryColor,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Encabezado con logo y nombre de la app
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'images/logo.png',
                    height: 100.0,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: 10)
              ],
            ),
          ),
          SizedBox(height: 12),
          Expanded(
            child: aboutList.isNotEmpty
                ? _loadList()
                : Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }

  Widget _loadList() {
    return ListView.builder(
      itemCount: aboutList.length,
      itemBuilder: (context, index) {
        final urlItem = aboutList[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: _itemCard(urlItem),
        );
      },
    );
  }

  Widget _itemCard(AboutModel aboutItem) {
    IconData leadingIcon;

    final titleLower = (aboutItem.title ?? '').toLowerCase();
    if (titleLower.contains("terms") || titleLower.contains("términos")) {
      leadingIcon = Icons.article_outlined;
    } else if (titleLower.contains("privacy") || titleLower.contains("privacidad")) {
      leadingIcon = Icons.privacy_tip_outlined;
    } else {
      leadingIcon = Icons.link;
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Abrimos SIEMPRE el WebView interno
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WebViewPage(
                title: aboutItem.title ?? '',
                url: aboutItem.url ?? '',
              ),
            ),
          );
        },
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: CustomColor.primaryColor.withOpacity(0.1),
            child: Icon(leadingIcon, color: CustomColor.primaryColor),
          ),
          title: Text(
            aboutItem.title ?? '',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ),
      ),
    );
  }
}

// ---------------------------------------------
// PÁGINA DE WEBVIEW INTERNA
// ---------------------------------------------
class WebViewPage extends StatefulWidget {
  final String title;
  final String url;

  const WebViewPage({Key? key, required this.title, required this.url}) : super(key: key);

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("No se pudo cargar el contenido.")),
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
        backgroundColor: CustomColor.primaryColor,
        actions: [
          IconButton(
            tooltip: "Recargar",
            icon: Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            LinearProgressIndicator(minHeight: 2),
        ],
      ),
    );
  }
}
