import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:cool_alert/cool_alert.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() {
  initializeDateFormatting().then(
    (_) => runApp(
      const SimpleChat(),
    ),
  );
}

class SimpleChat extends StatelessWidget {
  const SimpleChat({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Faccettz Chat",
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true),
      home: const MyHomePage(title: 'FACCETTZ CHAT'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<types.Message> _messages = [];
  dynamic _path;
  dynamic _user;
  File? _messagesFile = null;

  late IO.Socket socket;
  final StreamController<String> _streamController = StreamController<String>();
  Stream<String> get messageStream => _streamController.stream;

  @override
  void initState() {
    super.initState();
    socket = IO.io("http://192.168.0.124:3000", <String, dynamic>{
      "transports": ['websocket']
    });
    //_loadUser();
    _user =
        const types.User(id: "id", firstName: "Matteo", lastName: "Faccetta");
    _loadFile();

    socket.on('connect', (_) {
      setState(() {
        // errorMessage = "connesso al server";
      });
    });

    socket.on('message', (data) {
      final message = data;
      final textMessage = types.TextMessage(
        author: types.User.fromJson(message['author']),
        id: message['id'],
        text: message['text'],
        createdAt: message['createdAt'],
      );
      // _streamController.add(data.toString());
      addMessage(textMessage, false);
    });
  }

  Future<void> _loadUser() async {
    // final response = await rootBundle.loadString('assets/user.json');
    // final us = jsonDecode(response);
    // _user = types.User(
    //     id: us['id']!, firstName: us['firstName'], lastName: us['lastName']);
    _user =
        const types.User(id: "id", firstName: "Matteo", lastName: "Faccetta");
  }

  Future<void> _loadFile() async {
    //await _loadUser();
    _path = await _getFilePath();
    _messagesFile = File(_path);
    final exists = await _messagesFile!.exists();
    if (exists) {
      loadMessages();
    } else {
      _messagesFile!.create();
    }
  }

    @override
    Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Chat(
        messages: _messages,
        onSendPressed: _handleSendPress,
        user: _user,
        onPreviewDataFetched: _handlePreviewDataFetched,
        showUserAvatars: true,
        showUserNames: true,
        theme: const DefaultChatTheme(
            seenIcon: Text('read', style: TextStyle(fontSize: 10.0))),
      ),
    );
  }

  void _handleSendPress(types.PartialText message) {
    final textMessage = types.TextMessage(
        author: _user,
        id: const Uuid().v4(),
        text: message.text,
        createdAt: DateTime.now().millisecondsSinceEpoch);
    addMessage(textMessage, true);
  }

  void _handlePreviewDataFetched(
      types.TextMessage message, types.PreviewData previewData) {
    final index = _messages.indexWhere((element) => element.id == message.id);
    final updatedMessage = (_messages[index] as types.TextMessage)
        .copyWith(previewData: previewData);

    setState(() {
      _messages[index] = updatedMessage;
    });
  }

  void addMessage(types.Message message, mode) async {
    if (!_messages.any((msg) => msg.id == message.id)) {
      setState(() {
        _messages.insert(0, message);
      });
    }

    //se la modalità è true allora invia il messaggio
    if (mode) _sendMessage(message);

    await _fileWriter();
  }

  void _sendMessage(data) async {
    if (socket.connected) {
      socket.emit('sendMessage', data);
    }
  }

  Future<void> _fileWriter() async {
    final stringToEncode = jsonEncode(_messages);
    await _messagesFile!.writeAsString(stringToEncode);
  }

  void loadMessages() async {
    final response = await _messagesFile!.readAsString();
    final messages = (jsonDecode(response) as List)
        .map((e) => types.Message.fromJson(e as Map<String, dynamic>))
        .toList();

    setState(() {
      _messages = messages;
    });
  }

  Future<String> _getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/messages.json';
  }

//per debug
  void _showAlert(
      BuildContext context, String title, String content, bool mode) {
    CoolAlert.show(
      context: context,
      type: mode ? CoolAlertType.success : CoolAlertType.error,
      title: title,
      text: content,
      loopAnimation: false,
    );
  }
}
