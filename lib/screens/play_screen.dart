import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:radio_player/radio_player.dart';
import 'package:flutter/services.dart';

import '../theme_provider.dart';

class PlayScreen extends StatefulWidget {
  PlayScreen({Key? key}) : super(key: key);

  @override
  _PlayScreenState createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  static RadioPlayer _radioPlayer = RadioPlayer();
  bool isPlaying = false;
  List<String>? metadata;

  bool isSet = false;
  bool isOn = false;
  bool isAllowed = false;
  bool _isHD = true;
  late MethodChannel _androidAutoChannel;

  @override
  void initState() {
    super.initState();
    _setupMethodChannel();
    initRadioPlayer();
    _setupAndroidAuto();
  }

  void _setupMethodChannel() {
    _androidAutoChannel = const MethodChannel('com.vr.radiobolid/android_auto');
    _androidAutoChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'play':
          await _radioPlayer.play();
          setState(() {
            isPlaying = true;
          });
          return null;
        case 'pause':
        case 'stop':
          await _radioPlayer.stop();
          setState(() {
            isPlaying = false;
          });
          return null;
        case 'getMediaItems':
          return [
            {
              'id': 'bolid_radio',
              'title': 'Радио Болид',
              'artist': metadata != null && metadata!.isNotEmpty ? metadata![0] : '',
              'album': metadata != null && metadata!.length > 1 ? metadata![1] : '',
              'albumArt': 'assets/images/bolidlogo.png',
              'playable': true,
            }
          ];
        default:
          throw PlatformException(
            code: 'Unimplemented',
            details: 'The method ${call.method} is not implemented',
          );
      }
    });
  }

  Future<void> _setupAndroidAuto() async {
    try {
      await _androidAutoChannel.invokeMethod('setupAndroidAuto', {
        'title': 'Радио Болид',
        'artist': metadata != null && metadata!.isNotEmpty ? metadata![0] : '',
        'album': metadata != null && metadata!.length > 1 ? metadata![1] : '',
        'isPlaying': isPlaying,
      });
    } on PlatformException catch (e) {
      print('Failed to setup Android Auto: ${e.message}');
    }
  }

  @override
  void dispose() {
    super.dispose();
    _radioPlayer.stop();
  }

  void initRadioPlayer() async {
    await _radioPlayer.setChannel(title: 'Радио Болид', url: 'https://icecast-bulteam.cdnvideo.ru/bolid128', imagePath: 'assets/images/bolidlogo.png');

    _radioPlayer.stateStream.listen((value) {
      setState(() {
        isPlaying = value;
      });
      _updateAndroidAutoState();
    });

    _radioPlayer.metadataStream.listen((value) {
      setState(() {
        metadata = value;
      });
      _updateAndroidAutoState();
    });
  }

  Future<void> _updateAndroidAutoState() async {
    try {
      await _androidAutoChannel.invokeMethod('updatePlaybackState', {
        'title': 'Радио Болид',
        'artist': metadata != null && metadata!.isNotEmpty ? metadata![0] : '',
        'album': metadata != null && metadata!.length > 1 ? metadata![1] : '',
        'isPlaying': isPlaying,
      });
    } on PlatformException catch (e) {
      print('Failed to update Android Auto state: ${e.message}');
    }
  }

  void toggleStream() async {
    bool playAfterChange = isPlaying;
    _isHD
        ? _radioPlayer.setChannel(title: 'Радио Болид', url: 'https://icecast-bulteam.cdnvideo.ru/bolid64', imagePath: 'assets/images/bolidlogo.png')
        : _radioPlayer.setChannel(title: 'Радио Болид', url: 'https://icecast-bulteam.cdnvideo.ru/bolid128', imagePath: 'assets/images/bolidlogo.png');
    _radioPlayer.stop();
    setState(() {
      _isHD = !_isHD;
    });
    await Future.delayed(Duration(milliseconds: 500));
    if (playAfterChange) _radioPlayer.play();
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    var isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    bool isDark = Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: isLandscape ? 900 : width / 1.1,
              height: isLandscape ? 125 : height / 3,
              child: Image.asset('assets/images/bolidlogo.png'),
            ),
            SizedBox(height: height / 15),
            SizedBox(
              width: width / 1.1,
              child: Text(
                metadata?[0] ?? '',
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.fade,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
              ),
            ),
            Text(
              metadata?[1] ?? '',
              softWrap: false,
              overflow: TextOverflow.fade,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: height / 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: isLandscape ? 50 : 100,
                  onPressed: () async {
                    isPlaying ? await _radioPlayer.stop() : await _radioPlayer.play();
                  },
                  icon: isPlaying
                      ? Icon(
                          Icons.pause_circle_filled,
                          color: isDark ? Colors.white : Colors.black,
                        )
                      : Icon(
                          Icons.play_circle_fill,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                ),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 3),
                    color: _isHD ? Colors.red : Colors.white,
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  child: TextButton(
                    onPressed: toggleStream,
                    child: _isHD
                        ? Text(
                            'HD',
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          )
                        : Text(
                            'LQ',
                            style: TextStyle(color: Colors.red, fontSize: 20),
                          ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
