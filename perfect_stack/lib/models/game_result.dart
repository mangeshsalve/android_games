class GameResult {
  const GameResult({
    required this.score,
    required this.best,
    required this.isNewBest,
  });

  final int score;
  final int best;
  final bool isNewBest;
}
