import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:radio_bolid/theme_provider.dart';

class ChangeThemeButton extends StatelessWidget {
  const ChangeThemeButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark;
    return Row(
      children: [
        Icon(!isDark ? Icons.light_mode : Icons.dark_mode),
        Switch.adaptive(
          activeColor: Colors.white,
          focusColor: Colors.white,
          value: themeProvider.isDarkMode,
          onChanged: (value) {
            final provider = Provider.of<ThemeProvider>(context, listen: false);
            provider.toggleTheme(value);
          },
        ),
      ],
    );
  }
}
