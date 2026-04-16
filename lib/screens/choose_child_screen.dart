import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/child_model.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'adventure_map_screen.dart';
import 'parent_dashboard_screen.dart';
import 'login_screen.dart';

class ChooseChildScreen extends StatefulWidget {
  const ChooseChildScreen({super.key});

  @override
  State<ChooseChildScreen> createState() => _ChooseChildScreenState();
}

class _ChooseChildScreenState extends State<ChooseChildScreen>
    with SingleTickerProviderStateMixin {
  int? _selectedIndex;
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onChildTap(int index) {
    setState(() => _selectedIndex = index);
  }

  void _onLetsPlay() {
    if (_selectedIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please choose a child first!',
            style: GoogleFonts.nunito()),
        backgroundColor: AppTheme.tealDark,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, __, ___) => AdventureMapScreen(
          child: ChildModel.demoChildren[_selectedIndex!]),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 500),
    ));
  }

  Future<void> _showSettingsMenu() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ListTile(
            leading: const Icon(Icons.logout_rounded, color: Color(0xFFD84E4E)),
            title: Text(
              'Log out',
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFD84E4E),
              ),
            ),
            onTap: () => Navigator.pop(context, 'logout'),
          ),
        );
      },
    );

    if (selected == 'logout' && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 350),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        Container(decoration: AppTheme.backgroundDecoration),
        const FloatingBubbles(),
        const Sparkles(),
        // Clouds at bottom
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: SizedBox(
              height: 120, child: CustomPaint(painter: CloudPainter())),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 8, right: 16),
              child: GestureDetector(
                onTap: _showSettingsMenu,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.82),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withOpacity(0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.settings_outlined,
                    color: AppTheme.tealMid,
                    size: 21,
                  ),
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: FadeTransition(
            opacity: _ctrl,
            child: Column(children: [
              const SizedBox(height: 36),

              // ── Title ────────────────────────────────────────────────────
              Text('Who is playing today? 🎮',
                  style: GoogleFonts.nunito(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.tealDark)),

              const SizedBox(height: 8),

              Text('Tap a card to select, then press Let\'s Play!',
                  style: GoogleFonts.nunito(
                      fontSize: 13, color: AppTheme.tealMid)),

              const SizedBox(height: 32),

              // ── Child cards row ───────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  ChildModel.demoChildren.length,
                      (i) => _ChildCard(
                    data: ChildModel.demoChildren[i],
                    isSelected: _selectedIndex == i,
                    onTap: () => _onChildTap(i),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // ── Let's Play button ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: _LetsPlayButton(
                  enabled: _selectedIndex != null,
                  onPressed: _onLetsPlay,
                ),
              ),

              const Spacer(),

              // ── Parents Area ──────────────────────────────────────────────
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 20, bottom: 16),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) =>
                          const ParentDashboardScreen(),
                          transitionsBuilder: (_, anim, __, child) =>
                              FadeTransition(opacity: anim, child: child),
                          transitionDuration:
                          const Duration(milliseconds: 500),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.teal.withOpacity(0.1),
                                blurRadius: 8)
                          ],
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.lock_outline_rounded,
                              size: 16, color: AppTheme.tealMid),
                          const SizedBox(width: 6),
                          Text('Parents Area',
                              style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  color: AppTheme.tealMid,
                                  fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ─── Child card (rectangular, selectable) ────────────────────────────────────

class _ChildCard extends StatefulWidget {
  final ChildModel data;
  final bool isSelected;
  final VoidCallback onTap;
  const _ChildCard({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ChildCard> createState() => _ChildCardState();
}

class _ChildCardState extends State<_ChildCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween<double>(begin: 1.0, end: 1.05)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.data.palette;
    final selected = widget.isSelected;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: MouseRegion(
        // ← hand cursor on hover
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          setState(() => _hovering = true);
          _ctrl.forward();
        },
        onExit: (_) {
          setState(() => _hovering = false);
          _ctrl.reverse();
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: ScaleTransition(
            scale: _scale,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: selected
                      ? [AppTheme.tealPrimary, AppTheme.tealDark]
                      : colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: selected ? Colors.white : Colors.white.withOpacity(0.6),
                  width: selected ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (selected ? AppTheme.tealPrimary : colors[0])
                        .withOpacity(selected ? 0.55 : 0.35),
                    blurRadius: selected ? 20 : 12,
                    spreadRadius: selected ? 2 : 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Avatar section ───────────────────────────────────────
                  Container(
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.28),
                          Colors.white.withOpacity(0.15),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft:  Radius.circular(18),
                        topRight: Radius.circular(18),
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFFFFF), Color(0xFFF6FFFD)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.95),
                            width: 2.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.10),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(5),
                        child: ClipOval(
                          child: AvatarFace(seed: widget.data.avatarSeed),
                        ),
                      ),
                    ),
                  ),

                  // ── Info section ─────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 10),
                    child: Column(children: [
                      Text(widget.data.name,
                          style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                      const SizedBox(height: 4),
                      // Level badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('Lv ${widget.data.level}',
                            style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                    ]),
                  ),

                  // ── Checkmark when selected ──────────────────────────────
                  if (selected)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        width: 24, height: 24,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded,
                            color: AppTheme.tealPrimary, size: 16),
                      ),
                    )
                  else
                    const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Let's Play button ────────────────────────────────────────────────────────

class _LetsPlayButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;
  const _LetsPlayButton({required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 54,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: enabled
              ? [AppTheme.tealPrimary, AppTheme.tealDark]
              : [Colors.grey.shade300, Colors.grey.shade400],
        ),
        boxShadow: enabled
            ? [
          BoxShadow(
              color: AppTheme.tealPrimary.withOpacity(0.45),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ]
            : [],
      ),
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: onPressed,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.videogame_asset_rounded,
                color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text("Let's Play!",
                style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ]),
        ),
      ),
    );
  }
}