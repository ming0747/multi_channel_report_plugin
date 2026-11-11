# multi_channel_report_plugin

提供 Android、iOS 和 OpenHarmony 的激活、注册和支付事件上报。Dart 接口为 `ReportUtil`。Android OAID 和 User-Agent 依赖放在 `third_party/`。

## 本地接入

在宿主 App 的 `pubspec.yaml` 里添加依赖。下面假设宿主与本项目在同一个父目录下。

```yaml
dependencies:
  multi_channel_report_plugin:
    path: ../multi_channel_report_plugin
```

运行 `flutter pub get` 后，在 App 中使用。

```dart
import 'package:multi_channel_report_plugin/multi_channel_report_plugin.dart';

Future<void> reportActivation(String userId) async {
  await ReportUtil.setParams(
    ztReportBaseUrl: 'https://example.com/attribution',
    myReportBaseUrl: 'https://example.com/report',
    appid: 'your-app-id',
    channelName: 'your-channel',
    versionName: '1.0.0',
    userUniqueId: userId,
  );

  await ReportUtil.report(ReportEvent.activation);
}
```

在 Flutter 完成初始化后调用 `report`。它读取设备信息并启动两路 GET 请求。接口应返回 JSON 对象，`code` 为 `0` 或 `1000` 表示成功。

Android 宿主需在主 Manifest 中声明 `android.permission.INTERNET`。iOS 宿主需在 `ios/Runner/Info.plist` 设置 `NSUserTrackingUsageDescription`，用于系统跟踪授权提示。OpenHarmony 使用支持 OHOS 的 Flutter SDK。

设备信息依赖要求 Flutter 3.38.1 和 Dart 3.10 或更高版本。Android 和 iOS 通过 `device_info_plus` 读取设备信息，OpenHarmony 通过 `device_info_plus_harmonyos` 读取型号和 ODID。

## GitHub 接入

推送仓库后，可以把上面的本地依赖换成 Git 依赖。将 URL 和 `ref` 换成你的仓库地址和版本标签。

```yaml
dependencies:
  multi_channel_report_plugin:
    git:
      url: https://github.com/YOUR_GITHUB_NAME/multi_channel_report_plugin.git
      ref: v0.0.1
```
