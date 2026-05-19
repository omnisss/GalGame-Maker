//顶部UI层，负责显示时间、状态等信息
import 'package:flutter/material.dart';
import '../scene_state.dart';
import '../../home/game_theme.dart';

class TopUiLayer extends StatelessWidget {
  const TopUiLayer({super.key, required this.state});
  final TopUiState state;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Align(
            alignment: Alignment.topLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _CalendarClockCard(
                  dateText: state.dateText,
                  timeText: state.timeText,
                ),
                const SizedBox(height: 8),
                _StatusCard(text: state.statusText),
                if (state.locationText.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _TinyTag(
                    icon: Icons.place_rounded,
                    text: state.locationText,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarClockCard extends StatelessWidget {
  const _CalendarClockCard({
    required this.dateText,
    required this.timeText,
  });

  final String dateText;
  final String timeText;

  String _yearMonth(String s) {
    final parts = s.split('/');
    if (parts.length >= 2) {
      return '${parts[0]}.${parts[1]}';
    }
    return s;
  }

  String _day(String s) {
    final parts = s.split('/');
    if (parts.length >= 3) {
      return parts[2];
    }
    return '--';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 138,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: GameTheme.accentPink.withValues(alpha: 0.42),
        ),
        boxShadow: [
          BoxShadow(
            color: GameTheme.accentPink.withValues(alpha: 0.18),
            blurRadius: 18,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: GameTheme.accentPink.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _yearMonth(dateText),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _day(dateText),
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              height: 1.0,
              shadows: [
                Shadow(
                  blurRadius: 12,
                  color: Colors.black.withValues(alpha: 0.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.90),
                ),
                const SizedBox(width: 6),
                Text(
                  timeText,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.94),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.wifi_tethering_rounded,
            size: 15,
            color: Colors.white.withValues(alpha: 0.88),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyTag extends StatelessWidget {
  const _TinyTag({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: Colors.white.withValues(alpha: 0.85),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.86),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}