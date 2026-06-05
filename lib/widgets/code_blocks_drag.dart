import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/challenge_model.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';

/// Payload for palette drops and workspace reordering.
class DraggedBlockData {
  final int? fromIndex;
  final CodeBlockType? type;

  const DraggedBlockData({this.fromIndex, this.type});
}

/// Registered insertion point used for magnetic snapping.
class CodeBlockDropTarget {
  final String id;
  final double centerY;

  const CodeBlockDropTarget({required this.id, required this.centerY});
}

/// Global drag session for a code-blocks workspace.
class CodeBlocksDragController extends ChangeNotifier {
  bool _isDragging = false;
  String? _activeSlotId;
  final Map<String, CodeBlockDropTarget> _targets = {};
  final Map<String, ValueChanged<DraggedBlockData>> _acceptHandlers = {};

  /// Expanded gap height shown at the active insertion point.
  double gapHeight;

  /// Invisible hit zone height for non-active slots while dragging.
  double idleHitHeight;

  CodeBlocksDragController({
    this.gapHeight = 44,
    this.idleHitHeight = 28,
  });

  bool get isDragging => _isDragging;
  String? get activeSlotId => _activeSlotId;

  void startDrag() {
    if (_isDragging) return;
    _isDragging = true;
    notifyListeners();
  }

  void endDrag() {
    if (!_isDragging && _activeSlotId == null) return;
    _isDragging = false;
    _activeSlotId = null;
    notifyListeners();
  }

  void registerTarget(String id, double centerY) {
    final existing = _targets[id];
    if (existing != null && (existing.centerY - centerY).abs() < 0.5) return;
    _targets[id] = CodeBlockDropTarget(id: id, centerY: centerY);
    if (_isDragging) {
      notifyListeners();
    }
  }

  void unregisterTarget(String id) {
    if (_targets.remove(id) != null) {
      if (_activeSlotId == id) _activeSlotId = null;
      notifyListeners();
    }
  }

  void registerAcceptHandler(
    String id,
    ValueChanged<DraggedBlockData> handler,
  ) {
    _acceptHandlers[id] = handler;
  }

  void unregisterAcceptHandler(String id) {
    _acceptHandlers.remove(id);
  }

  void setActiveSlot(String? id) {
    if (_activeSlotId == id) return;
    _activeSlotId = id;
    notifyListeners();
  }

  /// Snaps to the nearest insertion slot while dragging.
  void updatePointer(Offset globalPosition) {
    if (!_isDragging || _targets.isEmpty) return;

    String? closestId;
    double closestDistance = double.infinity;

    for (final target in _targets.values) {
      final distance = (globalPosition.dy - target.centerY).abs();
      if (distance < closestDistance) {
        closestDistance = distance;
        closestId = target.id;
      }
    }

    setActiveSlot(closestId);
  }

  /// Inserts at the active slot when the drag ends without a direct hit.
  void tryDrop(DraggedBlockData data) {
    final id = _activeSlotId;
    if (id == null) return;
    _acceptHandlers[id]?.call(data);
  }

  @override
  void dispose() {
    _targets.clear();
    _acceptHandlers.clear();
    super.dispose();
  }
}

class CodeBlocksDragScope extends InheritedNotifier<CodeBlocksDragController> {
  final bool enabled;

  const CodeBlocksDragScope({
    super.key,
    required super.notifier,
    required this.enabled,
    required super.child,
  });

  static CodeBlocksDragController? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CodeBlocksDragScope>();
    return scope?.notifier;
  }

  static CodeBlocksDragController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(controller != null, 'CodeBlocksDragScope not found in widget tree');
    return controller!;
  }
}

/// Owns a [CodeBlocksDragController] for a workspace subtree.
class CodeBlocksDragHost extends StatefulWidget {
  final bool enabled;
  final Widget child;

  const CodeBlocksDragHost({
    super.key,
    required this.enabled,
    required this.child,
  });

  @override
  State<CodeBlocksDragHost> createState() => _CodeBlocksDragHostState();
}

class _CodeBlocksDragHostState extends State<CodeBlocksDragHost> {
  late final CodeBlocksDragController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CodeBlocksDragController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CodeBlocksDragScope(
      notifier: _controller,
      enabled: widget.enabled,
      child: widget.child,
    );
  }
}

