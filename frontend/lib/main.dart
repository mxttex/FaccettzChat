import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';
import 'package:intl/date_symbol_data_local.dart';
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
  dynamic _preview = [];
  States _state = States.login;
  bool logged = false;
  late IO.Socket socket;
  final StreamController<String> _streamController = StreamController<String>();
  Stream<String> get messageStream => _streamController.stream;
  dynamic otherUserId;
  dynamic dynMessages;

  @override
  void initState() {
    super.initState();

    socket = IO.io("http://192.168.0.124:3000", <String, dynamic>{
      "transports": ['websocket']
    });
    _loggati();
    _loadFile();

    socket.on('connect', (_) {
      setState(() {});
    });

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
            _user = types.User(
                id: user.uid,
                firstName: user.displayName,
                imageUrl: user.photoURL);
            socket.emit("join-my-room", _user.id);
            _state = States.menu;
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
    switch (_state) {
      case States.login:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SignInButton(Buttons.Google, onPressed: _loggati),
          ],
        );
      case States.menu:
        _preview = _createPreview();
        return Center(
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 5),
            itemCount: _preview.length,
            itemBuilder: (context, index) {
              final message = _preview[index] as types.TextMessage;

              return GestureDetector(
                  onTap: () {
                    setState(() {
                      try {
                        _state = States.inChat;
                        otherUserId = message.author.id;
                      } catch (e) {
                        _showAlert(context, "title", e.toString(), false);
                      }
                    });
                  },
                  child: SizedBox(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 15),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          UserAvatar(imageUrl: message.author.imageUrl ?? ""),
                          const SizedBox(width: 10),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Nome dell'autore
                                Text(
                                  message.author.firstName ?? "Unknown",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 3),

                                Text(
                                  message.text,
                                  style: const TextStyle(
                                      color: Colors.black, fontSize: 14),
                                ),
                              ],
                            ),
                          ),

                          // Data del messaggio
                          Text(
                            _showDate(message.createdAt),
                            style: const TextStyle(
                                color: Colors.black, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ));
            },
          ),
        );

      case States.inChat:
        dynMessages = _loadMessagesWithIds();

        socket.emit("join-room", otherUserId ?? "broadcast");
        return Chat(
          messages: dynMessages,
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
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () => {_state = States.inChat},
      //   child: const Icon(Icons.message),
      // )
    );
  }

  void _handleSendPress(types.PartialText message) {
    if (message.text == "/logout") {
      _logout();
    } else if (socket.connected) {
      if (message.text.startsWith("/back")) {
        // socket.emit("join-room", message.text.substring(5));
        socket.emit("leave-room");
        setState(() {
          _state = States.menu;
        });
      } else {
        final textMessage = types.TextMessage(
            author: _user,
            id: const Uuid().v4(),
            text: message.text,
            createdAt: DateTime.now().millisecondsSinceEpoch,
            roomId: otherUserId);

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
        _preview = _createPreview();
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

  String _showDate(int? milliseconds) {
    if (milliseconds != null) {
      final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);
      if (date.toString().substring(0, 10) ==
          DateTime.now().toString().substring(0, 10)) {
        return date.toString().substring(11, 16);
      } else {
        return date.toString().substring(0, 10);
      }
    } else {
      return "unknown";
    }
  }

  List<dynamic> _createPreview() {
    List<dynamic> prev = [];

    if (_messages.isNotEmpty) {
      for (int i = 0; i < _messages.length; i++) {
        final message = _messages[i];
        if (message.author.id != _user.id &&
            !prev.any((msg) => msg.author.id == message.author.id)) {
          setState(() {
            prev.add(message);
          });
        }
      }
    } else {
      setState(() {
        _state = States.inChat;
      });
    }
    return prev;
  }

  List<types.Message> _loadMessagesWithIds() {
  return _messages.where((message) {
    return (message.roomId == otherUserId || message.author.id == otherUserId);
  }).toList();
}
}

class UserAvatar extends StatelessWidget {
  final String imageUrl;
  final double radius;

  const UserAvatar({super.key, required this.imageUrl, this.radius = 32});

  @override

//codice generato da AI, molto probabilmente da sistemare
  Widget build(BuildContext context) {
    return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white, // Bordo bianco attorno all'immagine
        child: CircleAvatar(
          radius: radius - 3, // Ridotto per il bordo
          backgroundImage: imageUrl.startsWith('http')
              ? NetworkImage(imageUrl) // Se è un URL, carica da internet
              : AssetImage('assets/images/$imageUrl') as ImageProvider,
          onBackgroundImageError: (_, __) => const Icon(Icons.person, size: 30),
        ));
  }
}
