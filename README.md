# multi_channel_report_plugin

支持 Android、iOS 和 OpenHarmony 的激活、注册和支付上报。要求 Flutter 3.38.1、Dart 3.10 或更高版本。

## 安装

在宿主 App 的 `pubspec.yaml` 中添加 Git 依赖。

```yaml
dependencies:
  multi_channel_report_plugin:
    git:
      url: https://github.com/ming0747/multi_channel_report_plugin.git
      ref: main
```

首次接入运行 `flutter pub get`。已接入的项目可运行 `flutter pub upgrade multi_channel_report_plugin` 拉取更新。

## 上报

用户同意隐私政策后，先用 `setParams` 配置上报地址和应用信息。每次上报时传入当前用户的 `userUniqueId`。

```dart
import 'package:multi_channel_report_plugin/multi_channel_report_plugin.dart';

Future<void> initReporting() async {
  await ReportUtil.setParams(
    ztReportBaseUrl: 'https://example.com/attribution',
    myReportBaseUrl: 'https://example.com/report',
    appid: 'your-app-id',
    channelName: 'your-channel',
    versionName: '1.0.0',
  );
}

Future<void> reportActivation(String userId) async {
  await ReportUtil.report(ReportEvent.activation, userUniqueId: userId);
}
```

注册用 `ReportEvent.register`，支付用 `ReportEvent.pay`。支付可附带 `vipName`、`amount`、`payMethod` 和 `productType`，值为字符串。

两路上报均使用 GET。接口返回的 JSON 中，`code` 为 `0`、`1000` 或 `200` 时表示成功。

Android 宿主需声明 `android.permission.INTERNET`。iOS 宿主需在 `Info.plist` 设置 `NSUserTrackingUsageDescription`。OpenHarmony 需使用支持 OHOS 的 Flutter SDK。
