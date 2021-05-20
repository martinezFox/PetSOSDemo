import 'package:flutter/widgets.dart';
import 'package:pet_sos/bloc/bloc.dart';

class LoginBloc extends BaseBloc {
  final StreamUseCaseProvider provider;

  LoginBloc({@required this.provider});

  @override
  Stream<BlocState> mapEventToState(BlocEvent event) async* {
    if (event is ContinueWithGoogle) {
      yield* provider.useCase<ContinueWithGoogleCase>().runSafely();
      return;
    }
    if (event is ContinueWithFacebook) {
      yield* provider.useCase<ContinueWithFacebookCase>().runSafely();
      return;
    }
    if (event is EmailLoginAttempt) {
      yield* provider.useCase<EmailLoginCase>().runSafely(event: event);
      return;
    }
  }
}