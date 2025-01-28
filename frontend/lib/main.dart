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
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  initializeDateFormatting().then(
    (_) => runApp(const SimpleChat()),
  );
}

enum States { login, menu, inChat }

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
  States _status = States.login;
  bool logged = false;
  late IO.Socket socket;
  final StreamController<String> _streamController = StreamController<String>();
  Stream<String> get messageStream => _streamController.stream;

  @override
  void initState() {
    super.initState();

    socket = IO.io("http://192.168.0.187:3000", <String, dynamic>{
      "transports": ['websocket']
    });
    _loadFile();
    _loggati();

    socket.on('connect', (_) {
      setState(() {});
    });
    socket.emit("join-room", "broadcast");

    socket.on('message', (data) {
      final message = data;
      final textMessage = types.TextMessage(
        author: types.User.fromJson(message['author']),
        id: message['id'],
        text: message['text'],
        createdAt: message['createdAt'],
      );
      setState(() {
        addMessage(textMessage, false);
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    socket.disconnect();
    _streamController.close();
  }

  void _assignUser(User user) {
    _user = types.User(id: user.uid, firstName: user.displayName);
  }

  Future<void> _loggati() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
        UserCredential userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
        User? user = userCredential.user;
        if (user != null) {
          setState(() {
            _assignUser(user);
            _status = States.inChat;
          });
        }
      }
    } catch (e) {
      setState(() {
        if (mounted) {
          _showAlert(context, "Errore", e.toString(), false);
        }
      });
    }
  }

  Future<void> _logout() async {
    try {
      await GoogleSignIn().signOut();
      setState(() {
        _user = null;
        logged = false;
      });
    } catch (e) {
      setState(() {
        _showAlert(context, "Errore", e.toString(), false);
      });
    }
  }

  Future<void> _loadFile() async {
    _path = await _getFilePath();
    _messagesFile = File(_path);
    final exists = await _messagesFile!.exists();
    if (exists) {
      loadMessages();
    } else {
      _messagesFile!.create();
    }
  }

  Widget _buildBody() {
    switch (_status) {
      case States.login:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SignInButton(Buttons.Google, onPressed: _loggati),
          ],
        );
      case States.menu:
  return Center(
    child: ListView.builder(
      padding: const EdgeInsets.only(left: 25),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index] as types.TextMessage;

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 50),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.author.firstName ?? "Unknown",
                              style: const TextStyle(color: Colors.black),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              message.text,
                              style: const TextStyle(color: Colors.black),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          DateTime.fromMicrosecondsSinceEpoch(
                                  message.createdAt ?? 0)
                              .toString(),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const Divider(indent: 75),
          ],
        );
      },
    ),
  );

      case States.inChat:
        return Chat(
          messages: _messages,
          onSendPressed: _handleSendPress,
          user: _user,
          onPreviewDataFetched: _handlePreviewDataFetched,
          showUserAvatars: true,
          showUserNames: true,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _buildBody(),
    );
  }

  void _handleSendPress(types.PartialText message) {
    if (message.text == "/logout") {
      _logout();
    } else if (socket.connected) {
      if (message.text.startsWith("/room")) {
        socket.emit("join-room", message.text.substring(5));
      } else {
        final textMessage = types.TextMessage(
            author: _user,
            id: const Uuid().v4(),
            text: message.text,
            createdAt: DateTime.now().millisecondsSinceEpoch);
        addMessage(textMessage, true);
      }
    }
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
