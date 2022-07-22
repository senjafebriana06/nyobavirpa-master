import '../models/weight_status_enum.dart';

WeightStatus stringToWeightStatus(String weightStatusString) {
  if (weightStatusString == "SEVERLYUNDERWEIGHT") {
    return WeightStatus.severlyUnderweight;
  } else if (weightStatusString == "UNDERWEIGHT") {
    return WeightStatus.underweight;
  } else if (weightStatusString == "NORMAL") {
    return WeightStatus.normal;
  }
  return WeightStatus.overweight;
}
