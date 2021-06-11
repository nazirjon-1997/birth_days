import 'dart:io';

import 'package:background_fetch/background_fetch.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:spintex_birth_days/add_user_dialog.dart';
import 'package:spintex_birth_days/firebase_database_util.dart';
import 'package:spintex_birth_days/user.dart';

class UserDashboard extends StatefulWidget {
  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<UserDashboard> implements AddUserCallback {
  bool _anchorToBottom = false;
  FirebaseDatabaseUtil databaseUtil;
  String age;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  String _appBadgeSupported = 'Unknown';

  bool _enabled = true;
  int _status = 0;
  //List<DateTime> _events = [];

  List<String> birthdayList = [];

  @override
  void initState() {
    super.initState();
    databaseUtil = new FirebaseDatabaseUtil();
    databaseUtil.initState();
    initPlatformState();
    initPlatState();
    flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    var android = new AndroidInitializationSettings('@mipmap/ic_launcher');
    var iOS = new IOSInitializationSettings();
    var initSetttings = new InitializationSettings(android: android, iOS: iOS);
    flutterLocalNotificationsPlugin.initialize(initSetttings,
        onSelectNotification: onSelectNotification);
  }

  initPlatState() async {
    String appBadgeSupported;
    try {
      bool res = await FlutterAppBadger.isAppBadgeSupported();
      if (res) {
        appBadgeSupported = 'Supported';
      } else {
        appBadgeSupported = 'Not supported';
      }
    } on PlatformException {
      appBadgeSupported = 'Failed to get badge support.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _appBadgeSupported = appBadgeSupported;
    });
  }

  void _addBadge(int i) {
    FlutterAppBadger.updateBadgeCount(i);
  }

  void _removeBadge() {
    FlutterAppBadger.removeBadge();
  }

