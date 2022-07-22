import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nyobavirpa/models/gender_enum.dart';
import 'package:nyobavirpa/models/height_status_enum.dart';
import 'package:nyobavirpa/models/weight_status_enum.dart';

class GrowthModel {
  String name;
  Gender gender;
  int age;
  Timestamp date;
  String dateOfBirth;
  WeightStatus weightStatus;
  HeightStatus heightStatus;
  double weight;
  double height;
  double headSize;
  String headSizeStatus;

  GrowthModel({
    required this.name,
    required this.gender,
    required this.age,
    required this.date,
    required this.weightStatus,
    required this.heightStatus,
    required this.weight,
    required this.height,
    required this.dateOfBirth,
    required this.headSize,
    required this.headSizeStatus,
  });
}
