import 'package:flutter/material.dart';

/// 공통 adaptive refresh 래퍼.
///
/// 다른 프로젝트에서도 그대로 가져다 쓸 수 있게,
/// `onRefresh`와 `child`만 받는 단순한 형태로 유지한다.
class AppRefreshIndicator extends StatelessWidget {
  const AppRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator.adaptive(onRefresh: onRefresh, child: child);
  }
}
