import 'package:flutter/material.dart';
import 'package:gpspro/theme/CustomColor.dart';

class MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Function onTap;

  const MenuItem({Key? key, required this.icon, required this.title, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap as void Function()?,
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, color: CustomColor.primaryColor,),
            SizedBox(height: 4.0),
            Text(title, style: TextStyle(fontSize: 11, color: CustomColor.primaryColor),),
          ],
        ),
      ),
    );
  }
}