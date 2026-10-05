/// Health component — attach to any entity that can take damage.
///
/// Usage:
/// ```dart
/// final health = HealthComponent(maxHp: 100);
/// entity.setComponent('health', health);
/// health.takeDamage(25);
/// ```
class HealthComponent {
  HealthComponent({
    required this.maxHp,
    int? initialHp,
    this.onDeath,
  }) : _currentHp = initialHp ?? maxHp;

  final int maxHp;
  int _currentHp;
  bool _dead = false;

  /// Called once when HP reaches zero.
  void Function()? onDeath;

  int get currentHp => _currentHp;
  bool get isDead => _dead;
  bool get isAlive => !_dead;

  /// 0.0 (empty) to 1.0 (full)
  double get fraction => maxHp > 0 ? _currentHp / maxHp : 0;

  void takeDamage(int amount) {
    if (_dead || amount <= 0) return;
    _currentHp = (_currentHp - amount).clamp(0, maxHp);
    if (_currentHp == 0 && !_dead) {
      _dead = true;
      onDeath?.call();
    }
  }

  void heal(int amount) {
    if (_dead || amount <= 0) return;
    _currentHp = (_currentHp + amount).clamp(0, maxHp);
  }

  void restore() {
    _currentHp = maxHp;
    _dead = false;
  }

  /// Set HP directly (e.g. when loading a save).
  void setHp(int hp) {
    _currentHp = hp.clamp(0, maxHp);
    _dead = _currentHp == 0;
  }

  Map<String, dynamic> toJson() => {
    'currentHp': _currentHp,
    'maxHp': maxHp,
    'dead': _dead,
  };

  factory HealthComponent.fromJson(Map<String, dynamic> json) {
    final c = HealthComponent(
      maxHp: json['maxHp'] as int? ?? 100,
    );
    c.setHp(json['currentHp'] as int? ?? c.maxHp);
    if (json['dead'] as bool? ?? false) c._dead = true;
    return c;
  }
}
