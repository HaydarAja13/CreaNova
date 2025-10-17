class AppConfig {
  // TODO: isi dari file .env / secrets manager
  static const String googlePlacesKey = String.fromEnvironment('PLACES_KEY', defaultValue: '');
  static const String googleStaticMapsKey = String.fromEnvironment('STATIC_MAPS_KEY', defaultValue: '');
  static const String googleMapsKey = String.fromEnvironment('MAPS_KEY', defaultValue: '');
}
