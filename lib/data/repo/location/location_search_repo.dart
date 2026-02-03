import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'package:ovorideuser/core/utils/url_container.dart';
import 'package:ovorideuser/data/services/api_client.dart';

import '../../../core/utils/method.dart';
import '../../../environment.dart';
import '../../model/location/prediction.dart';

class LocationSearchRepo {
  ApiClient apiClient;
  LocationSearchRepo({required this.apiClient});

  Future<String?> getActualAddress(double lat, double lng) async {
    final apiKey = Environment.mapKey;
    final url = '${UrlContainer.googleMapLocationSearch}/geocode/json?latlng=$lat,$lng&key=$apiKey';

    final response = await apiClient.request(url, Method.getMethod, null);

    if (response.statusCode == 200) {
      final data = response.responseJson;

      // Prefer a meaningful formatted_address
      if (data['results'] != null && data['results'].isNotEmpty) {
        for (var result in data['results']) {
          final types = result['types'];
          if (types != null && (types.contains('street_address') || types.contains('premise') || types.contains('subpremise') || types.contains('route') || types.contains('locality'))) {
            return result['formatted_address'];
          }
        }

        // Fallback to first result's address if no specific types found
        return data['results'][0]['formatted_address'];
      }

      // Final fallback: Plus Code
      if (data['plus_code'] != null && data['plus_code']['compound_code'] != null) {
        return data['plus_code']['compound_code'];
      }
    }

    return null; // or return 'Unknown Location';
  }

  Future<dynamic> searchAddressByLocationName({
    String text = '',
    List<String>? countries,
  }) async {
    printD(apiClient.getOperatingCountries());
    List<String> codes = apiClient
        .getOperatingCountries()
        .map(
          (e) => 'country:${e.countryCode ?? Environment.defaultCountryCode}',
        )
        .toList();
    printD(codes);

    String url = '${UrlContainer.googleMapLocationSearch}/place/autocomplete/json?input=$text&key=${Environment.mapKey}&components=${codes.join('|')}&language=en';
    printX(url);

    if (countries != null) {
      for (int i = 0; i < countries.length; i++) {
        final country = countries[i];

        if (i == 0) {
          url = "$url&components=country:$country";
        } else {
          url = "$url|country:$country";
        }
      }
    }

    final response = await apiClient.request(url, Method.getMethod, null);
    return response;
  }

  Future<dynamic> getPlaceDetailsFromPlaceId(Prediction prediction) async {
    final url = "${UrlContainer.googleMapLocationSearch}/place/details/json?placeid=${prediction.placeId}&key=${Environment.mapKey}";

    final response = await apiClient.request(url, Method.getMethod, null);
    return response;
  }
}
