import 'package:flutter/material.dart';

class LoadingStateWidget<T> extends StatelessWidget {
  final Stream<T> stream;
  final Widget Function(T data) onData;
  final String emptyMessage;
  final IconData emptyIcon;
  final bool Function(T? data)? isEmpty;

  const LoadingStateWidget({
    super.key,
    required this.stream,
    required this.onData,
    required this.emptyMessage,
    this.emptyIcon = Icons.info_outline,
    this.isEmpty,
  });

  bool _isEmpty(T? data) {
    if (isEmpty != null) {
      return isEmpty!(data);
    }
    if (data == null) return true;
    if (data is List) return data.isEmpty;
    if (data is Map) return data.isEmpty;
    if (data is String) return data.isEmpty;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Stream error: ${snapshot.error}');
          debugPrint('Stack trace: ${snapshot.stackTrace}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Đã xảy ra lỗi: ${snapshot.error}',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // This will trigger a rebuild of the StreamBuilder
                    (context as Element).markNeedsBuild();
                  },
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Đang tải dữ liệu...'),
              ],
            ),
          );
        }

        if (_isEmpty(snapshot.data)) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(emptyIcon, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  emptyMessage,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return onData(snapshot.data as T);
      },
    );
  }
}
