import 'package:flutter/material.dart';
import 'package:sodhis_app/constants.dart';
import 'package:flutter/services.dart';
import 'package:sodhis_app/components/general.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/gestures.dart';
import 'package:sodhis_app/utilities/basic_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

class LoginPage extends StatefulWidget {
  final String mobile = '';
  LoginPage() : super();
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final mobileController = TextEditingController();
  final pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  var _mobile;
  var _pin;
  bool _loading = false;
  @override
  void dispose() {
    mobileController.dispose();
    pinController.dispose();
    super.dispose();
  }

  Widget _welcomeText() {
    return Container(
      padding: const EdgeInsets.only(left: 30),
      child: Text(
        "Welcome to 7mirchi's Mart!",
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  Widget _signinText() {
    return Container(
      padding: const EdgeInsets.only(top: 20, left: 30),
      child: Text(
        "SIGN IN",
        style: TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }

  Widget _mobileTextbox() {
    return Container(
      margin: new EdgeInsets.only(left: 30, right: 30, bottom: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextFormField(
          controller: mobileController,
          keyboardType: TextInputType.number,
          cursorColor: Color(0xFF372D61),
          textCapitalization: TextCapitalization.sentences,
          validator: (value) {
            if (value.isEmpty) {
              return 'Please enter 10 digit mobile number';
            } else if (value.length < 10) {
              return 'Please enter 10 digit mobile number';
            } else if (value.length > 10) {
              return 'Please enter 10 digit mobile number';
            }
            return null;
          },
          onSaved: (String value) {
            _mobile = value;
          },
          decoration: InputDecoration(
            hintText: 'Mobile Number',
          ),
        ),
      ),
    );
  }

  Widget _pinTextbox() {
    return Container(
      margin: new EdgeInsets.only(left: 30, right: 30, bottom: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextFormField(
          controller: pinController,
          maxLength: 6,
          keyboardType: TextInputType.number,
          cursorColor: Color(0xFF372D61),
          validator: (value) {
            if (value.isEmpty) {
              return 'Please enter 6 digit pin';
            } else if (value.length < 6) {
              return 'Please enter 6 digit pin';
            }
            return null;
          },
          onSaved: (String val) {
            _pin = val;
          },
          decoration: InputDecoration(
            hintText: 'PIN Code',
          ),
        ),
      ),
    );
  }

  Widget _loginButton() {
    return Container(
      margin: new EdgeInsets.only(top: 20, left: 30, right: 30, bottom: 30),
      child: Align(
        alignment: Alignment.center,
        child: ButtonTheme(
          minWidth: MediaQuery.of(context).size.width,
          child: RaisedButton(

            onPressed: () async {
              if (_formKey.currentState.validate()) {
                _formKey.currentState.save();
                setState(() {
                  _loading = true;
                });
                var response = await http.post(
                  new Uri.https(BASE_URL, API_PATH + "/app-login"),
                  body: {
                    "mobile_number": mobileController.text,
                    "pin": pinController.text
                  },
                  headers: {
                    "Accept": "application/json",
                    "authorization": basicAuth
                  },
                );
                if (response.statusCode == 200) {
                  setState(() {
                    _loading = false;
                  });
                  var data = json.decode(response.body);
                  var errorCode = data['ErrorCode'];
                  var errorMessage = data['ErrorMessage'];
                  if (errorCode == 0) {
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    prefs.setBool('logged_in', true);
                    prefs.setBool('logged_one', true);
                    prefs.setInt('cart_count', 0);
                    prefs.setInt('user_id', data['Response']['id']);
                    prefs.setString('name', data['Response']['name']);
                    prefs.setString(
                        'email_address', data['Response']['email_address']);
                    prefs.setString(
                        'mobile_number', data['Response']['mobile_number']);
                    prefs.setString('address', data['Response']['address']);
                    Navigator.pushReplacementNamed(context, '/dashboard');
                  } else {
                    showAlertDialog(context, ALERT_DIALOG_TITLE, errorMessage);
                  }
                }
              }
            },
            elevation: 0,
            padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
            shape: StadiumBorder(),
            child: Text(
              "SIGN IN",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _signupContainer() {
    return Container(
      padding: const EdgeInsets.only(top: 0, left: 30, right: 30),
      child: Align(
        alignment: Alignment.center,
        child: RichText(
          text: TextSpan(
            text: "Don't have an account? ",
            style: TextStyle(color: Colors.grey[700]),
            children: <TextSpan>[
              TextSpan(
                text: 'Sign up',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF372D61),
                ),
                recognizer: new TapGestureRecognizer()
                  ..onTap = () => Navigator.pushNamed(context, '/signup'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _forgotPinContainer() {
    return Container(
      padding: const EdgeInsets.only(top: 20, left: 30, right: 30),
      child: Align(
        alignment: Alignment.center,
        child: RichText(
          text: TextSpan(
            text: 'Forgot Pin?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF372D61),
              decoration: TextDecoration.underline,
            ),
            recognizer: new TapGestureRecognizer()
              ..onTap = () => Navigator.pushNamed(context, '/forgot-pin'),
          ),
        ),
      ),
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF372D61),
      body: ModalProgressHUD(
        inAsyncCall: _loading,
        child: SafeArea(
          child: Container(
            child: Column(
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: Center(
                    child: ListView(shrinkWrap: true, children: <Widget>[
                      _welcomeText(),
                      _signinText(),
                    ]),
                  ),
                ),
                Expanded(
                  flex: 7,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(25.0),
                        topRight: Radius.circular(25.0),
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.only(top: 20, bottom: 30),
                        children: <Widget>[
                          _mobileTextbox(),
                          _pinTextbox(),
                          _loginButton(),
                          _signupContainer(),
                          _forgotPinContainer(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
