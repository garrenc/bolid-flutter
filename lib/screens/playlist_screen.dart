import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:radio_bolid/metadata/metadata_worker.dart';
import 'package:radio_bolid/theme_provider.dart';

class PlaylistScreen extends StatefulWidget {
  PlaylistScreen({Key? key}) : super(key: key);

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> with WidgetsBindingObserver {
  bool isDark = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    MetaDataWorker.instance.start();
  }

  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    MetaDataWorker.instance.stop();
  }

  @override
  Widget build(BuildContext context) {
    isDark = Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark;
    return Scaffold(
        body: ListView(
      children: ListTile.divideTiles(
          color: Colors.grey,
          context: context,
          tiles: MetaDataWorker.metaData.reversed.map((e) => _createListTile(context, artistName: e.artistName, trackName: e.songName, time: DateFormat.Hm().format(e.dateTime)))).toList(),
    ));
  }

  Widget _createListTile(BuildContext context, {required String artistName, required String trackName, required String time}) => Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          title: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(artistName, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(trackName, style: TextStyle(fontSize: 16, color: isDark ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.w300)),
              ),
            ],
          ),
          trailing: Chip(
            label: Text(time, style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        ),
      );

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached || state == AppLifecycleState.inactive) {
      MetaDataWorker.instance.stop();
    } else {
      MetaDataWorker.instance.start();
    }
  }
}
