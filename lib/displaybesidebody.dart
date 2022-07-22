import 'dart:convert' as convert;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:nyobavirpa/main.dart';
import 'package:nyobavirpa/service/height_status_getter_service.dart';
import 'package:nyobavirpa/service/height_status_to_string_service.dart';
import 'package:nyobavirpa/service/weight_status_getter_service.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "dart:math" show pi;

import 'models/gender_enum.dart';
import 'models/weight_status_enum.dart';
import 'service/weight_status_to_string_service.dart';

class SideBodyImage extends StatefulWidget {
  final String imagePath;

  const SideBodyImage({Key? key, required this.imagePath}) : super(key: key);

  @override
  State<SideBodyImage> createState() => _SideBodyImageState();
}

class _SideBodyImageState extends State<SideBodyImage> {
  SharedPreferences? prefs;

  String? processedImageUrl;
  bool processingImage = false;
  bool imageProcessed = false;
  String weightStatusString = "";
  String heightStatusString = "";

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  double getWeight(double a, double b, double t) {
    double bsa = (pi / 2) * ((a * b) + ((a + b) * t)) * 0.6 * 0.0001;
    return bsa * bsa * 3600 / t;
  }

  Future<String?> uploadImage(File image, String type, String id) async {
    firebase_storage.UploadTask task;

    task = firebase_storage.FirebaseStorage.instance
        .ref('images/$id/$type/${basename(image.path)}')
        .putFile(image);

    task.snapshotEvents.listen((firebase_storage.TaskSnapshot snapshot) {
      print('Task state: ${snapshot.state}');
      print(
          'Progress: ${(snapshot.bytesTransferred / snapshot.totalBytes) * 100} %');
    }, onError: (e) {
      print(task.snapshot);

      if (e.code == 'permission-denied') {
        print('User does not have permission to upload to this reference.');
      }
    });

    try {
      var dowurl = await (await task).ref.getDownloadURL();
      return dowurl.toString();
    } on firebase_core.FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        print('User does not have permission to upload to this reference.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Display the Picture')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Column(children: [
        if (!imageProcessed && !processingImage)
          Column(children: [
            Image.file(File(widget.imagePath)),
            ElevatedButton(
                onPressed: () async {
                  setState(() {
                    processingImage = true;
                  });
                  prefs = await SharedPreferences.getInstance();
                  String? id = prefs?.getString("id");
                  print("Upload Image");

                  String? result = await uploadImage(
                      File(widget.imagePath), 'besideBody', id ?? '');
                  print("Put result");
                  await firestore
                      .collection('users')
                      .doc(id)
                      .update({'besideBody': result});

                  var url =
                      Uri.parse('https://virpaflaskapp.azurewebsites.net/side');
                  print("Process image");
                  late String name;
                  late String gender;
                  late int age;
                  late String dateOfBirth;
                  late double headSize;

                  await firestore
                      .collection("users")
                      .doc(id)
                      .get()
                      .then((result) {
                    if (result.data()!['name'] != null &&
                        result.data()!['gender'] != null &&
                        result.data()!['age'] != null) {
                      name = result.data()!['name'];
                      gender = result.data()!['gender'];
                      age = result.data()!['age'];
                    }
                  });

                  await http
                      .post(url, body: {
                        'id': id,
                        'image_name': basename(widget.imagePath)
                      })
                      .then((response) => convert.jsonDecode(response.body)
                          as Map<String, dynamic>)
                      .then((jsonResponse) {
                        setState(() {
                          processingImage = false;
                          imageProcessed = true;
                          processedImageUrl = jsonResponse['result'];
                          weightStatusString = weightStatusToString(
                              weightStatusGetter(
                                  weight: getWeight(
                                      context.read<BsaState>().a,
                                      context.read<BsaState>().b,
                                      context.read<BsaState>().t),
                                  age: age,
                                  gender: gender == "L" ? Gender.L : Gender.P));
                          heightStatusString = heightStatusToString(
                              heightStatusGetter(
                                  height: context.read<BsaState>().t,
                                  age: age,
                                  gender: gender == "L" ? Gender.L : Gender.P));
                          context.read<BsaState>().setAVal = jsonResponse['a'];
                          context.read<BsaState>().setTVal = jsonResponse['t'];
                        });
                      });
                  context.read<BsaState>().setA = true;
                  print("Success");
                },
                child: Text('Lanjut'))
          ]),
        if (processingImage && !imageProcessed)
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        if (!processingImage && imageProcessed)
          Column(
            children: [
              Image.network(processedImageUrl!),
              ElevatedButton(
                onPressed: () async {
                  prefs = await SharedPreferences.getInstance();
                  String? id = prefs?.getString("id");

                  late String name;
                  late String gender;
                  late int age;
                  late String dateOfBirth;
                  late double headSize;
                  late String headSizeStatus;

                  await firestore
                      .collection("users")
                      .doc(id)
                      .get()
                      .then((result) {
                    if (result.data()!['name'] != null &&
                        result.data()!['gender'] != null &&
                        result.data()!['age'] != null &&
                        result.data()!['headSize'] != null &&
                        result.data()!['dateOfBirth'] != null) {
                      name = result.data()!['name'];
                      gender = result.data()!['gender'];
                      age = result.data()!['age'];
                      headSize = result.data()!['headSize'];
                      dateOfBirth = result.data()!['dateOfBirth'];
                      headSizeStatus = result.data()!['headSizeStatus'];
                    }
                  });

                  await firestore.collection("users").doc(id).update({
                    "growth": FieldValue.arrayUnion([
                      {
                        "age": age,
                        "gender": gender,
                        "name": name,
                        "weightStatus": weightStatusString,
                        "heightStatus": heightStatusString,
                        "time": DateTime.now(),
                        "weight": getWeight(
                            context.read<BsaState>().a,
                            context.read<BsaState>().b,
                            context.read<BsaState>().t),
                        "height": context.read<BsaState>().t,
                        "headSize": headSize,
                        "dateOfBirth": dateOfBirth,
                        "headSizeStatus": headSizeStatus,
                      },
                    ])
                  });
                  context.read<BsaState>().reset();
                  Navigator.of(context).pop(3);
                },
                child: Text("Lanjut"),
              ),
            ],
          ),
        if (context.read<BsaState>().a_set && context.read<BsaState>().b_set)
          Text("Berat badan " +
              getWeight(context.read<BsaState>().a, context.read<BsaState>().b,
                      context.read<BsaState>().t)
                  .toStringAsFixed(2) +
              " kg"),
        if (context.read<BsaState>().a_set && context.read<BsaState>().b_set)
          Text("Tinggi badan " +
              context.read<BsaState>().t.toStringAsFixed(2) +
              " cm"),
        if (context.read<BsaState>().a_set && context.read<BsaState>().b_set)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Text("Status Berat Badan :"), Text(weightStatusString)],
          ),
        if (context.read<BsaState>().a_set && context.read<BsaState>().b_set)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Text("Status Tinggi Badan :"), Text(heightStatusString)],
          ),
      ]),
    );
  }
}
