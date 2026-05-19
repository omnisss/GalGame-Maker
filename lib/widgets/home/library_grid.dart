import 'package:flutter/material.dart';
import 'game_theme.dart';
import 'home_root.dart';

class LibraryGrid extends StatelessWidget {
  final List<SaveEntry> items;
  final ValueChanged<SaveEntry> onTap;
  final bool showAdd;
  final VoidCallback? onTapAdd;

  const LibraryGrid({
    super.key,
    required this.items,
    required this.onTap,
    required this.showAdd,
    this.onTapAdd,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final crossAxisCount = w >= 1200 ? 4 : (w >= 900 ? 3 : 2);
    final total = (showAdd ? 1 : 0) + items.length;

    return GridView.builder(
      padding: const EdgeInsets.only(top: 4),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: total,
      itemBuilder: (context, index) {
        if (showAdd) {
          if (index == 0) return _AddTile(onTap: onTapAdd ?? () {});
          final item = items[index - 1];
          return _SaveTile(entry: item, onTap: () => onTap(item));
        } else {
          final item = items[index];
          return _SaveTile(entry: item, onTap: () => onTap(item));
        }
      },
    );
  }
}

class _AddTile extends StatelessWidget {
  final VoidCallback onTap;

  const _AddTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: GameTheme.blur(
        sigma: 12,
        radius: 18,
        child: Container(
          decoration: GameTheme.card(radius: 18, opacity: 0.62),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: [GameTheme.accentBlue.withOpacity(0.70), GameTheme.accentPink.withOpacity(0.70)],
                    ),
                  ),
                  child: Icon(Icons.add_rounded, color: Colors.black.withOpacity(0.7)),
                ),
                const SizedBox(height: 10),
                Text("添加", style: TextStyle(fontWeight: FontWeight.w900, color: GameTheme.fg(0.86))),
                const SizedBox(height: 4),
                Text("点击创建", style: GameTheme.tiny(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveTile extends StatefulWidget {
  final SaveEntry entry;
  final VoidCallback onTap;

  const _SaveTile({required this.entry, required this.onTap});

  @override
  State<_SaveTile> createState() => _SaveTileState();
}

class _SaveTileState extends State<_SaveTile> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: _down ? 0.98 : (_hover ? 1.02 : 1.0),
          child: GameTheme.blur(
            sigma: 12,
            radius: 18,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.64),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(_hover ? 0.65 : 0.45)),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 18,
                    offset: const Offset(0, 12),
                    color: Colors.black.withOpacity(0.08),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _IdPill(id: widget.entry.id),
                  const Spacer(),
                  Text(widget.entry.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: GameTheme.fg(0.90))),
                  const SizedBox(height: 6),
                  Text(widget.entry.subtitle, style: GameTheme.tiny(context)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IdPill extends StatelessWidget {
  final String id;

  const _IdPill({required this.id});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.70),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.55)),
      ),
      child: Text(
        id,
        style: TextStyle(fontSize: 11.5, color: GameTheme.fg(0.70), fontWeight: FontWeight.w800),
      ),
    );
  }
}
