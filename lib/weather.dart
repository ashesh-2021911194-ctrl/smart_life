//a19b7650099c241d92bb2df2aceca770

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';

class WeatherData {
  final double temperature;
  final String condition;
  final String icon;
  final String advice;

  WeatherData({
    required this.temperature,
    required this.condition,
    required this.icon,
    required this.advice,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: json['temperature'].toDouble(),
      condition: json['condition'],
      icon: json['icon'],
      advice: json['advice'],
    );
  }
}

class WeatherService {
  final String baseUrl;
  final String token;

  WeatherService({required this.baseUrl, required this.token});

  Future<WeatherData> getWeatherData(String lat, String lon) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/weather?lat=$lat&lon=$lon'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return WeatherData.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to fetch weather data: ${response.statusCode}');
    }
  }
}




class WeatherWidget extends StatefulWidget {
  final String token;

  const WeatherWidget({super.key, required this.token});

  @override
  _WeatherWidgetState createState() => _WeatherWidgetState();
}



class _WeatherWidgetState extends State<WeatherWidget> {
  // Get platform implementation instance
  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
  
  WeatherData? _weatherData;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Get current location
      Position position = await _determinePosition();
      
      // Initialize weather service
      WeatherService weatherService = WeatherService(
        baseUrl: 'http://192.168.0.114:5000', // Replace with your actual API URL
        token: widget.token,
      );

      // Fetch weather data
      final weatherData = await weatherService.getWeatherData(
        position.latitude.toString(),
        position.longitude.toString(),
      );

      setState(() {
        _weatherData = weatherData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await _geolocatorPlatform.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location services are disabled.';
    }

    // Check permissions
    permission = await _geolocatorPlatform.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocatorPlatform.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permissions are denied.';
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw 'Location permissions are permanently denied.';
    }

    // Get current position
    return await _geolocatorPlatform.getCurrentPosition();
  }
  

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        color: Colors.black45,
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        color: Colors.black45,
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              "Weather unavailable",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.black45,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Weather Icon
            Icon(
              _getWeatherIcon(_weatherData!.icon),
              size: 50,
              color: Colors.white,
            ),
            const SizedBox(width: 20),
            // Weather Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "${_weatherData!.temperature}°C",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _weatherData!.condition,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _weatherData!.advice,
                    style: const TextStyle(
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getWeatherIcon(String iconCode) {
    switch (iconCode) {
      case 'clear':
        return Icons.wb_sunny;
      case 'rain':
        return Icons.grain;
      case 'clouds':
        return Icons.cloud;
      case 'snow':
        return Icons.ac_unit;
      case 'thunderstorm':
        return Icons.flash_on;
      default:
        return Icons.cloud;
    }
  }
}