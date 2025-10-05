import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:html';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TimerApp(),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
    );
  }
}

class TimerApp extends StatefulWidget {
  @override
  _TimerAppState createState() => _TimerAppState();
}

class GraphNode {
  final String id;
  final String title;
  final String content;
  final String type; // 'discussione' or 'codice'
  final DateTime created;
  List<String> connectedTo;

  GraphNode({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.created,
    List<String>? connectedTo,
  }) : connectedTo = connectedTo ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'type': type,
        'created': created.toIso8601String(),
        'connectedTo': connectedTo,
      };
}

class _TimerAppState extends State<TimerApp> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _timeController = TextEditingController(text: "1");
  List<String> _friends = ['Amico 1', 'Amico 2', 'Amico 3'];
  List<String> _selectedFriends = [];
  List<Map<String, String>> _messages = [];
  String? _selectedFileUrl;
  int _remainingSeconds = 60;
  Timer? _timer;
  
  // Cervello Grafologico - Graph Theory based knowledge system
  List<GraphNode> _knowledgeGraph = [];
  bool _showGraphInterface = false;
  final TextEditingController _nodeTitle = TextEditingController();
  final TextEditingController _nodeContent = TextEditingController();
  String _nodeType = 'discussione';

  void _startCountdown() {
    int? customMinutes = int.tryParse(_timeController.text);
    if (customMinutes != null && customMinutes > 0) {
      setState(() {
        _remainingSeconds = customMinutes * 60;
      });
    }

    if (_timer != null && _timer!.isActive) return;
    final String title = _titleController.text;

    if (_selectedFriends.isNotEmpty) {
      _sendTimerToFriends(title);
    }

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _stopCountdown();
          _playNotificationSound();
          _sendMessageToFriends();
        }
      });
    });
  }

  void _stopCountdown() {
    _timer?.cancel();
  }

  void _resetCountdown() {
    _stopCountdown();
    setState(() {
      _remainingSeconds = 60;
    });
  }

  String _formatTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _uploadFile() {
    FileUploadInputElement uploadInput = FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      final file = uploadInput.files?.first;
      if (file != null) {
        final reader = FileReader();
        reader.readAsDataUrl(file);
        reader.onLoadEnd.listen((e) {
          setState(() {
            _selectedFileUrl = reader.result as String?;
          });
        });
      }
    });
  }

  void _sendTimerToFriends(String title) {
    for (var friend in _selectedFriends) {
      setState(() {
        _messages.add({
          'to': friend,
          'title': title,
          'type': 'Timer Avviato'
        });
      });
    }
  }

  void _sendMessageToFriends() {
    final String message = _messageController.text;
    for (var friend in _selectedFriends) {
      setState(() {
        _messages.add({
          'to': friend,
          'message': message,
          'type': 'Countdown Finito'
        });
      });
    }
  }

  void _playNotificationSound() {
    AudioElement sound = AudioElement('https://www.soundjay.com/button/beep-07.wav');
    sound.play();
  }

  void _toggleGraphInterface() {
    setState(() {
      _showGraphInterface = !_showGraphInterface;
    });
  }

  void _addGraphNode() {
    if (_nodeTitle.text.isEmpty || _nodeContent.text.isEmpty) return;
    
    setState(() {
      _knowledgeGraph.add(GraphNode(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _nodeTitle.text,
        content: _nodeContent.text,
        type: _nodeType,
        created: DateTime.now(),
      ));
      _nodeTitle.clear();
      _nodeContent.clear();
    });
  }

  void _deleteGraphNode(String id) {
    setState(() {
      _knowledgeGraph.removeWhere((node) => node.id == id);
      // Remove connections to this node
      for (var node in _knowledgeGraph) {
        node.connectedTo.remove(id);
      }
    });
  }

  void _connectNodes(String fromId, String toId) {
    setState(() {
      final fromNode = _knowledgeGraph.firstWhere((n) => n.id == fromId);
      if (!fromNode.connectedTo.contains(toId)) {
        fromNode.connectedTo.add(toId);
      }
    });
  }

  String _exportGraph() {
    final data = _knowledgeGraph.map((node) => node.toJson()).toList();
    return data.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Timer App"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Titolo del Timer",
                ),
              ),
              TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: "Messaggio Finale",
                ),
              ),
              TextField(
                controller: _timeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Tempo in Minuti",
                ),
              ),
              SizedBox(height: 20),
              Text(
                _formatTime(_remainingSeconds),
                style: TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _startCountdown,
                    child: Text("Avvia"),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _stopCountdown,
                    child: Text("Ferma"),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _resetCountdown,
                    child: Text("Reset"),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _uploadFile,
                icon: Icon(Icons.upload_file),
                label: Text("Carica Foto"),
              ),
              if (_selectedFileUrl != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Image.network(
                    _selectedFileUrl!,
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _toggleGraphInterface,
                icon: Icon(_showGraphInterface ? Icons.visibility_off : Icons.account_tree),
                label: Text(_showGraphInterface ? "Nascondi Cervello Grafologico" : "Cervello Grafologico"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                ),
              ),
              if (_showGraphInterface) ...[
                SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Aggiungi Nodo al Grafo",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _nodeTitle,
                          decoration: InputDecoration(
                            labelText: "Titolo",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _nodeContent,
                          decoration: InputDecoration(
                            labelText: "Contenuto (discussione o codice)",
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Text("Tipo: "),
                            Radio<String>(
                              value: 'discussione',
                              groupValue: _nodeType,
                              onChanged: (value) {
                                setState(() {
                                  _nodeType = value!;
                                });
                              },
                            ),
                            Text("Discussione"),
                            Radio<String>(
                              value: 'codice',
                              groupValue: _nodeType,
                              onChanged: (value) {
                                setState(() {
                                  _nodeType = value!;
                                });
                              },
                            ),
                            Text("Codice"),
                          ],
                        ),
                        SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: _addGraphNode,
                          icon: Icon(Icons.add),
                          label: Text("Aggiungi Nodo"),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "Grafo della Conoscenza (${_knowledgeGraph.length} nodi)",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                ..._knowledgeGraph.map((node) => Card(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Icon(
                          node.type == 'codice' ? Icons.code : Icons.chat,
                          color: node.type == 'codice' ? Colors.green : Colors.blue,
                        ),
                        title: Text(node.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              node.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (node.connectedTo.isNotEmpty)
                              Text(
                                "Connesso a: ${node.connectedTo.length} nodi",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.purple,
                                ),
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteGraphNode(node.id),
                        ),
                      ),
                    )),
                if (_knowledgeGraph.isNotEmpty) ...[
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      final data = _exportGraph();
                      print("Dati del grafo: $data");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Grafo esportato nella console")),
                      );
                    },
                    icon: Icon(Icons.download),
                    label: Text("Esporta Grafo"),
                  ),
                ],
                SizedBox(height: 20),
              ],
              DropdownButtonFormField(
                items: _friends
                    .map((friend) => DropdownMenuItem(
                          value: friend,
                          child: Text(friend),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    if (!_selectedFriends.contains(value)) {
                      _selectedFriends.add(value!);
                    }
                  });
                },
                decoration: InputDecoration(
                  labelText: "Seleziona Amici",
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Cronologia Messaggi",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ..._messages.map((msg) => ListTile(
                    title: Text("A: ${msg['to']}"),
                    subtitle: Text(
                        "${msg['type']} - ${msg['title'] ?? msg['message']}"),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
