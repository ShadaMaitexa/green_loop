import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';

class HksResourcesScreen extends StatelessWidget {
  const HksResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<Map<String, String>> resources = [
      {
        'title': 'HKS App Guide (Malayalam)',
        'subtitle': 'Learn how to use GreenLoop HKS app',
        'type': 'PDF',
        'url': 'https://storage.greenloop.app/guides/hks_guide_ml.pdf',
        'icon': 'menu_book_rounded',
      },
      {
        'title': 'Waste Segregation SOP',
        'subtitle': 'Official guidelines for ULB workers',
        'type': 'PDF',
        'url': 'https://storage.greenloop.app/guides/segregation_sop.pdf',
        'icon': 'recycling_rounded',
      },
      {
        'title': 'Safety & PPE Procedures',
        'subtitle': 'Guidelines for health and safety',
        'type': 'IMAGE',
        'url': 'https://storage.greenloop.app/guides/safety_infographic.png',
        'icon': 'security_rounded',
      },
      {
        'title': 'Emergency Contact List',
        'subtitle': 'Kochi ULB helpdesk and emergency',
        'type': 'PHONE',
        'url': '0484-1234567',
        'icon': 'support_agent_rounded',
      },
    ];

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Resources'),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(GLSpacing.lg),
        itemCount: resources.length,
        itemBuilder: (context, index) {
          final res = resources[index];
          return _buildResourceCard(context, res);
        },
      ),
    );
  }

  Widget _buildResourceCard(BuildContext context, Map<String, String> res) {
    final theme = Theme.of(context);
    final iconData = _getIconData(res['icon']!);

    return Card(
      margin: const EdgeInsets.only(bottom: GLSpacing.md),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GLRadius.lg)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(GLSpacing.md),
        leading: Container(
          padding: const EdgeInsets.all(GLSpacing.sm),
          decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(GLRadius.md)),
          child: Icon(iconData, color: theme.colorScheme.primary),
        ),
        title: Text(res['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(res['subtitle']!),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
          child: Text(res['type']!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        onTap: () => _handleAction(context, res),
      ),
    );
  }

  void _handleAction(BuildContext context, Map<String, String> res) async {
    final url = Uri.parse(res['url']!);
    if (res['type'] == 'PHONE') {
      final telUrl = Uri.parse('tel:${res['url']}');
      if (await canLaunchUrl(telUrl)) await launchUrl(telUrl);
    } else {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open resource.')));
        }
      }
    }
  }

  IconData _getIconData(String key) {
    switch (key) {
      case 'menu_book_rounded': return Icons.menu_book_rounded;
      case 'recycling_rounded': return Icons.recycling_rounded;
      case 'security_rounded': return Icons.security_rounded;
      case 'support_agent_rounded': return Icons.support_agent_rounded;
      default: return Icons.insert_drive_file_rounded;
    }
  }
}
