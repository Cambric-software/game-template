import 'package:flutter/widgets.dart';

import 'bootstrap/bootstrap_service.dart';
import 'ui/cambric_app.dart';

/// Entry point for the Cambric Game.
///
/// 1. Ensures Flutter is initialized
/// 2. Runs the bootstrap sequence (services, config, scenes)
/// 3. Launches the Flutter app with the game widget
///
/// Do not put logic here — all initialization belongs in
/// BootstrapService so it can be tested and reasoned about
/// independently of the Flutter entry point.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final game = await BootstrapService.initialize();

  runApp(CambricApp(game: game));
}
