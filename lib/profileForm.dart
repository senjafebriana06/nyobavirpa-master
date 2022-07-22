import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:date_time_picker/date_time_picker.dart';
import 'package:flutter/material.dart';
import 'package:nyobavirpa/component/custom_radio_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/gender_enum.dart';

class ProfileForm extends StatefulWidget {
  const ProfileForm({Key? key}) : super(key: key);

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  Gender? _gender = Gender.L;
  TextEditingController nameInputController = TextEditingController();
  TextEditingController ageInputController = TextEditingController();
  late String dateOfBirth;

  ValueChanged<Gender?> _valueChangedHandler() {
    return (value) => setState(() => _gender = value!);
  }

  @override
  Widget build(BuildContext context) {
    SharedPreferences? prefs;

    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    void onSaveHandler() async {
      prefs = await SharedPreferences.getInstance();
      String? id = prefs?.getString("id");
      firestore.collection("users").doc(id).set({
        'name': nameInputController.text,
        'age': int.parse(ageInputController.text),
        'gender': _gender == Gender.L ? "L" : "P",
        'dateOfBirth': dateOfBirth,
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
                    hintText: "Masukan Nama Lengkap",
                    labelText: "Nama Lengkap",
                  ),
                  controller: nameInputController,
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    hintText: "Masukan Umur (dalam Bulan)",
                    labelText: "Umur",
                  ),
                  controller: ageInputController,
                  keyboardType: TextInputType.number,
                ),
                DateTimePicker(
                  initialValue: '',
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  dateLabelText: 'Date',
                  onChanged: (val) => dateOfBirth = val,
                ),
                Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(
                        height: 18.0,
                      ),
                      const Text(
                        "Jenis Kelamin",
                        style: TextStyle(fontSize: 18),
                      ),
                      MyRadioOption<Gender>(
                        value: Gender.L,
                        groupValue: _gender,
                        label: '1',
                        text: 'Laki-laki',
                        onChanged: _valueChangedHandler(),
                      ),
                      MyRadioOption<Gender>(
                        value: Gender.P,
                        groupValue: _gender,
                        label: '121',
                        text: 'Perempuan',
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
