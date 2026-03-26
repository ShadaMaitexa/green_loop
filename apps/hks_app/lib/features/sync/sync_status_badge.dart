import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'sync_manager.dart';

class SyncStatusTitle extends StatelessWidget {
  final String originalTitle;

  const SyncStatusTitle({super.key, required this.originalTitle});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncManager>(
      builder: (context, syncManager, child) {
        final status = syncManager.status;
        final count = syncManager.pendingCount;

        if (status == SyncStatus.online && count == 0) {
          return Text(originalTitle);
        }

        String statusText;
        Color statusColor;
        IconData statusIcon;

        switch (status) {
          case SyncStatus.offline:
            statusText = count > 0 ? 'Offline Mode • $count Pending' : 'Offline Mode';
            statusColor = Colors.orange;
            statusIcon = Icons.wifi_off_rounded;
            break;
          case SyncStatus.syncing:
            statusText = 'Syncing... ($count pending)';
            statusColor = Colors.blue;
            statusIcon = Icons.sync_rounded;
            break;
          case SyncStatus.synced:
            statusText = 'Synced';
            statusColor = Colors.green;
            statusIcon = Icons.cloud_done_rounded;
            break;
          case SyncStatus.online:
            statusText = count > 0 ? 'Online • $count Pending' : 'Online';
            statusColor = Colors.grey;
            statusIcon = Icons.cloud_queue_rounded;
            break;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(originalTitle, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (status == SyncStatus.syncing)
                    SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: statusColor,
                      ),
                    )
                  else
                    Icon(statusIcon, size: 12, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
