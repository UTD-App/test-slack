import 'package:utd_app/network/network.dart'; // ApiClient, FormData, MultipartFile
import 'package:utd_studio_sdk/utd_studio_sdk.dart';

/// [StacTransport] over the Base app's Dio client. Only the JSON the SDUI
/// runtime needs travels through here; files are passed by path so the SDK
/// never imports `dio`.
class DioStacTransport implements StacTransport {
  const DioStacTransport();

  @override
  Future<dynamic> getJson(String path, {Map<String, dynamic>? query}) async {
    final res = await ApiClient.instance.dio.get(path, queryParameters: query);
    return res.data;
  }

  @override
  Future<dynamic> postForm(
    String path, {
    Map<String, String> fields = const {},
    String? filePath,
    String? fileField,
    String? fileName,
  }) async {
    final map = <String, dynamic>{...fields};
    if (filePath != null) {
      map[fileField ?? 'image'] =
          await MultipartFile.fromFile(filePath, filename: fileName);
    }
    final res =
        await ApiClient.instance.dio.post(path, data: FormData.fromMap(map));
    return res.data;
  }

  @override
  String get origin {
    var base = ApiClient.instance.dio.options.baseUrl;
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    if (base.endsWith('/api')) base = base.substring(0, base.length - 4);
    return base;
  }
}
