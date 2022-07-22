import '../models/height_status_enum.dart';

HeightStatus stringToHeightStatus(String heightStatusString) {
  if (heightStatusString == "SEVERLYSTUNTED") {
    return HeightStatus.severlyStunted;
  } else if (heightStatusString == "STUNTED") {
    return HeightStatus.stunted;
  } else if (heightStatusString == "NORMAL") {
    return HeightStatus.normal;
  }
  return HeightStatus.tinggi;
}
