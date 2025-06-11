// travel_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../service.dart';
import 'time_model.dart';
import 'time_state.dart';

class TravelCubit extends Cubit<TravelState> {
  final TravelService travelService;

  TravelCubit(this.travelService) : super(TravelInitial());

  Future<void> predictTravelTime(TravelData data) async {
    emit(TravelLoading());
    try {
      final response = await travelService.predictTravelTime(data);

      final predictedTime = response.predictedDurationMin;
      final calculatedDistance = response.distanceKm;
      final predictedWeather = response.weather;
      final hourOfDay = response.hourOfDay;


      emit(TravelSuccess(predictedTime, calculatedDistance,predictedWeather,hourOfDay));
    } catch (e) {
      emit(TravelError(e.toString()));
    }
  }
}
