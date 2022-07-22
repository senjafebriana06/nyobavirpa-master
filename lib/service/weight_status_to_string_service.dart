import '../models/weight_status_enum.dart';

String weightStatusToString(WeightStatus weightStatus) {
  if (weightStatus == WeightStatus.severlyUnderweight) {
    return "SEVERLYUNDERWEIGHT";
  } else if (weightStatus == WeightStatus.underweight) {
    return "UNDERWEIGHT";
  } else if (weightStatus == WeightStatus.normal) {
    return "NORMAL";
  }
  return "OVERWEIGHT";
}
