// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_chat_ui/flutter_chat_ui.dart';
// import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
// import 'package:uuid/uuid.dart';
// import 'package:is_valid/is_valid.dart';
// import 'package:intl/date_symbol_data_local.dart';
// import 'dart:convert';
// import 'package:path_provider/path_provider.dart';
// import 'dart:io';
// import 'package:cool_alert/cool_alert.dart';
// import 'package:socket_io_client/socket_io_client.dart' as IO;
// import 'package:flutter_signin_button/flutter_signin_button.dart';
// import 'firebase_options.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:faccettz_chat/main.dart';

//   Future<void> _loadFile() async {
//     _path = await _getFilePath();
//     _messagesFile = File(_path);
//     final exists = await _messagesFile!.exists();
//     if (exists) {
//       loadMessages();
//     } else {
//       _messagesFile!.create();
//     }
//   }