import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:date_time_picker/date_time_picker.dart';
import 'package:flutter/material.dart';
import 'package:nyobavirpa/component/custom_radio_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/gender_enum.dart';

class HeadSizeForm extends StatefulWidget {
  const HeadSizeForm({Key? key}) : super(key: key);

  @override
  State<HeadSizeForm> createState() => _HeadSizeFormState();
}

class _HeadSizeFormState extends State<HeadSizeForm> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController nameInputController = TextEditingController();
  TextEditingController ageInputController = TextEditingController();
  TextEditingController headInputController = TextEditingController();
  late String dateOfBirth;
  String? _headSizeStatus = "Normal";

  ValueChanged<String?> _valueChangedHandler() {
    return (value) => setState(() => _headSizeStatus = value!);
  }

  @override
  Widget build(BuildContext context) {
    SharedPreferences? prefs;

    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    void onSaveHandler() async {
      prefs = await SharedPreferences.getInstance();
      String? id = prefs?.getString("id");
      firestore.collection("users").doc(id).set({
        'headSize': double.parse(headInputController.text),
        'headSizeStatus': _headSizeStatus,
      }, SetOptions(merge: true)).then((value) {
        int count = 0;
        Navigator.of(context).popUntil((_) => count++ >= 2);
      }).catchError((error) => print("Failed $error"));
    }

    return Scaffold(
      body: SafeArea(
        child: Form(
          child: Container(
            padding: EdgeInsets.all(20.0),
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    hintText: "Masukan Lingkar Kepala (dalam cm)",
                    labelText: "Lingkar Kepala",
                  ),
                  controller: headInputController,
                  keyboardType: TextInputType.number,
                ),
                Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(
                        height: 18.0,
                      ),
                      const Text(
                        "Status Lingkar Kepala",
                        style: TextStyle(fontSize: 18),
                      ),
                      MyRadioOption<String>(
                        value: "Dibawah Normal",
                        groupValue: _headSizeStatus,
                        label: '1',
                        text: "Dibawah Normal",
                        onChanged: _valueChangedHandler(),
                      ),
                      MyRadioOption<String>(
                        value: "Normal",
                        groupValue: _headSizeStatus,
                        label: '2',
                        text: 'Normal',
                        onChanged: _valueChangedHandler(),
                      ),
                      MyRadioOption<String>(
                        value: "Diatas Normal",
                        groupValue: _headSizeStatus,
                        label: '1',
                        text: "Diatas Normal",
                        onChanged: _valueChangedHandler(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 18.0,
                ),
                InkWell(
                  child: Container(
                    child: const Center(
                      child: Text(
                        "Simpan",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    color: Color(0xff0095FF),
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    width: double.infinity,
                  ),
                  onTap: onSaveHandler,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
