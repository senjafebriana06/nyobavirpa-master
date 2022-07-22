import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:nyobavirpa/menu.dart';
import 'package:nyobavirpa/signup.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login.dart';

late List<CameraDescription> cameras;
SharedPreferences? prefs;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  cameras = await availableCameras();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => BsaState()),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    ),
  ));
}

class BsaState with ChangeNotifier, DiagnosticableTreeMixin {
  bool _a_set = false;
  bool _b_set = false;
  double _a = 0;
  double _b = 0;
  double _t = 0;

  bool get a_set => _a_set;
  bool get b_set => _b_set;
  double get a => _a;
  double get b => _b;
  double get t => _t;

  set setA(bool __a) {
    _a_set = __a;
    notifyListeners();
  }

  set setB(bool __b) {
    _b_set = __b;
    notifyListeners();
  }

  set setAVal(double val) {
    _a = val;
    notifyListeners();
  }

  set setBVal(double val) {
    _b = val;
    notifyListeners();
  }

  set setTVal(double val) {
    _t = val;
    notifyListeners();
  }

  void reset() {
    _a_set = false;
    _b_set = false;
    _a = 0;
    _b = 0;
    _t = 0;
  }
}

class HomePage extends StatelessWidget {
  void checkAuth(BuildContext context) async {
    prefs = await SharedPreferences.getInstance();

    String? id = prefs?.getString('id');

    if (id != null) {
      /*Navigator.push(
          context, MaterialPageRoute(builder: (context) => MenuPage()));*/
    }
  }

  @override
  Widget build(BuildContext context) {
    checkAuth(context);

    EasyLoading.instance
      ..userInteractions = false
      ..indicatorType = EasyLoadingIndicatorType.ring
      ..dismissOnTap = false;

    return FlutterEasyLoading(
        child: Scaffold(
      appBar: AppBar(
        title: Text("VIRPA"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height,
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 50),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Column(
                children: <Widget>[
                  Text(
                    "VIRPA",
                    style: TextStyle(
                      fontFamily: 'Knewave',
                      fontWeight: FontWeight.bold,
                      fontSize: 60,
                      color: Colors.blue[700],
                    ),
                  ),
                  Text(
                    "Virtual Posyandu",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              Container(
                height: MediaQuery.of(context).size.height / 3,
                decoration: BoxDecoration(
                    image: DecorationImage(
                  image: AssetImage("assets/images/pertama.png"),
                )),
              ),
              Column(
                children: <Widget>[
                  Text(
                    "toodler growth app",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              Column(
                children: <Widget>[
                  //login button
                  MaterialButton(
                    minWidth: double.infinity,
                    height: 60,
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => LoginPage()));
                    },
                    //defining the shape
                    shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.black),
                        borderRadius: BorderRadius.circular(50)),
                    child: Text(
                      "Login",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),

                  //signup button
                  SizedBox(height: 20),
                  MaterialButton(
                    minWidth: double.infinity,
                    height: 60,
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SignUpPage()));
                    },
                    color: Color(0xff0095FF),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50)),
                    child: Text(
                      "Sign Up",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    ));
  }
}
