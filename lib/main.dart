import 'package:flutter/material.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:spintex_birth_days/firebase_database_util.dart';
import 'package:spintex_birth_days/user_dashboard.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// This "Headless Task" is run when app is terminated.
void backgroundFetchHeadlessTask(String taskId) async {
  if (taskId == "flutter_background_fetch") {
    await BackgroundFetch.scheduleTask(TaskConfig(
        taskId: "com.transistorsoft.customtask",
        delay: 5000,
        periodic: false,
        forceAlarmManager: true,
        stopOnTerminate: false,
        enableHeadless: true));
  }
  if (taskId == "com.transistorsoft.customtask") {
    initFireNotif();
  }

  BackgroundFetch.finish(taskId);
}

void initFireNotif() {
  FirebaseDatabaseUtil datab = new FirebaseDatabaseUtil();
  datab.initState();
  List<String> birthdayList = [];
  final databaseReference = datab.getUser();
  var inputFormat = DateFormat("dd.MM.yyyy");
  databaseReference.once().then((snapshot) {
    print(snapshot.value);
    Map<dynamic, dynamic> values = snapshot.value;
    values.forEach((key, values) {
      print(values["name"]);
      String ddmm = values["birthday"];
      var date1 = inputFormat.parse(ddmm);
      print("birthday = " + date1.toString());
      if (isTodayBirthday(date1)) {
        print("yesss");
        birthdayList.add(values['name']);
      }
    });
    print(birthdayList.join(", "));
    showNotification(birthdayList.join(", "));
    birthdayList.clear();
  });
}

Future showNotification(var name) async {
  var now = new DateTime.now();
  if (name != "") {
    if (now.hour == 10 || now.hour == 16) {
      print("date time true");
      _addBadge();
      var android = new AndroidNotificationDetails(
          'channel id', 'channel NAME', 'CHANNEL DESCRIPTION',
          priority: Priority.high, importance: Importance.max);
      var iOS = new IOSNotificationDetails();
      var platform = new NotificationDetails(android: android, iOS: iOS);
      await flutterLocalNotificationsPlugin.show(
          0, 'Сегодня день рождения', name, platform,
          payload: 'Сегодня день рождения $name');
    }
  }
  // _addBadge();
  // var android = new AndroidNotificationDetails(
  //     'channel id', 'channel NAME', 'CHANNEL DESCRIPTION',
  //     priority: Priority.high, importance: Importance.max);
  // var iOS = new IOSNotificationDetails();
  // var platform = new NotificationDetails(android: android, iOS: iOS);
  // await flutterLocalNotificationsPlugin.show(
  //     0, 'Сегодня день рождения', name, platform,
  //     payload: 'Сегодня день рождения $name');
}

bool isTodayBirthday(DateTime date) {
  DateTime today = new DateTime.now();
  print("datenow = " + today.toString());
  return today.month == date.month && today.day == date.day;
}

// Future onSelectNotification(String payload, BuildContext context) {
//   debugPrint("payload : $payload");
//   _removeBadge();
//   showDialog(
//     context: context,
//     builder: (_) => new AlertDialog(
//       title: new Text('Уведомление'),
//       content: new Text('$payload'),
//     ),
//   );
// }

void _addBadge() {
  FlutterAppBadger.updateBadgeCount(1);
}

// void _removeBadge() {
//   FlutterAppBadger.removeBadge(); dgrH356*dgrH356*
// }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  var initializationSettingsIOS = IOSInitializationSettings();
  var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: (String payload) async {
    if (payload != null) {
      debugPrint('notification payload: ' + payload);
    }
  });
  runApp(new MyApp());
  // Register to receive BackgroundFetch events after app is terminated.
  // Requires {stopOnTerminate: false, enableHeadless: true}
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      theme: new ThemeData(
        primaryColor: const Color(0xFF02BB9F),
        primaryColorDark: const Color(0xFF167F67),
        accentColor: const Color(0xFF167F67),
      ),
      debugShowCheckedModeBanner: false,
      title: 'Дни рождения',
      home: new SpalshScreen(),
    );
  }
}

class SpalshScreen extends StatefulWidget {
  SpalshScreen({Key key}) : super(key: key);
  _SpalshScreenState createState() => _SpalshScreenState();
}

class _SpalshScreenState extends State<SpalshScreen> {
  var buildVersion;

  @override
  void initState() {
    super.initState();
    _openPage();
  }

  void _openPage() {
    Future.delayed(
      Duration(seconds: 2),
      () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserDashboard(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Container(
      alignment: Alignment.center,
      decoration: kBoxDecorationColor,
      child: Column(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                child: Text("Дни рождения",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                        decorationStyle: TextDecorationStyle.wavy,
                        decorationThickness: 2)),
              ),
            ],
          ),
        ),
        Container(
          margin: EdgeInsets.only(bottom: 20.0),
          child: Text(
            "version 1.0.0",
            style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                decoration: TextDecoration.none,
                decorationStyle: TextDecorationStyle.wavy,
                decorationThickness: 2),
          ),
        )
      ]),
    );
  }
}

final kBoxDecorationColor = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF02BB9F),
      Color(0xFF167F67),
      Color(0xFF167F67),
    ],
    stops: [0.1, 0.5, 0.7],
  ),
);
