import 'dart:convert';
import 'dart:io';
import 'package:android_cn_oaid/android_cn_oaid.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:device_info_plus_harmonyos/device_info_plus_harmonyos.dart'
    as harmony;
import 'package:dio/dio.dart';
import 'package:fk_user_agent/fk_user_agent.dart';
import 'package:fk_user_agent_ohos/fk_user_agent_ohos.dart';
import 'package:flutter_udid/flutter_udid.dart';

enum ReportEvent { activation, register, pay }

// 上报工具
class ReportUtil {

  static final Dio _dio = Dio();

  /// 公共参数
  static String _udid = '';
  static String _androidId = '';
  static String _odid = '';
  static String _idfa = '';
  static String _idfv = '';
  static String _oaid = '';
  static String _deviceModel = '';
  static String _userAgent = '';
  static String _userUniqueId = '';
  static String _versionName = '';
  static String _channelName = '';
  static String _appid = '';
  static String _osName = '';
  static String _ztReportBaseUrl = '';
  static String _myReportBaseUrl = '';

  /// 内部参数
  static String _vipName     = '';
  static String _amount      = '';
  static String _payMethod   = '';
  static String _productType = '';

  static bool get isHarmonyOS => Platform.operatingSystem == 'ohos';

  static Future setParams({
    required String ztReportBaseUrl,
    required String myReportBaseUrl,
    required String appid,
    required String channelName,
    required String versionName,
  }) async {
    _ztReportBaseUrl = ztReportBaseUrl;
    _myReportBaseUrl = myReportBaseUrl;
    _versionName = versionName;
    _channelName = channelName;
    _appid = appid;
  }

  static Future report(ReportEvent event, {
    required String userUniqueId,
    String? vipName,
    String? amount,
    String? payMethod,
    String? productType
  }) async {

    _userUniqueId = userUniqueId;

    if ((vipName ?? "").isNotEmpty) {
      _vipName = vipName!;
    }

    if ((amount ?? "").isNotEmpty) {
      _amount = amount!;
    }

    if ((payMethod ?? "").isNotEmpty) {
      _payMethod = payMethod!;
    }

    if ((productType ?? "").isNotEmpty) {
      _productType = productType!;
    }

    _getOsName();
    await Future.wait(
      <Future<void>>[
        _getUdid(),
        _getAndroidId(),
        _getOdid(),
        _getIdfa(),
        _getIdfv(),
        _getOaid(),
        _getDeviceModel(),
        _getUserAgent(),
      ]
    );
    requestReport(event, _ztReportBaseUrl);
    requestReport(event, _myReportBaseUrl);
  }

  /// 上报归因
  static String reportUrl(ReportEvent event, String baseUrl) {
    final reportParam = <String, String>{};
    reportParam["app_id"] = _appid;
    reportParam["os_name"] = _osName;
    reportParam["event_name"] = event.name;
    reportParam["udid"] = _udid;
    reportParam["android_id"] = _androidId;
    reportParam["odid"] = _odid;
    reportParam["idfa"] = _idfa;
    reportParam["idfv"] = _idfv;
    reportParam["oaid"] = _oaid;
    reportParam["user_unique_id"] = _userUniqueId;
    reportParam["time"] = DateTime.now().millisecondsSinceEpoch.toString();
    reportParam["device_model"] = _deviceModel;
    reportParam["brand"] = _userAgent;
    reportParam["app_version"] = _versionName;
    reportParam["app_name"] = _channelName;

    if (_vipName.isNotEmpty) {
      reportParam["vipName"] = _vipName;
    }

    if (_amount.isNotEmpty) {
      reportParam["amount"] = _amount;
    }

    if (_payMethod.isNotEmpty) {
      reportParam["payMethod"] = _payMethod;
    }

    if (_productType.isNotEmpty) {
      reportParam["productType"] = _productType;
    }

    final uri = Uri.parse(baseUrl);
    return uri.replace(queryParameters: {...uri.queryParametersAll, ...reportParam}).toString();
  }

  static String _getOsName() {
    if (isHarmonyOS) {
      _osName = "ohos";
    } else {
      _osName = Platform.isAndroid ? 'android' : 'ios';
    }
    return _osName;
  }

  static Future<String> _getAndroidIdValue() async{
    final plugin = AndroidCnOaid();
    // 用户同意隐私政策后调用
    await plugin.register();
    final androidId = await plugin.getAndroidID(); // String? — 可能为 null
    return androidId ?? "";
  }


  static Future<String> _getUdid() async {
    if (_udid.isEmpty) {
      String udid = "";
      if (Platform.isAndroid) {
        udid = await _getAndroidIdValue();
      } else if (Platform.isIOS) {
        IosDeviceInfo deviceInfo = await DeviceInfoPlugin().iosInfo;
        udid = deviceInfo.identifierForVendor ?? "";
      } else if (isHarmonyOS) {
        final deviceInfo = await harmony.DeviceInfoPlusOhosPlugin().ohosInfo;
        udid = deviceInfo.odId;
      }
      _udid = udid;
    }
    return _udid;
  }