/// Wraps a palette chip [Draggable] and reports pointer movement for snapping.
class CodeBlocksPaletteDraggable extends StatelessWidget {
  final DraggedBlockData data;
  final int maxSimultaneousDrags;
  final Widget feedback;
  final Widget childWhenDragging;
  final Widget child;

  const CodeBlocksPaletteDraggable({
    super.key,
    required this.data,
    required this.maxSimultaneousDrags,
    required this.feedback,
    required this.childWhenDragging,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scope = CodeBlocksDragScope.maybeOf(context);

    return Draggable<DraggedBlockData>(
      data: data,
      maxSimultaneousDrags: maxSimultaneousDrags,
      onDragStarted: scope?.startDrag,
      onDragEnd: (details) {
        if (scope != null && !details.wasAccepted) {
          scope.tryDrop(data);
        }
        scope?.endDrag();
      },
      onDraggableCanceled: (_, __) => scope?.endDrag(),
      onDragUpdate: (details) => scope?.updatePointer(details.globalPosition),
      feedback: feedback,
      childWhenDragging: childWhenDragging,
      child: child,
    );
  }
}

/// Drag callbacks to wire into [HandleOnlyDraggable].
class CodeBlocksDragCallbacks {
  final VoidCallback? onDragStarted;
  final void Function(DraggableDetails details)? onDragEnd;
  final void Function(DragUpdateDetails details)? onDragUpdate;
  final void Function(Velocity, Offset)? onDraggableCanceled;

  const CodeBlocksDragCallbacks({
    this.onDragStarted,
    this.onDragEnd,
    this.onDragUpdate,
    this.onDraggableCanceled,
  });

  factory CodeBlocksDragCallbacks.forData(
    BuildContext context,
    DraggedBlockData data,
  ) {
    final scope = CodeBlocksDragScope.maybeOf(context);
    if (scope == null) return const CodeBlocksDragCallbacks();
    return CodeBlocksDragCallbacks(
      onDragStarted: scope.startDrag,
      onDragEnd: (details) {
        if (!details.wasAccepted) {
          scope.tryDrop(data);
        }
        scope.endDrag();
      },
      onDraggableCanceled: (_, __) => scope.endDrag(),
      onDragUpdate: (details) => scope.updatePointer(details.globalPosition),
    );
  }
}

/// Animated insertion slot between workspace blocks.
///
/// Hidden when idle; expands a magnetic hit zone while dragging; opens a full
/// gap at the snapped insertion index.
class CodeBlockDropSlot extends StatefulWidget {
  final String slotId;
  final bool isExecuting;
  final ValueChanged<DraggedBlockData> onAccept;

  const CodeBlockDropSlot({
    super.key,
    required this.slotId,
    required this.isExecuting,
    required this.onAccept,
  });

  @override
  State<CodeBlockDropSlot> createState() => _CodeBlockDropSlotState();
}

class _CodeBlockDropSlotState extends State<CodeBlockDropSlot> {
  final GlobalKey _key = GlobalKey();
  bool _isHovering = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    CodeBlocksDragScope.maybeOf(context)
        ?.registerAcceptHandler(widget.slotId, widget.onAccept);
  }

  @override
  void deactivate() {
    final scope = CodeBlocksDragScope.maybeOf(context);
    scope?.unregisterTarget(widget.slotId);
    scope?.unregisterAcceptHandler(widget.slotId);
    super.deactivate();
  }

  void _reportBounds() {
    final scope = CodeBlocksDragScope.maybeOf(context);
    if (scope == null) return;

    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final topLeft = box.localToGlobal(Offset.zero);
    final centerY = topLeft.dy + box.size.height / 2;
    scope.registerTarget(widget.slotId, centerY);
  }

