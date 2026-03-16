import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/scoring.dart';
import '../../providers/game_providers.dart';
import 'game_screen.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedEra = ref.watch(selectedEraProvider);
    final selectedDifficulty = ref.watch(selectedDifficultyProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A2410),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Title
              const Text(
                'TRENCH\nDEFENSE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFD4C5A9),
                  letterSpacing: 4,
                  height: 1.1,
                  shadows: [
                    Shadow(
                      offset: Offset(2, 2),
                      blurRadius: 8,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'TOWER DEFENSE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8B7355),
                  letterSpacing: 8,
                ),
              ),
              const SizedBox(height: 48),

              // Era selector
              _SectionTitle('SELECT ERA'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _EraCard(
                    title: 'World War I',
                    subtitle: 'Rifles, Mortars, Trenches',
                    isSelected: selectedEra == 'wwi',
                    enabled: true,
                    onTap: () => ref.read(selectedEraProvider.notifier).state = 'wwi',
                  ),
                  const SizedBox(width: 16),
                  _EraCard(
                    title: 'Medieval',
                    subtitle: 'Coming Soon',
                    isSelected: selectedEra == 'medieval',
                    enabled: false,
                    onTap: null,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Difficulty selector
              _SectionTitle('DIFFICULTY'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _DifficultyChip(
                    label: 'Normal',
                    isSelected: selectedDifficulty == Difficulty.normal,
                    color: const Color(0xFF4A7C3F),
                    onTap: () => ref.read(selectedDifficultyProvider.notifier).state =
                        Difficulty.normal,
                  ),
                  const SizedBox(width: 12),
                  _DifficultyChip(
                    label: 'Hard',
                    isSelected: selectedDifficulty == Difficulty.hard,
                    color: const Color(0xFFC77B28),
                    onTap: () => ref.read(selectedDifficultyProvider.notifier).state =
                        Difficulty.hard,
                  ),
                  const SizedBox(width: 12),
                  _DifficultyChip(
                    label: 'Nightmare',
                    isSelected: selectedDifficulty == Difficulty.nightmare,
                    color: const Color(0xFF8B2020),
                    onTap: () => ref.read(selectedDifficultyProvider.notifier).state =
                        Difficulty.nightmare,
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // Deploy button
              SizedBox(
                width: 220,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A7C3F),
                    foregroundColor: const Color(0xFFD4C5A9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(
                        color: Color(0xFF6B9B5E),
                        width: 2,
                      ),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const GameScreen(),
                      ),
                    );
                  },
                  child: const Text('DEPLOY!'),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF8B7355),
        letterSpacing: 4,
      ),
    );
  }
}

class _EraCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final bool enabled;
  final VoidCallback? onTap;

  const _EraCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 180,
        height: 100,
        decoration: BoxDecoration(
          color: enabled
              ? (isSelected
                  ? const Color(0xFF3A4D28)
                  : const Color(0xFF2A3520))
              : const Color(0xFF1E2618),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6B9B5E)
                : enabled
                    ? const Color(0xFF4A5D23)
                    : const Color(0xFF333D25),
            width: isSelected ? 2.5 : 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: enabled
                    ? const Color(0xFFD4C5A9)
                    : const Color(0xFF555E48),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: enabled
                    ? const Color(0xFF8B7355)
                    : const Color(0xFF444D38),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _DifficultyChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.8) : const Color(0xFF2A3520),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : const Color(0xFF4A5D23),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : const Color(0xFF8B7355),
          ),
        ),
      ),
    );
  }
}
