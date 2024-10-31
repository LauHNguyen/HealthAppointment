
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'http://localhost:3000';

  Future<void> fetchData() async {
    final response = await http.get(Uri.parse('$baseUrl/api/endpoint'));
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      print(data);
    } else {
      throw Exception('Failed to load data');
    }
  }
}
