import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gpspro/Config.dart';
import 'package:gpspro/model/User.dart';
import 'package:gpspro/preference.dart';
import 'package:gpspro/services/APIService.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:gpspro/widgets/AlertDialogCustom.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

class SettingsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  User? user;
  SharedPreferences? prefs;

  final TextEditingController _newPassword = TextEditingController();
  final TextEditingController _retypePassword = TextEditingController();

  String? email;
  String? expirationDate;

  @override
  void initState() {
    super.initState();
    getUser();
    checkPreference();
  }

  void checkPreference() async {
    prefs = await SharedPreferences.getInstance();
  }

  getUser() async {
    final value = await API.getUserData();
    setState(() {
      user = value;
      email = value?.email;
      expirationDate = value?.expiration_date;
    });
  }

  logout() {
    prefs?.clear();
    Phoenix.rebirth(context);
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(('settings').tr())),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          ('settings').tr(),
          style: TextStyle(color: CustomColor.secondaryColor),
        ),
        iconTheme: IconThemeData(color: CustomColor.secondaryColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // PERFIL DEL USUARIO
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: CustomColor.primaryColor,
                          child: Icon(Icons.person,
                              size: 40, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user!.email ?? "-",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                              const SizedBox(height: 6),
                              Text("Plan: ${user!.plan ?? 'N/A'}"),
                              Text("Límite Dispositivos: ${user!.devices_limit ?? 0}"),
                              Text("Expira: ${user!.expiration_date ?? 'Sin vencimiento'}"),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        onPressed: logout,
                        child: Text(("logout").tr(),
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // OPCIONES
            Text(
              "Opciones",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: CustomColor.primaryColor,
              ),
            ),
            const SizedBox(height: 10),

            // --- CONTACTO ---
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ("support").tr(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: CustomColor.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        InkWell(
                          onTap: () =>
                              launchUrl(Uri.parse("https://wa.me/$WHATS_APP")),
                          child: CircleAvatar(
                            backgroundColor: Colors.green,
                            radius: 26,
                            child: FaIcon(FontAwesomeIcons.whatsapp,
                                color: Colors.white, size: 28),
                          ),
                        ),
                        InkWell(
                          onTap: () => launchUrl(Uri.parse("mailto:$EMAIL")),
                          child: CircleAvatar(
                            backgroundColor: Colors.blueAccent,
                            radius: 26,
                            child: Icon(Icons.mail,
                                color: Colors.white, size: 28),
                          ),
                        ),
                        //InkWell(
                        //  onTap: () => launchUrl(Uri.parse("tel:$PHONE_NO")),
                        //  child: CircleAvatar(
                        //    backgroundColor: Colors.orange,
                        //    radius: 26,
                        //    child: Icon(Icons.phone,
                        //        color: Colors.white, size: 28),
                        //  ),
                        //),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // CAMBIO DE CONTRASEÑA
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading:
                Icon(Icons.password, color: CustomColor.primaryColor),
                title: Text(("changePassword").tr()),
                trailing: Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey),
                onTap: () => changePasswordDialog(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void changePasswordDialog(BuildContext context) {
    bool isLoading = false;
    bool showPassword = false; // 👈 Controla si se muestra la contraseña

    final dialog = Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Container(
            height: 320,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: <Widget>[
                TextField(
                  controller: _newPassword,
                  obscureText: !showPassword, // 👈 cambia según el icono
                  decoration: InputDecoration(
                    labelText: 'Nueva contraseña',
                    suffixIcon: IconButton(
                      icon: Icon(
                        showPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          showPassword = !showPassword;
                        });
                      },
                    ),
                  ),
                ),
                TextField(
                  controller: _retypePassword,
                  obscureText: !showPassword,
                  decoration: InputDecoration(
                    labelText: 'Reingresa contraseña',
                    suffixIcon: IconButton(
                      icon: Icon(
                        showPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          showPassword = !showPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (isLoading) CircularProgressIndicator(),
                if (!isLoading)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () {
                          _newPassword.clear();
                          _retypePassword.clear();
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CustomColor.primaryColor,
                        ),
                        onPressed: () async {
                          if (_newPassword.text.isEmpty ||
                              _retypePassword.text.isEmpty) {
                            Navigator.of(context).pop();
                            _newPassword.clear();
                            _retypePassword.clear();
                            AlertDialogCustom().showAlertDialog(
                              context,
                              "La contraseña es requerida.",
                              "Cambio de contraseña",
                              "OK",
                            );
                            return;
                          }

                          if (_newPassword.text != _retypePassword.text) {
                            Navigator.of(context).pop();
                            _newPassword.clear();
                            _retypePassword.clear();
                            AlertDialogCustom().showAlertDialog(
                              context,
                              "Las contraseñas no coinciden. Verifica e intenta nuevamente.",
                              'Cambio de contraseña',
                              'OK',
                            );
                            return;
                          }

                          setState(() => isLoading = true);

                          try {
                            final response = await API.changePassword(
                              _newPassword.text,
                              _retypePassword.text,
                            );

                            String message;
                            if (response.statusCode == 200) {
                              message =
                              "Tu contraseña ha sido actualizada correctamente.";
                            } else {
                              try {
                                final decoded = jsonDecode(response.body);
                                message = decoded['message'] ??
                                    "No se pudo actualizar la contraseña. Intenta nuevamente más tarde.";
                              } catch (_) {
                                message =
                                "No se pudo actualizar la contraseña. Intenta nuevamente más tarde.";
                              }
                            }

                            _newPassword.clear();
                            _retypePassword.clear();
                            Navigator.of(context).pop();

                            AlertDialogCustom().showAlertDialog(
                              context,
                              message,
                              'Cambio de contraseña',
                              'OK',
                              onOk: () {
                                getUser();
                              },
                            );
                          } catch (e) {
                            _newPassword.clear();
                            _retypePassword.clear();
                            Navigator.of(context).pop();
                            AlertDialogCustom().showAlertDialog(
                              context,
                              "No se pudo actualizar la contraseña. Intenta nuevamente más tarde.",
                              'Cambio de contraseña',
                              'OK',
                            );
                          } finally {
                            setState(() => isLoading = false);
                          }
                        },
                        child: const Text(
                          'OK',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );

    showDialog(context: context, builder: (_) => dialog);
  }

}
