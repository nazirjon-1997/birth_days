import 'package:firebase_database/firebase_database.dart';

class User {
  String _id;
  String _name;
  String _birthday;
  String _mobile;

  User(this._id, this._name, this._birthday, this._mobile);

  String get name => _name;

  String get birthday => _birthday;

  String get mobile => _mobile;

  String get id => _id;

  User.fromSnapshot(DataSnapshot snapshot) {
    _id = snapshot.key;
    _name = snapshot.value['name'];
    _birthday = snapshot.value['birthday'];
    _mobile = snapshot.value['mobile'];
  }
}
