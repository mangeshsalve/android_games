/// Immutable horizontal slice of a block on the stack, in world units.
class StackBlock {
  const StackBlock({required this.left, required this.width});

  final double left;
  final double width;

  double get right => left + width;
  double get center => left + width / 2;

  StackBlock copyWith({double? left, double? width}) =>
      StackBlock(left: left ?? this.left, width: width ?? this.width);

  @override
  bool operator ==(Object other) =>
      other is StackBlock && other.left == left && other.width == width;

  @override
  int get hashCode => Object.hash(left, width);

  @override
  String toString() => 'StackBlock(left: $left, width: $width)';
}
