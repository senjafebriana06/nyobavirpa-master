import '../models/height_status_enum.dart';

String heightStatusToString(HeightStatus heightStatus) {
  if (heightStatus == HeightStatus.severlyStunted) {
    return "SEVERLYSTUNTED";
  } else if (heightStatus == HeightStatus.stunted) {
    return "STUNTED";
  } else if (heightStatus == HeightStatus.normal) {
    return "NORMAL";
  }
  return "TINGGI";
}
