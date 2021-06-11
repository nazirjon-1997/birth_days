import 'package:flutter/material.dart';
import 'package:flutter_masked_text/flutter_masked_text.dart';
import 'package:fluttertoast/fluttertoast.dart';
//import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:spintex_birth_days/user.dart';

class AddUserDialog {
  final teName = TextEditingController();
  //final teBirthday = TextEditingController();
  //final teMobile = TextEditingController();
  User user;
  var maskController = new MaskedTextController(mask: '00.00.0000');
  var teMobile = new MaskedTextController(mask: '0 000 000 00 00');
  // var maskFormatter = new MaskTextInputFormatter(
  //     mask: '##.##.####', filter: {"#": RegExp(r'[0-9]')});

  static const TextStyle linkStyle = const TextStyle(
    color: Colors.blue,
    decoration: TextDecoration.underline,
  );

  Widget buildAboutDialog(BuildContext context,
      AddUserCallback _myHomePageState, bool isEdit, User user) {
    if (user != null) {
      this.user = user;
      teName.text = user.name;
      maskController.text = user.birthday;
      teMobile.text = user.mobile;
    }

    return new AlertDialog(
      title: new Text(isEdit ? 'Изменить деталь!' : 'Добавить  данные!'),
      content: new SingleChildScrollView(
        child: new Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            getTextField("Фамилия Имя Отчество", teName),
            getTextFieldBirthDay(context, "Дата рождения", maskController),
            getTextFieldMobile(context, "Номер телефон", teMobile),
            new GestureDetector(
              onTap: () {
                if (teName.text.isNotEmpty && maskController.text.isNotEmpty) {
                  if (maskController.text.length == 10) {
                    onTap(isEdit, _myHomePageState, context);
                  } else {
                    Fluttertoast.showToast(
                        msg: "Дата рождения не правильно запольнено",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                        fontSize: 14.0);
                  }
                } else {
                  Fluttertoast.showToast(
                      msg: "Запольните полей",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      timeInSecForIosWeb: 1,
                      backgroundColor: Colors.red,
                      textColor: Colors.white,
                      fontSize: 14.0);
                }
              },
              child: new Container(
                margin: EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 0.0),
                child: getAppBorderButton(isEdit ? "Редактировать" : "Добавить",
                    EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget getTextField(
      String inputBoxName, TextEditingController inputBoxController) {
    var loginBtn = new Padding(
      padding: const EdgeInsets.all(5.0),
      child: new TextFormField(
        autocorrect: true,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        controller: inputBoxController,
        textInputAction: TextInputAction.next,
        decoration: new InputDecoration(
          labelText: inputBoxName,
        ),
        validator: (value) {
          if (value.isEmpty) {
            return '\u26A0 Поле пустое.';
          }
          return null;
        },
      ),
    );

    return loginBtn;
  }

  Widget getTextFieldBirthDay(BuildContext context, String inputBoxName,
      TextEditingController inputBoxController) {
    var loginBtn = new Padding(
      padding: const EdgeInsets.all(5.0),
      child: new TextFormField(
        //inputFormatters: [maskFormatter],
        controller: inputBoxController,
        textInputAction: TextInputAction.next,
        keyboardType: TextInputType.number,
        decoration: new InputDecoration(
          hintText: "день/месяц/год",
          labelText: inputBoxName,
        ),
        validator: (value) {
          if (value.isEmpty) {
            return '\u26A0 Поле пустое.';
          }
          return null;
        },
      ),
    );

    return loginBtn;
  }

  Widget getTextFieldMobile(BuildContext context, String inputBoxName,
      TextEditingController inputBoxController) {
    var loginBtn = new Padding(
      padding: const EdgeInsets.all(5.0),
      child: new TextFormField(
        controller: inputBoxController,
        keyboardType: TextInputType.number,
        decoration: new InputDecoration(
          labelText: inputBoxName,
        ),
      ),
    );

    return loginBtn;
  }

  Widget getAppBorderButton(String buttonLabel, EdgeInsets margin) {
    var loginBtn = new Container(
      margin: margin,
      padding: EdgeInsets.all(8.0),
      alignment: FractionalOffset.center,
      decoration: new BoxDecoration(
        border: Border.all(color: const Color(0xFF28324E)),
        borderRadius: new BorderRadius.all(const Radius.circular(6.0)),
      ),
      child: new Text(
        buttonLabel,
        style: new TextStyle(
          color: const Color(0xFF28324E),
          fontSize: 20.0,
          fontWeight: FontWeight.w300,
          letterSpacing: 0.3,
        ),
      ),
    );
    return loginBtn;
  }

  User getData(bool isEdit) {
    return new User(
        isEdit ? user.id : "", teName.text, maskController.text, teMobile.text);
  }

  onTap(bool isEdit, AddUserCallback _myHomePageState, BuildContext context) {
    if (isEdit) {
      _myHomePageState.update(getData(isEdit));
      Navigator.of(context).pop();
    } else {
      _myHomePageState.addUser(getData(isEdit));
      Navigator.of(context).pop();
    }
  }
}

abstract class AddUserCallback {
  void addUser(User user);

  void update(User user);
}
