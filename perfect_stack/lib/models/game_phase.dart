enum GamePhase {
  playing,
  paused,

  /// The last block missed; debris is falling before the game-over panel.
  dying,
  gameOver,
}
