import 'package:rxdart/rxdart.dart';

import 'custom_auth_manager.dart';

class SecureMessagingAuthUser {
  SecureMessagingAuthUser({required this.loggedIn, this.uid});

  bool loggedIn;
  String? uid;
}

/// Generates a stream of the authenticated user.
BehaviorSubject<SecureMessagingAuthUser> secureMessagingAuthUserSubject =
    BehaviorSubject.seeded(SecureMessagingAuthUser(loggedIn: false));
Stream<SecureMessagingAuthUser> secureMessagingAuthUserStream() =>
    secureMessagingAuthUserSubject
        .asBroadcastStream()
        .map((user) => currentUser = user);
