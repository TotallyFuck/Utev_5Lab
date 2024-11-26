import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(WeatherApp());
}

class WeatherApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather Forecast',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: WeatherHomePage(),
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  @override
  _WeatherHomePageState createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final List<String> cities = [
    'Uray HMAO',
    'Khanty-Mansiysk',
    'Moscow',
    'Tumen',
    'Ekaterinburg',
    'London'
  ];
  String selectedCity = 'Uray HMAO';
  Map<String, dynamic>? weatherData;
  List<dynamic>? forecastData;

  final String apiKey = 'f8ddac1b8ae04aa29d9192345240911';

  @override
  void initState() {
    super.initState();
    fetchWeatherData(selectedCity);
  }

  Future<void> fetchWeatherData(String city) async {
    try {
      final currentWeatherResponse = await http.get(Uri.parse(
          'https://api.weatherapi.com/v1/current.json?key=$apiKey&q=$city'));

      final forecastResponse = await http.get(Uri.parse(
          'https://api.weatherapi.com/v1/forecast.json?key=$apiKey&q=$city&days=7'));

      if (currentWeatherResponse.statusCode == 200 &&
          forecastResponse.statusCode == 200) {
        setState(() {
          weatherData = json.decode(currentWeatherResponse.body);
          forecastData =
              json.decode(forecastResponse.body)['forecast']['forecastday'];
        });
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load weather data')));
    }
  }

  String getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return '☀️';
      case 'partly cloudy':
        return '🌤️';
      case 'light freezing rain':
        return '💧';
      case 'light snow showers':
        return '☃️';
      case 'patchy rain nearby':
      case 'moderate rain':
        return '🌧️';
      case 'snow':
      case 'light snow':
      case 'blowing snow':
      case 'patchy moderate snow':
      case 'moderate snow':
      case 'moderate or heavy snow showers':
        return '❄️';
      default:
        return '☁️';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather Forecast'),
      ),
      body: weatherData == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: DropdownButton<String>(
                      value: selectedCity,
                      items: cities.map((city) {
                        return DropdownMenuItem(
                          value: city,
                          child: Text(city),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedCity = value;
                          });
                          fetchWeatherData(value);
                        }
                      },
                    ),
                  ),
                  Card(
                    elevation: 8,
                    margin: EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            weatherData!['location']['name'],
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${weatherData!['current']['temp_c'].round()}°C',
                            style: TextStyle(
                                fontSize: 48, fontWeight: FontWeight.w500),
                          ),
                          SizedBox(height: 8),
                          Text(
                            getWeatherIcon(
                                weatherData!['current']['condition']['text']),
                            style: TextStyle(fontSize: 64),
                          ),
                          SizedBox(height: 8),
                          Text(
                            weatherData!['current']['condition']['text'],
                            style: TextStyle(fontSize: 20),
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Icon(Icons.water_drop, color: Colors.blue),
                                  Text('Влажность'),
                                  Text(
                                      '${weatherData!['current']['humidity']}%'),
                                ],
                              ),
                              Column(
                                children: [
                                  Icon(Icons.speed, color: Colors.green),
                                  Text('Давление'),
                                  Text(
                                      '${weatherData!['current']['pressure_mb'] * 0.75} мм ртут столб'),
                                ],
                              ),
                              Column(
                                children: [
                                  Icon(Icons.air, color: Colors.orange),
                                  Text('Ветер'),
                                  Text(
                                      '${weatherData!['current']['wind_kph']} км/ч'),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  ExpansionTile(
                    title: Text('Почасовой прогноз'),
                    children: forecastData != null
                        ? forecastData!.take(2).expand((day) {
                            DateTime now = DateTime.now();
                            // ignore: unused_local_variable
                            DateTime forecastDate = DateTime.parse(day['date']);

                            return (day['hour'] as List)
                                .where((hourData) {
                                  DateTime hourDateTime =
                                      DateTime.parse(hourData['time']);
                                  return hourDateTime.isAfter(now);
                                })
                                .take(24)
                                .map((hourData) {
                                  DateTime dateTime =
                                      DateTime.parse(hourData['time']);
                                  String formattedDateTime =
                                      DateFormat('dd.MM.yy HH:mm')
                                          .format(dateTime);

                                  return ListTile(
                                    leading: Text(getWeatherIcon(
                                        hourData['condition']['text'])),
                                    title: Text(formattedDateTime),
                                    subtitle: Text(
                                      '${hourData['temp_c'].round()}°C, ${hourData['condition']['text']}',
                                    ),
                                  );
                                })
                                .toList();
                          }).toList()
                        : [Text('Нет данных о почасовом прогнозе')],
                  ),
                ],
              ),
            ),
    );
  }
}
