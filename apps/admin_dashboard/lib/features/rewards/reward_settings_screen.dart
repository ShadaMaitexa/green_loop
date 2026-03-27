import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:data_models/data_models.dart';
import 'reward_settings_state.dart';

class RewardSettingsScreen extends StatefulWidget {
  const RewardSettingsScreen({super.key});

  @override
  State<RewardSettingsScreen> createState() => _RewardSettingsScreenState();
}

class _RewardSettingsScreenState extends State<RewardSettingsScreen> {
  final _configFormKey = GlobalKey<FormState>();
  
  // Point Config Controllers
  late TextEditingController _cleanPickupController;
  late TextEditingController _contaminatedPickupController;
  late TextEditingController _streakBonusController;
  late TextEditingController _streakWeeksController;

  @override
  void initState() {
    super.initState();
    _cleanPickupController = TextEditingController();
    _contaminatedPickupController = TextEditingController();
    _streakBonusController = TextEditingController();
    _streakWeeksController = TextEditingController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RewardSettingsState>().fetchAll().then((_) {
        final config = context.read<RewardSettingsState>().config;
        if (config != null) {
          _updateControllers(config);
        }
      });
    });
  }

  void _updateControllers(RewardConfig config) {
    _cleanPickupController.text = config.pointsPerCleanPickup.toString();
    _contaminatedPickupController.text = config.pointsPerContaminatedPickup.toString();
    _streakBonusController.text = config.streakBonusPoints.toString();
    _streakWeeksController.text = config.streakWeeksRequired.toString();
  }

  @override
  void dispose() {
    _cleanPickupController.dispose();
    _contaminatedPickupController.dispose();
    _streakBonusController.dispose();
    _streakWeeksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RewardSettingsState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Reward System Settings')),
      body: state.isLoading && state.config == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(GLSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildConfigSection(context, state),
                  const SizedBox(height: GLSpacing.xxl),
                  _buildRewardsSection(context, state),
                ],
              ),
            ),
    );
  }

  Widget _buildConfigSection(BuildContext context, RewardSettingsState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(GLSpacing.lg),
        child: Form(
          key: _configFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Point Valuations',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: GLSpacing.md),
              const Text('Define how many points are awarded to residents for different activities.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: GLSpacing.xl),
              
              Row(
                children: [
                  Expanded(child: _buildPointInput('Clean Pickup Points', _cleanPickupController)),
                  const SizedBox(width: GLSpacing.lg),
                  Expanded(child: _buildPointInput('Contaminated Pickup Points', _contaminatedPickupController)),
                ],
              ),
              const SizedBox(height: GLSpacing.lg),
              Row(
                children: [
                  Expanded(child: _buildPointInput('Streak Bonus Points', _streakBonusController)),
                  const SizedBox(width: GLSpacing.lg),
                  Expanded(child: _buildPointInput('Streak Threshold (Weeks)', _streakWeeksController)),
                ],
              ),
              const SizedBox(height: GLSpacing.xl),
              GLButton(
                text: 'Save Point Config',
                onPressed: state.isLoading ? null : _saveConfig,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPointInput(String label, TextEditingController controller) {
    return GLTextField(
      label: label,
      controller: controller,
      keyboardType: TextInputType.number,
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
    );
  }

  Widget _buildRewardsSection(BuildContext context, RewardSettingsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Redemption Catalog',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            GLButton(
              text: 'Add New Reward',
              variant: GLButtonVariant.outline,
              onPressed: () => _showAddRewardDialog(context),
            ),
          ],
        ),
        const SizedBox(height: GLSpacing.md),
        const Text('Manage the items available in the user app for redemption.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: GLSpacing.lg),
        
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.rewards.length,
          separatorBuilder: (_, __) => const SizedBox(height: GLSpacing.md),
          itemBuilder: (context, index) {
            final reward = state.rewards[index];
            return _RewardListItem(reward: reward, onDelete: () => state.deleteReward(reward.id));
          },
        ),
      ],
    );
  }

  void _saveConfig() {
    if (_configFormKey.currentState!.validate()) {
      final newConfig = RewardConfig(
        pointsPerCleanPickup: int.parse(_cleanPickupController.text),
        pointsPerContaminatedPickup: int.parse(_contaminatedPickupController.text),
        streakBonusPoints: int.parse(_streakBonusController.text),
        streakWeeksRequired: int.parse(_streakWeeksController.text),
      );
      context.read<RewardSettingsState>().updateConfig(newConfig).then((success) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Configuration updated successfully!')),
          );
        }
      });
    }
  }

  void _showAddRewardDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final pointController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Reward'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GLTextField(label: 'Reward Name', controller: nameController),
            const SizedBox(height: GLSpacing.md),
            GLTextField(label: 'Description', controller: descController),
            const SizedBox(height: GLSpacing.md),
            GLTextField(label: 'Point Cost', controller: pointController, keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final newReward = Reward(
                id: DateTime.now().millisecondsSinceEpoch.toString(), // Temporary
                name: nameController.text,
                description: descController.text,
                pointCost: int.parse(pointController.text),
              );
              context.read<RewardSettingsState>().addReward(newReward).then((_) {
                Navigator.pop(context);
              });
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _RewardListItem extends StatelessWidget {
  final Reward reward;
  final VoidCallback onDelete;

  const _RewardListItem({required this.reward, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(reward.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${reward.description}\nCost: ${reward.pointCost} points'),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
