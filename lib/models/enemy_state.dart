enum EnemyMovementState {
  advancing,   // moving across no man's land toward trench
  breaching,   // at trench wall, draining breach HP
  inTrench,    // inside trench, only melee defenders can engage
  crossed,     // past trench, heading for command post
}
