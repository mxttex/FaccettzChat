import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

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
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
          useMaterial3: true),
      home: const MyHomePage(title: 'chat'),
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
  final _user = const types.User(id: 'aaaa');

  @override
  void initState() {
    super.initState();
    //_loadMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    final textMessage = types.TextMessage(author: _user, id: const Uuid().v4(), text: message.text, createdAt: DateTime.now().microsecondsSinceEpoch);
    addMessage(textMessage);
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

  void addMessage(types.Message message){
    setState(() {
      _messages.insert(0, message);
    });
  }
}
