// Enemy rendering is handled directly in game_map_widget.dart via
// CustomPainter for performance. This file serves as documentation
// of the enemy visual design:
//
// - Enemies rendered as colored circles moving along the path
// - Health bar displayed above each enemy
// - Color coding by type:
//   * Infantry: green
//   * Runner: yellow
//   * Shield Bearer: blue-grey
//   * Officer: purple
//   * Medic: white
//   * Sapper: orange
//   * Heavy: red
//   * Elite: gold
// - Damage flash: brief red tint on hit
//
// All rendering is done in _MapPainter._drawEnemies()
