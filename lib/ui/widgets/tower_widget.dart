// Tower rendering is handled directly in game_map_widget.dart via
// CustomPainter for performance. This file serves as documentation
// of the tower visual design:
//
// - Rifleman (damage): Blue circle with range indicator
// - Mortar (area): Red triangle
// - Barbed Wire (slow): Grey X pattern
// - Level/tier indicated by star count below tower
//
// All rendering is done in _MapPainter._drawTowers()