  Future onSelectNotification(String payload) {
    debugPrint("payload : $payload");
    _removeBadge();
    Alert(
      context: context,
      type: AlertType.info,
      title: "Уведомление",
      desc: '$payload',
      buttons: [
        DialogButton(
          child: Text(
            "OK",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          onPressed: () => Navigator.pop(context),
          color: Theme.of(context).primaryColor,
        ),
      ],
    ).show();
  }

  showNotification(var name) async {
    var now = new DateTime.now();
    if (name != "") {
      if (now.hour == 10 || now.hour == 16) {
        print("date time true");
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
  }

  void initFireNotif() {
    FirebaseDatabaseUtil datab = new FirebaseDatabaseUtil();
    datab.initState();

    print("log init fire initFireNotif");
    int i = 0;
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
          i = i + 1;
          birthdayList.add(values['name']);
        }
      });
      if (birthdayList.isNotEmpty) {
        print(birthdayList.join(", ").toString());
        showNotification(birthdayList.join(", ").toString());
        _addBadge(i);
        birthdayList.clear();
      }
    });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // Configure BackgroundFetch.
    BackgroundFetch.configure(
        BackgroundFetchConfig(
            minimumFetchInterval: 40,
            stopOnTerminate: false,
            enableHeadless: true,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresStorageNotLow: false,
            requiresDeviceIdle: false,
            requiredNetworkType: NetworkType.NONE), (String taskId) async {
      // This is the fetch-event callback.
      print("[BackgroundFetch] Event received $taskId");
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
        print("log init fire notif");
        initFireNotif();
      }
      print("initFireNotif");
      // IMPORTANT:  You must signal completion of your task or the OS can punish your app
      // for taking too long in the background.
      BackgroundFetch.finish(taskId);
    }).then((int status) {
      print('[BackgroundFetch] configure success: $status');
      setState(() {
        _status = status;
      });
    }).catchError((e) {
      print('[BackgroundFetch] configure ERROR: $e');
      setState(() {
        _status = e;
      });
    });

    // Optionally query the current BackgroundFetch status.
    int status = await BackgroundFetch.status;
    setState(() {
      _status = status;
    });

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

  bool isTodayBirthday(DateTime date) {
    DateTime today = new DateTime.now();
    print("datenow = " + today.toString());
    return today.month == date.month && today.day == date.day;
  }

  // void _onClickEnable(enabled) {
  //   setState(() {
  //     _enabled = enabled;
  //   });
  //   if (enabled) {
  //     BackgroundFetch.start().then((int status) {
  //       print('[BackgroundFetch] start success: $status');
  //     }).catchError((e) {
  //       print('[BackgroundFetch] start FAILURE: $e');
  //     });
  //   } else {
  //     BackgroundFetch.stop().then((int status) {
  //       print('[BackgroundFetch] stop success: $status');
  //     });
  //   }
  // }

  @override
  void dispose() {
    super.dispose();
    //databaseUtil.dispose();
  }

  /// This "Headless Task" is run when app is terminated.
  // void backgroundFetchHeadlessTask(String taskId) async {
  //   print('[BackgroundFetch] Headless event received.');
  //   BackgroundFetch.finish(taskId);
  // }

  @override
  Widget build(BuildContext context) {
    // showNotification("name");

    Widget _buildTitle(BuildContext context) {
      return new InkWell(
        child: new Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              new Text(
                'Дни рождения',
                style: new TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    List<Widget> _buildActions() {
      return <Widget>[
        new IconButton(
          icon: const Icon(
            Icons.group_add,
            color: Colors.white,
          ),
          onPressed: () => showEditWidget(null, false),
        ),
      ];
    }

    return WillPopScope(
      onWillPop: _onBackPressed,
      child: new Scaffold(
        appBar: new AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          title: _buildTitle(context),
          actions: _buildActions(),
        ),
        body: new FirebaseAnimatedList(
          key: new ValueKey<bool>(_anchorToBottom),
          query: databaseUtil.getUser(),
          reverse: _anchorToBottom,
          sort: _anchorToBottom
              ? (DataSnapshot a, DataSnapshot b) => b.key.compareTo(a.key)
              : null,
          itemBuilder: (BuildContext context, DataSnapshot snapshot,
              Animation<double> animation, int index) {
            return new SizeTransition(
              sizeFactor: animation,
              child: showUser(snapshot),
            );
          },
        ),
      ),
    );
  }

  Future<bool> _onBackPressed() {
    return Alert(
          context: context,
          type: AlertType.warning,
          title: "Вы уверены?",
          desc: "Вы хотите выйти из приложения",
          buttons: [
            DialogButton(
              child: Text(
                "НЕТ",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              onPressed: () => Navigator.of(context).pop(false),
              color: Colors.red,
            ),
            DialogButton(
              child: Text(
                "ДА",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              onPressed: () {
                if (Platform.isAndroid) {
                  SystemNavigator.pop();
                } else if (Platform.isIOS) {
                  exit(0);
                }
              },
              color: Colors.greenAccent,
            ),
          ],
        ).show() ??
        false;
  }

  @override
  void addUser(User user) {
    setState(() {
      databaseUtil.addUser(user);
    });
  }

  @override
  void update(User user) {
    setState(() {
      databaseUtil.updateUser(user);
    });
  }

  Widget showUser(DataSnapshot res) {
    User user = User.fromSnapshot(res);

    if (user.birthday.isNotEmpty) {
      var inputFormat = DateFormat("dd.MM.yyyy");
      var date1 = inputFormat.parse(user.birthday);
      var outputFormat = DateFormat("yyyy-MM-dd");
      var date2 = outputFormat.parse("$date1");
      Duration dur = DateTime.now().difference(date2);
      age = (dur.inDays / 365).floor().toString();
      print("year = " + age);
    }
    var item = new Card(
      semanticContainer: true,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      elevation: 8,
      child: new Container(
          child: new Center(
            child: new Row(
              children: <Widget>[
                new CircleAvatar(
                  radius: 30.0,
                  child: new Text(getShortName(user)),
                  backgroundColor: const Color(0xFF20283e),
                ),
                new Expanded(
                  child: new Padding(
                    padding: EdgeInsets.all(10.0),
                    child: new Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        new Text(
                          user.name,
                          // set some style to text
                          style: new TextStyle(
                              fontSize: 20.0, color: Colors.lightBlueAccent),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.date_range,
                              color: Colors.blue,
                              size: 20,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 8.0, top: 8.0),
                              child: new Text(
                                user.birthday,
                                // set some style to text
                                style: new TextStyle(
                                    fontSize: 16.0, color: Colors.purple),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.update,
                              color: Colors.blue,
                              size: 20,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 8.0, top: 2.0),
                              child: new Text(
                                age.isNotEmpty ? getAge(age) : "",
                                // set some style to text
                                style: new TextStyle(
                                    fontSize: 16.0, color: Colors.amber),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_iphone,
                              color: Colors.blue,
                              size: 20,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 8.0, top: 2.0),
                              child: new Text(
                                user.mobile,
                                // set some style to text
                                style: new TextStyle(
                                    fontSize: 16.0, color: Colors.cyan),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                new Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    new IconButton(
                      icon: const Icon(
                        Icons.edit,
                        color: const Color(0xFF167F67),
                      ),
                      onPressed: () => showEditWidget(user, true),
                    ),
                    new IconButton(
                      icon: const Icon(Icons.delete_forever,
                          color: const Color(0xFF167F67)),
                      onPressed: () => showDialogDelete(context, user),
                    ),
                  ],
                ),
              ],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0)),
    );

    return item;
  }

  void showDialogDelete(BuildContext context, User user) {
    Alert(
      context: context,
      type: AlertType.warning,
      title: "Сообщения",
      desc: "Вы действительно хотите удалить данные?",
      buttons: [
        DialogButton(
          child: Text(
            "Отмена",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          onPressed: () => Navigator.pop(context),
          color: Colors.red,
        ),
        DialogButton(
          child: Text(
            "Удалить",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          onPressed: () => deleteUser(user),
          color: Colors.greenAccent,
        ),
      ],
    ).show();
  }

  String getAge(String _age) {
    int endage = 0;
    String str;
    if (!_age.isEmpty) {
      endage =
          int.parse(_age.substring((_age.length - 1).clamp(0, _age.length)));
      print(endage);
      if (endage == 1) {
        str = age + " год";
      }
      if (endage >= 2 || endage <= 4) {
        str = age + " года";
      }
      if (endage == 0 || endage >= 5) {
        str = age + " лет";
      }
    }
    print(str);
    return str;
  }

  String getShortName(User user) {
    String shortName = "";
    if (!user.name.isEmpty) {
      shortName = user.name.substring(0, 1);
    }
    return shortName;
  }

  showEditWidget(User user, bool isEdit) {
    showDialog(
      context: context,
      builder: (BuildContext context) =>
          new AddUserDialog().buildAboutDialog(context, this, isEdit, user),
    );
  }

  deleteUser(User user) {
    setState(() {
      databaseUtil.deleteUser(user);
      Navigator.of(context).pop(false);
    });
  }
}
