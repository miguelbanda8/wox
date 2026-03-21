import 'package:gpspro/model/Command.dart';

class GetCommands extends Object {
  Map<String, Command>? commands;

  GetCommands({this.commands});

  GetCommands.fromJson(Map<String, dynamic> json) {
    commands = json["commands"];
  }
}
