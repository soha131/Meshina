// time_state.dart
abstract class TravelState {}

class TravelInitial extends TravelState {}

class TravelLoading extends TravelState {}

class TravelSuccess extends TravelState {
  final double predictedTime;
  final double calculatedDistance;
  final String weather;
  final int hourOfDay;
  TravelSuccess(this.predictedTime, this.calculatedDistance, this.weather, this. hourOfDay);
}

class TravelError extends TravelState {
  final String errorMessage;

  TravelError(this.errorMessage);
}
