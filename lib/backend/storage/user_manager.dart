import '../models/user.dart';
import 'package:flutter/foundation.dart';

class UserManager {
  static final UserManager _instance = UserManager._internal();
  factory UserManager() => _instance;
  UserManager._internal();

  // Make currentUser reactive
  final ValueNotifier<User?> currentUser = ValueNotifier<User?>(null);

  void login(User user) {
    currentUser.value = user;
  }

  void logout() {
    currentUser.value = null;
  }

  void updateUser(User updatedUser) {
    if (currentUser.value != null) {
      currentUser.value!.name = updatedUser.name;
      currentUser.value!.email = updatedUser.email;
      currentUser.value!.profileImage = updatedUser.profileImage;
      currentUser.notifyListeners();
    } else {
      currentUser.value = updatedUser;
    }
  }
}
