import 'dart:io';

import 'package:conferenceapp/analytics.dart';
import 'package:conferenceapp/sponsors/sponsors_page.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:package_info/package_info.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapfeed/snapfeed.dart';
import 'package:url_launcher/url_launcher.dart';

import 'authenticator_button.dart';
import 'settings_toggle.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int counter = 0;
  bool authVisible = false;

  @override
  Widget build(BuildContext context) {
    final sharedPrefs = Provider.of<SharedPreferences>(context);
    return Container(
      child: Center(
        child: Column(
          children: <Widget>[
            SettingsToggle(
              title: 'Dark Theme',
              onChanged: (_) => changeBrightness(),
              value: Theme.of(context).brightness == Brightness.dark,
            ),
            SettingsToggle(
              title: 'Reminders',
              onChanged: (value) {
                sharedPrefs.setBool('reminders', value);
                setState(() {});
              },
              value: sharedPrefs.getBool('reminders') == true,
            ),
            ListTile(
              title: Text('Sponsors'),
              subtitle: Text('See who supported us'),
              trailing: Icon(LineIcons.angle_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SponsorsPage(),
                    settings: RouteSettings(name: 'sponsors'),
                  ),
                );
              },
            ),
            ListTile(
              title: Text('Organizers'),
              subtitle: Text('See who created this event'),
              trailing: Icon(LineIcons.angle_right),
              onTap: () {},
            ),
            ListTile(
              title: Text('Send feedback'),
              subtitle: Text(
                  'Let us know if you find any errors or want to share your feedback with us'),
              trailing: Icon(LineIcons.angle_right),
              onTap: () async {
                await showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (ctx) => SimpleDialog(
                          children: <Widget>[
                            FlatButton(
                              child: Text('Send e-mail'),
                              onPressed: () {
                                sendEmail();
                                Navigator.pop(ctx);
                              },
                            ),
                            FlatButton(
                              child: Text(
                                'Try Snapfeed\n(User feedback tool for Flutter apps)',
                                textAlign: TextAlign.center,
                              ),
                              onPressed: () {
                                Navigator.pop(ctx);
                                Snapfeed.of(context).startFeedback();
                              },
                            )
                          ],
                        ));
              },
            ),
            ListTile(
              title: Text('Open source licenses'),
              subtitle:
                  Text('All the awesome libraries we used to create this app'),
              trailing: Icon(LineIcons.angle_right),
              onTap: () async {
                final version = await PackageInfo.fromPlatform();
                showLicensePage(
                    context: context,
                    applicationIcon: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Image.asset(
                        'assets/flutter_europe.png',
                        height: 50,
                      ),
                    ),
                    applicationName: 'Flutter Europe 2020',
                    applicationVersion: '${version?.version}',
                    applicationLegalese:
                        'Created by Dominik Roszkowski (roszkowski.dev) and Marcin Szałek (fidev.io) for Flutter Europe conference');
              },
            ),
            ListTile(
              title: Text('Service login'),
              subtitle: Text('You can check tickets if you\'re authorized'),
              trailing: Icon(LineIcons.angle_right),
              onTap: () {
                AuthenticatorButton().showLoginDialog(context);
              },
            ),
            Spacer(),
            Visibility(
              visible: authVisible,
              child: AuthenticatorButton(),
            ),
            GestureDetector(
              onTap: () {
                counter++;
                if (counter > 8) {
                  setState(() {
                    authVisible = true;
                  });
                }
              },
              child: VersionInfo(),
            )
          ],
        ),
      ),
    );
  }

  void sendEmail() async {
    final version = await PackageInfo.fromPlatform();
    final platform = Platform.isIOS ? 'iOS' : 'Android';
    final email = 'dominik@fluttereurope.dev';
    final subject = 'Feedback about Flutter Europe app';
    final body =
        'Hi! I wanted to share some feedback about Flutter Europe mobile app.<br><br><br>App Version: ${version.version}<br>App Id: ${version.packageName}<br>Platform: $platform';
    final url = Uri.encodeFull('mailto:$email?subject=$subject&body=$body');
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('Could not launch $url, trying typical share');
      Share.share(body, subject: body);
    }
  }

  void changeBrightness() {
    final target = Theme.of(context).brightness == Brightness.dark
        ? Brightness.light
        : Brightness.dark;
    final paramValue = target == Brightness.light ? 'light' : 'dark';
    analytics.logEvent(
      name: 'settings_theme',
      parameters: {'target': paramValue},
    );
    analytics.setUserProperty(name: 'theme', value: paramValue);
    DynamicTheme.of(context).setBrightness(target);
  }
}

class VersionInfo extends StatelessWidget {
  const VersionInfo({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final pkg = snapshot.data;
            return Row(
              children: <Widget>[
                Text('V. ${pkg.version} (${pkg.buildNumber})'),
              ],
            );
          }
          return Container();
        },
      ),
    );
  }
}
