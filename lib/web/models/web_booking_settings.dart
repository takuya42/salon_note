const String webBookingEnabledField = 'isWebBookingEnabled';

/// Keeps web booking available for shops created before the booking toggle was
/// introduced. An explicit value still takes precedence, so shops can disable
/// web booking by storing `false`.
bool readWebBookingEnabled(Map<String, dynamic> data) {
  if (!data.containsKey(webBookingEnabledField)) {
    return true;
  }

  return data[webBookingEnabledField] == true;
}