  static Future<String> _getAndroidId() async {
    if (_androidId.isEmpty) {
      String androidId = "";
      DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        androidId = await _getAndroidIdValue();
      } else if (Platform.isIOS) {
        IosDeviceInfo deviceInfo = await deviceInfoPlugin.iosInfo;
        androidId = deviceInfo.identifierForVendor ?? "";
      } else if (isHarmonyOS) {
        androidId = "";
      }
      _androidId = androidId;
    }
    return _androidId;
  }

  static Future<String> _getOdid() async {
    if (_odid.isEmpty) {
      String odid = "";
      if (Platform.isAndroid) {
        odid = await _getAndroidIdValue();
      } else if (Platform.isIOS) {
        IosDeviceInfo deviceInfo = await DeviceInfoPlugin().iosInfo;
        odid = deviceInfo.identifierForVendor ?? "";
      } else if (isHarmonyOS) {
        final deviceInfo = await harmony.DeviceInfoPlusOhosPlugin().ohosInfo;
        odid = deviceInfo.odId;
      }
      _odid = odid;
    }
    return _udid;
  }

  static Future<String> _getIdfa() async {
    if (_idfa.isEmpty) {
      String idfa = "";
      if (Platform.isAndroid) {
        idfa = "";
      } else if (Platform.isIOS) {
        final TrackingStatus status =
        await AppTrackingTransparency.trackingAuthorizationStatus;
        if (status == TrackingStatus.notDetermined) {
          await AppTrackingTransparency.requestTrackingAuthorization();
        }

        idfa = await AppTrackingTransparency.getAdvertisingIdentifier();
      } else if (isHarmonyOS) {
        idfa = "";
      }
      _idfa = idfa;
    }
    return _idfa;
  }

  static Future<String> _getIdfv() async {
    if (_idfv.isEmpty) {
      String idfv = "";
      DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        idfv = await _getAndroidIdValue();
      } else if (Platform.isIOS) {
        IosDeviceInfo deviceInfo = await deviceInfoPlugin.iosInfo;
        idfv = deviceInfo.identifierForVendor ?? "";
      } else if (isHarmonyOS) {
        idfv = "";
      }
      _idfv = idfv;
    }
    return _idfv;
  }

  static Future<String> _getOaid() async {
    if (_oaid.isEmpty) {
      String oaid = "";
      if (Platform.isAndroid) {
        final plugin = AndroidCnOaid();
        // 用户同意隐私政策后调用
        await plugin.register();
        final supported = await plugin.isSupported();
        if (!supported) {
          // 当前设备不支持 OAID 或 AAID
          print("当前设备不支持 OAID 或 AAID");
          oaid = "";
        }else{
          try {
            // 自动选择最优方式获取
            oaid = await plugin.getOAID() ?? "";
            print('OAID: $oaid');

          } on OaidException catch (e) {
            print('获取OAID错误 [${e.code}]: ${e.message}');
          }
        }

      } else if (Platform.isIOS) {
        oaid = "";
      } else if (isHarmonyOS) {
        oaid = await FlutterUdid.udid;
      }
      _oaid = oaid;
    }
    return _oaid;
  }

  static Future<String> _getDeviceModel() async {
    if (_deviceModel.isEmpty) {
      String deviceModel = "";
      if (Platform.isAndroid) {
        AndroidDeviceInfo deviceInfo = await DeviceInfoPlugin().androidInfo;
        deviceModel = deviceInfo.model;
      } else if (Platform.isIOS) {
        IosDeviceInfo deviceInfo = await DeviceInfoPlugin().iosInfo;
        deviceModel = deviceInfo.utsname.machine;
      } else if (isHarmonyOS) {
        final deviceInfo = await harmony.DeviceInfoPlusOhosPlugin().ohosInfo;
        deviceModel = deviceInfo.productModel;
      }
      _deviceModel = deviceModel;
    }
    return _deviceModel;
  }

  static Future<String> _getUserAgent() async {
    if (_userAgent.isEmpty) {
      if (isHarmonyOS) {
        await FkUserAgentOhos.init();
        _userAgent = FkUserAgentOhos.userAgent ?? "";
      } else {
        await FkUserAgent.init();
        _userAgent = FkUserAgent.userAgent ?? "";
      }
    }
    return _userAgent;
  }

  /// 请求上报
  static Future requestReport(ReportEvent event, String baseUrl) async {
    String url = reportUrl(event, baseUrl);

    print("【ReportUtil 上报地址】：$url");

    int retryCount = 5; // 5

    for (int i = 0; i < retryCount; i++) {
      print("尝试第${i}");
      try {
        final response = await _dio.get<String>(
          url,
          options: Options(responseType: ResponseType.plain),
        );
        final result = jsonDecode(response.data!) as Map<String, dynamic>;
        final code = int.tryParse('${result['code']}');
        final message = result['message'] ?? result['msg'] ?? '';

        if (code == 0 || code == 1000 || code == 200) {
          print('report $event success');
          return; // 成功后直接返回
        } else {
          print(
            'report $event failed, attempt ${i + 1}/$retryCount, error: $message',
          );
        }
      } catch (e) {
        print('report $event error, attempt ${i + 1}/$retryCount: $e');
      }

      // 最后一次失败后不再延迟
      await Future.delayed(const Duration(milliseconds: 3000));
    }
  }
}
