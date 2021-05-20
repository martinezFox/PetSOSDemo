import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:pet_sos/bloc/bloc.dart';
import 'package:pet_sos/extension/extension.dart';
import 'package:pet_sos/repo/repo.dart';

class EmailLoginCase extends StreamUseCase<EmailLoginAttempt> {
  final NetworkRepository network;
  final SessionRepository session;

  EmailLoginCase({
    @required this.network,
    @required this.session,
  });

  @override
  Stream<BlocState> run({EmailLoginAttempt event}) async* {
    yield LoadingState<void>();
    final loginParams = jsonEncode({JsonKeys.email: event.email, JsonKeys.password: event.password});
    final response = await network.postLogin(loginParams);
    final body = jsonDecode(response.body);
    if (response.isSuccessful) {
      await session.userLoggedIn(body[JsonKeys.token], body[JsonKeys.id], body[JsonKeys.email]);
      yield LoginSuccess();
    } else {
      yield defaultFailure(body);
    }
  }
}

class EmailSignupCase extends StreamUseCase<EmailSignupAttempt> {
  final NetworkRepository network;

  EmailSignupCase({@required this.network});

  @override
  Stream<BlocState> run({EmailSignupAttempt event}) async* {
    yield LoadingState<void>();
    final signupParams = jsonEncode({JsonKeys.email: event.email, JsonKeys.password: event.password});
    final response = await network.postSignup(signupParams);
    final body = jsonDecode(response.body);
    if (response.statusCode == 201) {
      yield SignupSuccess(email: body[JsonKeys.email], password: event.password);
    } else {
      yield defaultFailure(body);
    }
  }
}

class ContinueWithGoogleCase extends StreamUseCase {
  final NetworkRepository network;
  final GoogleRepository google;
  final SessionRepository session;

  ContinueWithGoogleCase({
    @required this.network,
    @required this.google,
    @required this.session,
  });

  @override
  Stream<BlocState> run({BlocEvent event}) async* {
    final idToken = await google.signIn();
    if (idToken == null) return;
    yield LoadingState<void>();
    final response = await network.postGoogle(idToken);
    final body = jsonDecode(response.body);
    if (response.isSuccessful) {
      await session.userLoggedIn(body[JsonKeys.token], body[JsonKeys.id], body[JsonKeys.email]);
      if (response.statusCode == 200) {
        yield LoginSuccess();
        return;
      }
      if (response.statusCode == 201) {
        yield SignupSuccess();
        return;
      }
    } else {
      yield defaultFailure(body);
    }
  }
}

class ContinueWithFacebookCase extends StreamUseCase {
  final NetworkRepository network;
  final FacebookRepository facebook;
  final SessionRepository session;

  ContinueWithFacebookCase({
    @required this.network,
    @required this.facebook,
    @required this.session,
  });

  @override
  Stream<BlocState> run({BlocEvent event}) async* {
    yield LoadingState<void>();
    String accessToken = await facebook.isLoggedIn;
    accessToken ??= await facebook.logIn();
    final response = await network.postFacebook(accessToken);
    final body = jsonDecode(response.body);
    if (response.isSuccessful) {
      await session.userLoggedIn(body[JsonKeys.token], body[JsonKeys.id], body[JsonKeys.email]);
      if (response.statusCode == 200) {
        yield LoginSuccess();
        return;
      }
      if (response.statusCode == 201) {
        yield SignupSuccess();
        return;
      }
    } else {
      await facebook.logOut();
      yield defaultFailure(body);
    }
  }
}