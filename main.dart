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
  List<Offset?> _handwritingPoints = [];
  bool _showHandwritingPad = false;

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

  void _clearHandwriting() {
    setState(() {
      _handwritingPoints.clear();
    });
  }

  void _toggleHandwritingPad() {
    setState(() {
      _showHandwritingPad = !_showHandwritingPad;
    });
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
                onPressed: _toggleHandwritingPad,
                icon: Icon(_showHandwritingPad ? Icons.visibility_off : Icons.edit),
                label: Text(_showHandwritingPad ? "Nascondi Scrittura" : "Cervello Grafologico"),
              ),
              if (_showHandwritingPad) ...[
                SizedBox(height: 10),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        RenderBox renderBox = context.findRenderObject() as RenderBox;
                        _handwritingPoints.add(
                          renderBox.globalToLocal(details.globalPosition),
                        );
                      });
                    },
                    onPanEnd: (details) {
                      setState(() {
                        _handwritingPoints.add(null);
                      });
                    },
                    child: CustomPaint(
                      painter: HandwritingPainter(_handwritingPoints),
                      size: Size.infinite,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _clearHandwriting,
                  icon: Icon(Icons.clear),
                  label: Text("Cancella Scrittura"),
                ),
                SizedBox(height: 10),
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

class HandwritingPainter extends CustomPainter {
  final List<Offset?> points;

  HandwritingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(HandwritingPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
