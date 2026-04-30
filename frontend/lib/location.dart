import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' show cos, sqrt, asin;
import 'package:iattend_frontend/utils/constants.dart';

class LocationService 
{
  
  Future<bool> verifyStudentLocation(String sessionId) async 
  {
    try 
    {
      Position studentPos = await _getCurrentLocation();
      Map<String, double>? roomPos = await _getRoomLocationFromServer(sessionId);
      
      if (roomPos == null) return false;
      double distanceInMeters = _calculateDistance(
        studentPos.latitude,
        studentPos.longitude,
        roomPos['lat']!,
        roomPos['lng']!,
      );
      const double bufferZone = 50.0; 
      return distanceInMeters <= bufferZone;

    } 
    catch (e) 
    {
      return false;
    }
  }

  Future<Position> _getCurrentLocation() async 
  {
    bool serviceEnabled;
    LocationPermission permission;
    
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) 
    {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return Future.error('Permission denied');
    }
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high
    );
  }

  Future<Map<String, double>?> _getRoomLocationFromServer(String sessionId) async 
  {
    try 
    {
      final response = await http.get(
      Uri.parse('${ApiConstsnts.baseUrl}${ApiConstsnts.getSessionLocation}$sessionId'),
      );

      if (response.statusCode == 200)
       {
        final data = jsonDecode(response.body);
        return 
        {
          'lat': double.parse(data['latitude'].toString()),
          'lng': double.parse(data['longitude'].toString()),
        };
      }
    } 
    catch (e) 
    {
      throw Exception("Failed to fetch room location:$e");
    }
    return null;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) 
  {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000; 
  }
  
}