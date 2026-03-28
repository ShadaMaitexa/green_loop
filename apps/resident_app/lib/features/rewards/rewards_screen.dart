import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:data_models/data_models.dart';
import 'rewards_state.dart';
import 'package:intl/intl.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _counterController;
  late Animation<int> _pointsAnimation;
  int _prevPoints = 0;

  @override
  void initState() {
    super.initState();
    _counterController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pointsAnimation = IntTween(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _counterController, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RewardsState>().fetchAll();
    });
  }

  @override
  void dispose() {
    _counterController.dispose();
    super.dispose();
  }

  void _updateAnimation(int newPoints) {
    if (newPoints != _prevPoints) {
      _pointsAnimation = IntTween(begin: _prevPoints, end: newPoints).animate(
        CurvedAnimation(parent: _counterController, curve: Curves.easeOut),
      );
      _counterController.reset();
      _counterController.forward();
      _prevPoints = newPoints;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RewardsState>();
    final profile = state.profile;

    if (profile != null && profile.pointsBalance != _prevPoints) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateAnimation(profile.pointsBalance);
      });
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Rewards & Points'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Available Rewards'),
              Tab(text: 'Earning History'),
            ],
          ),
        ),
        body: state.isLoading && profile == null
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _RewardsTab(profile: profile, state: state, pointsAnimation: _pointsAnimation),
                  _HistoryTab(history: state.history),
                ],
              ),
      ),
    );
  }
}

class _RewardsTab extends StatelessWidget {
  final ResidentProfile? profile;
  final RewardsState state;
  final Animation<int> pointsAnimation;

  const _RewardsTab({
    required this.profile,
    required this.state,
    required this.pointsAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => state.fetchAll(),
      child: ListView(
        padding: const EdgeInsets.all(GLSpacing.lg),
        children: [
          // Points Card
          _PointsCard(profile: profile, pointsAnimation: pointsAnimation),
          const SizedBox(height: GLSpacing.lg),

          // Streak Counter
          if (profile != null) _StreakCard(streakWeeks: profile!.streakWeeks),
          const SizedBox(height: GLSpacing.lg),

          Text(
            'Available Rewards',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: GLSpacing.md),

          if (state.availableRewards.isEmpty && !state.isLoading)
            const Center(child: Text('No rewards available at the moment.'))
          else
            ...state.availableRewards.map((reward) => _RewardItem(reward: reward, state: state)),
        ],
      ),
    );
  }
}

class _PointsCard extends StatelessWidget {
  final ResidentProfile? profile;
  final Animation<int> pointsAnimation;

  const _PointsCard({this.profile, required this.pointsAnimation});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(GLSpacing.xl),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.green.shade700, Colors.green.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const Text(
              'Your GreenLeaf Balance',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: GLSpacing.xs),
            AnimatedBuilder(
              animation: pointsAnimation,
              builder: (context, child) {
                return Text(
                  '${pointsAnimation.value}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            const Text(
              'Points',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final int streakWeeks;

  const _StreakCard({required this.streakWeeks});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(GLSpacing.md),
        child: Row(
          children: [
            const Icon(Icons.bolt, color: Colors.orange, size: 32),
            const SizedBox(width: GLSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    streakWeeks >= 4 
                      ? '$streakWeeks weeks of perfect segregation!' 
                      : (streakWeeks > 0 ? '$streakWeeks week streak!' : 'Start your streak today!'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    streakWeeks >= 4 
                      ? 'You are earning 25% bonus points on all pickups!' 
                      : (streakWeeks > 0 ? 'Maintain your streak for bonus points!' : 'Segregate waste weekly to earn more.'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardItem extends StatelessWidget {
  final Reward reward;
  final RewardsState state;

  const _RewardItem({required this.reward, required this.state});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: GLSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(GLSpacing.md),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: reward.imageUrl != null
                  ? Image.network(reward.imageUrl!, fit: BoxFit.cover)
                  : const Icon(Icons.redeem, size: 32, color: Colors.green),
            ),
            const SizedBox(width: GLSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reward.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(reward.description, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: GLSpacing.xs),
                  Text('${reward.pointCost} Points', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(width: GLSpacing.md),
            GLButton(
              text: 'Redeem',
              size: GLButtonSize.small,
              onPressed: (state.profile?.pointsBalance ?? 0) >= reward.pointCost
                  ? () => _confirmRedeem(context, reward)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRedeem(BuildContext context, Reward reward) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Redemption'),
        content: Text('Redeem "${reward.name}" for ${reward.pointCost} points?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              state.redeemReward(reward);
            },
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final List<RewardHistoryEntry> history;

  const _HistoryTab({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Center(child: Text('No earning history yet.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(GLSpacing.md),
      itemCount: history.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final entry = history[index];
        final isEarning = entry.pointsEarned > 0;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isEarning ? Colors.green.shade100 : Colors.red.shade100,
            child: Icon(
              isEarning ? Icons.add_circle_outline : Icons.remove_circle_outline,
              color: isEarning ? Colors.green : Colors.red,
            ),
          ),
          title: Text(entry.description),
          subtitle: Text(DateFormat('MMM dd, yyyy • HH:mm').format(entry.date)),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isEarning ? "+" : ""}${entry.pointsEarned}',
                style: TextStyle(
                  color: isEarning ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text('Bal: ${entry.totalBalanceAtTime}', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        );
      },
    );
  }
}
