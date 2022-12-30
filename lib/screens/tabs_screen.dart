import 'package:flutter/material.dart';
import 'package:radio_bolid/screens/playlist_screen.dart';
import 'package:radio_bolid/widgets/change_theme_button.dart';

import '../../screens/info_screen.dart';
import '../../screens/play_screen.dart';

class TabsScreen extends StatefulWidget {
  const TabsScreen({Key? key, this.payload}) : super(key: key);
  final String? payload;
  @override
  _TabsScreenState createState() => _TabsScreenState();
}

class _TabsScreenState extends State<TabsScreen> {
  int currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Радио Болид'),
        actions: const [
          ChangeThemeButton(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.red,
        onTap: (index) {
          setState(() {
            currentTab = index;
          });
        },
        currentIndex: currentTab,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.radio),
            label: 'Радио',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.playlist_play),
            label: 'Плейлист',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'Контакты',
          ),
        ],
      ),
      body: IndexedStack(
        children: <Widget>[
          PlayScreen(),
          PlaylistScreen(),
          const InfoScreen(),
        ],
        index: currentTab,
      ),
    );
  }
}
