import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gpspro/theme/CustomColor.dart';

class MyMarker extends StatelessWidget {
  // declare a global key and get it trough Constructor

  MyMarker(this.globalKeyMyWidget);
  final GlobalKey globalKeyMyWidget;

  @override
  Widget build(BuildContext context) {
    // wrap your widget with RepaintBoundary and
    // pass your global key to RepaintBoundary
    dynamic _data;
    void setData(dynamic data) {
      // Update the state of the widget with the data.
        _data = data;
    }
    String value = '';

    void setValue(String newValue) {
        value = newValue;
    }

    return RepaintBoundary(
      key: globalKeyMyWidget,
      child: Column(
        children: [
          Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: CustomColor.primaryColor, width: 2),
              ),
              padding: EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 5),
                  Text(
                    "test",
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                      color: CustomColor.primaryColor
                    ),
                  ),
                ],
              )),
          Transform.rotate(
              angle: pi / 4, child:Transform.scale(
              scale: 2.0,
              child:Image.asset('assets/images/arrow-online.png',))),
        ],
      ),
    );
  }
}