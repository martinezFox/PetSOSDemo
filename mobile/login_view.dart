import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pet_sos/bloc/bloc.dart';
import 'package:pet_sos/locale/locale.dart';
import 'package:pet_sos/resources/resources.dart';
import 'package:pet_sos/ui/ui.dart';
import 'package:pet_sos/util/util.dart';

class LoginView extends StatefulWidget {
  final Function(AccountClickAction) onActionClick;
  final Function({String email, String password}) onWelcome;

  const LoginView({@required this.onActionClick, @required this.onWelcome});

  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final FocusNode _emailNode = FocusNode();
  final FocusNode _passwordNode = FocusNode();

  bool _isPasswordObscure = true;

  String _email;
  String _password;

  final _formKey = GlobalKey<FormState>();

  LoginBloc _bloc;

  @override
  void initState() {
    super.initState();
    _emailNode.addListener(() {
      setState(() {});
    });
    _passwordNode.addListener(() {
      setState(() {});
    });
    _bloc = context.bloc<LoginBloc>();
  }

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    final cardWidth = min(deviceSize.width * 0.75, 360.0);
    final cardPadding = min(deviceSize.width * 0.09, 35.0);
    final labelActiveStyle = Theme.of(context).textTheme.subtitle2.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        );
    final labelInactiveStyle = labelActiveStyle.copyWith(color: AppColors.grayish);
    final errorStyle = Theme.of(context).textTheme.subtitle2.copyWith(color: Colors.redAccent);
    return BlocListener<LoginBloc, BlocState>(
      listener: _listen,
      child: FittedBox(
        alignment: Alignment.center,
        child: Card(
          margin: EdgeInsets.only(
            left: cardPadding,
            right: cardPadding,
          ),
          elevation: 8.0,
          color: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18.0)),
          ),
          child: Container(
            width: cardWidth,
            child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      FacebookContinue(onClick: () => _bloc.add(ContinueWithFacebook())),
                      GoogleContinue(onClick: () => _bloc.add(ContinueWithGoogle())),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  const TinyDivider(),
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, right: 14.0, left: 14.0),
                    child: TextFormField(
                      focusNode: _emailNode,
                      validator: Validator.email,
                      onSaved: (value) => _email = value.trim(),
                      cursorColor: AppColors.primary,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                          borderSide: BorderSide(color: AppColors.primary, width: 1.2),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        isDense: true,
                        labelText: AccountStrings.email,
                        labelStyle: _emailNode.hasFocus ? labelActiveStyle : labelInactiveStyle,
                        errorStyle: errorStyle,
                        prefixIcon: Icon(
                          Icons.email,
                          size: 24.0,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 14.0, right: 14.0, left: 14.0),
                    child: TextFormField(
                      focusNode: _passwordNode,
                      obscureText: _isPasswordObscure,
                      validator: Validator.password,
                      onSaved: (value) => _password = value,
                      cursorColor: AppColors.primary,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                          borderSide: BorderSide(color: AppColors.primary, width: 1.2),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        isDense: true,
                        labelText: AccountStrings.password,
                        labelStyle: _passwordNode.hasFocus ? labelActiveStyle : labelInactiveStyle,
                        errorStyle: errorStyle,
                        prefixIcon: Icon(
                          Icons.lock,
                          size: 24.0,
                        ),
                        suffixIcon: AbsorbPointer(
                          absorbing: false,
                          child: IconButton(
                            highlightColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            onPressed: () {
                              setState(() {
                                _isPasswordObscure = !_isPasswordObscure;
                              });
                            },
                            icon: Icon(_isPasswordObscure ? Icons.visibility_off : Icons.visibility, size: 24.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  GestureDetector(
                    child: Text(AccountStrings.forgotPassword, style: Theme.of(context).textTheme.subtitle1),
                    onTap: () {
                      widget.onActionClick(AccountClickAction.forgot);
                    },
                  ),
                  const SizedBox(height: 16.0),
                  ActionButton(
                    actionText: ActionStrings.login,
                    action: _submit,
                    enabled: true,
                    radius: 24.0,
                  ),
                  const SizedBox(height: 8.0),
                  GestureDetector(
                    child: Text(AccountStrings.newAccount, style: Theme.of(context).textTheme.subtitle1),
                    onTap: () {
                      widget.onActionClick(AccountClickAction.signup);
                    },
                  ),
                  const SizedBox(height: 16.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailNode.dispose();
    _passwordNode.dispose();
    super.dispose();
  }

  void _listen(context, state) {
    if (state is LoadingState<void>) {
      showDialog(
        context: context,
        useRootNavigator: false,
        builder: (_) => CustomProgressDialog(progress: ActionStrings.loggingIn),
      );
      return;
    }
    if (state is LoginSuccess) {
      Navigator.of(context, rootNavigator: true).pop();
      return;
    }
    if (state is SignupSuccess) {
      _popProgress();
      widget.onWelcome();
      return;
    }
    if (state is FailureState) {
      _popProgress();
      showDialog(
        context: context,
        useRootNavigator: false,
        builder: (context) => CustomSimpleDialog(
          title: state.title,
          message: state.message,
          confirmOnly: true,
        ),
      );
      return;
    }
  }

  void _popProgress() {
    Navigator.of(context).pop();
  }

  void _submit() {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      _bloc.add(EmailLoginAttempt(email: _email, password: _password));
    }
  }
}