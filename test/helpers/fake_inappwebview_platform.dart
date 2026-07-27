import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview_platform_interface/flutter_inappwebview_platform_interface.dart';

/// A minimal [InAppWebViewPlatform] for widget tests.
///
/// It renders a placeholder in place of the real native web view so that
/// widgets embedding [InAppWebView] can be pumped without a platform
/// implementation. Only the widget-creation path is stubbed; all other platform
/// features throw their default `UnimplementedError`.
class FakeInAppWebViewPlatform extends InAppWebViewPlatform {
  @override
  PlatformInAppWebViewWidget createPlatformInAppWebViewWidget(
    PlatformInAppWebViewWidgetCreationParams params,
  ) {
    return _FakePlatformInAppWebViewWidget(params);
  }
}

class _FakePlatformInAppWebViewWidget extends PlatformInAppWebViewWidget {
  _FakePlatformInAppWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) => const SizedBox.expand();

  @override
  T controllerFromPlatform<T>(PlatformInAppWebViewController controller) =>
      controller as T;

  @override
  void dispose() {}
}
