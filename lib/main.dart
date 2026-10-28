import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';

void main() {
  runApp(const LocalPairApp());
}

class LocalPairApp extends StatelessWidget {
  const LocalPairApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local Duo Connect',
      theme: ThemeData.dark(useMaterial3: true),
      home: const ProfileSelectScreen(),
    );
  }
}

// 1. Simple Profile Selection (Only Tarsh & Friend)
class ProfileSelectScreen extends StatelessWidget {
  const ProfileSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Who is using this device?')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            ).wrap(
              ElevatedButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardScreen(myIdentity: 'Tarsh')),
                ),
                child: const Text('I am Tarsh (Galaxy Tab S11)', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DashboardScreen(myIdentity: 'Friend')),
              ),
              child: const Text('I am Friend (Lenovo Laptop)', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}

// 2. Dashboard for Local Chat & Connection
class DashboardScreen extends StatefulWidget {
  final String myIdentity;
  const DashboardScreen({super.key, required this.myIdentity});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _msgController = TextEditingController();
  List<String> messages = [];
  ServerSocket? _server;
  Socket? _connection;
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    _startLocalServer();
  }

  // Start a local TCP server on port 4040 so the other device can connect
  void _startLocalServer() async {
    try {
      _server = await ServerSocket.bind(InternetAddress.anyIPv4, 4040);
      _server!.listen((Socket client) {
        setState(() {
          _connection = client;
          isConnected = true;
        });
        client.listen((data) {
          String incoming = utf8.decode(data);
          setState(() {
            messages.add('Friend: $incoming');
          });
        });
      });
    } catch (e) {
      print('Server error: $e');
    }
  }

  // Connect to the other device using its local IP address
  void _connectToPeer(String ipAddress) async {
    try {
      Socket socket = await Socket.connect(ipAddress, 4040);
      setState(() {
        _connection = socket;
        isConnected = true;
      });
      socket.listen((data) {
        String incoming = utf8.decode(data);
        setState(() {
          messages.add('Friend: $incoming');
        });
      });
    } catch (e) {
      print('Connection failed: $e');
    }
  }

  void _sendMessage() {
    if (_msgController.text.isNotEmpty && _connection != null) {
      _connection!.write(_msgController.text);
      setState(() {
        messages.add('${widget.myIdentity}: ${_msgController.text}');
        _msgController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Logged in as: ${widget.myIdentity}')),
      body: Column(
        children: [
          if (!isConnected)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ipController,
                      decoration: const InputDecoration(
                        labelText: 'Enter Other Device Local IP (e.g. 192.168.x.x)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => _connectToPeer(_ipController.text),
                    child: const Text('Connect'),
                  ),
                ],
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Status: Connected Locally! 🎉', style: TextStyle(color: Colors.greenAccent)),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(messages[index]),
              ),
            ),
          ),
          if (isConnected)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: const InputDecoration(hintText: 'Type offline message...'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blueAccent),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