  @override
  Widget build(BuildContext context) {
    final scope = CodeBlocksDragScope.maybeOf(context);
    final isDragging = scope?.isDragging ?? false;
    final isActive = isDragging &&
        (scope?.activeSlotId == widget.slotId || _isHovering);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reportBounds();
    });

    final gapHeight = scope?.gapHeight ?? 44;
    final idleHitHeight = scope?.idleHitHeight ?? 28;

    return DragTarget<DraggedBlockData>(
      onWillAcceptWithDetails: (_) {
        if (widget.isExecuting || !mounted) return false;
        setState(() => _isHovering = true);
        scope?.setActiveSlot(widget.slotId);
        return true;
      },
      onMove: (details) {
        final box = _key.currentContext?.findRenderObject() as RenderBox?;
        if (box != null) {
          scope?.updatePointer(box.localToGlobal(details.offset));
        }
      },
      onLeave: (_) {
        if (mounted) setState(() => _isHovering = false);
      },
      onAcceptWithDetails: (details) {
        if (mounted) setState(() => _isHovering = false);
        scope?.endDrag();
        widget.onAccept(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final height = !isDragging
            ? 0.0
            : isActive
                ? gapHeight
                : idleHitHeight;

        return AnimatedContainer(
          key: _key,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.symmetric(
            horizontal: 8,
            vertical: isDragging ? 2 : 0,
          ),
          height: height,
          decoration: isActive
              ? BoxDecoration(
                  color: AppTheme.tealPrimary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.tealPrimary,
                    width: 1.5,
                  ),
                )
              : null,
          child: isActive
              ? Center(
                  child: Icon(
                    Icons.add_rounded,
                    size: 16,
                    color: AppTheme.tealPrimary.withValues(alpha: 0.85),
                  ),
                )
              : null,
        );
      },
    );
  }
}

/// Drop target for empty nested block bodies (repeat / if / var containers).
class CodeBlockBodyDropHint extends StatefulWidget {
  final String slotId;
  final bool isExecuting;
  final Color color;
  final ValueChanged<DraggedBlockData> onInsert;

  const CodeBlockBodyDropHint({
    super.key,
    required this.slotId,
    required this.isExecuting,
    required this.color,
    required this.onInsert,
  });

  @override
  State<CodeBlockBodyDropHint> createState() => _CodeBlockBodyDropHintState();
}

class _CodeBlockBodyDropHintState extends State<CodeBlockBodyDropHint> {
  final GlobalKey _key = GlobalKey();
  bool _isHovering = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    CodeBlocksDragScope.maybeOf(context)
        ?.registerAcceptHandler(widget.slotId, widget.onInsert);
  }

  @override
  void deactivate() {
    final scope = CodeBlocksDragScope.maybeOf(context);
    scope?.unregisterTarget(widget.slotId);
    scope?.unregisterAcceptHandler(widget.slotId);
    super.deactivate();
  }

  void _reportBounds() {
    final scope = CodeBlocksDragScope.maybeOf(context);
    if (scope == null) return;

    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final topLeft = box.localToGlobal(Offset.zero);
    final centerY = topLeft.dy + box.size.height / 2;
    scope.registerTarget(widget.slotId, centerY);
  }

  @override
  Widget build(BuildContext context) {
    final scope = CodeBlocksDragScope.maybeOf(context);
    final isDragging = scope?.isDragging ?? false;
    final isActive = isDragging &&
        (scope?.activeSlotId == widget.slotId || _isHovering);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reportBounds();
    });

    final gapHeight = scope?.gapHeight ?? 44;

    if (!isDragging) {
      return const SizedBox.shrink();
    }

    return DragTarget<DraggedBlockData>(
      onWillAcceptWithDetails: (_) {
        if (widget.isExecuting || !mounted) return false;
        setState(() => _isHovering = true);
        scope?.setActiveSlot(widget.slotId);
        return true;
      },
      onMove: (details) {
        final box = _key.currentContext?.findRenderObject() as RenderBox?;
        if (box != null) {
          scope?.updatePointer(box.localToGlobal(details.offset));
        }
      },
      onLeave: (_) {
        if (mounted) setState(() => _isHovering = false);
      },
      onAcceptWithDetails: (details) {
        if (mounted) setState(() => _isHovering = false);
        scope?.endDrag();
        widget.onInsert(details.data);
      },
      builder: (context, _, __) {
        return AnimatedContainer(
          key: _key,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          height: isActive ? gapHeight : 32,
          decoration: BoxDecoration(
            color: isActive
                ? widget.color.withValues(alpha: 0.18)
                : widget.color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.color.withValues(alpha: isActive ? 0.85 : 0.35),
              width: isActive ? 2 : 1.5,
            ),
          ),
          child: isActive
              ? Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        size: 14,
                        color: widget.color.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppStrings.of(context).dropBlockHere,
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: widget.color.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        );
      },
    );
  }
}

/// Helper to build stable slot ids for flat and nested lists.
String codeBlockDropSlotId({required int index, int nesting = 0}) {
  return 'n$nesting-i$index';
}
