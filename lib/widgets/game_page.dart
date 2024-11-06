import 'package:asteroids_flame/game/game.dart';
import 'package:asteroids_flame/main.dart';
import 'package:asteroids_flame/widgets/loby_dialog.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late final MyGame _game;

  /// Holds the RealtimeChannel to sync game states
  RealtimeChannel? _gameChannel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/background.jpg', fit: BoxFit.cover),
          GameWidget(game: _game),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _game = MyGame(
      onGameStateUpdate: (position, health) async {
        ChannelResponse response;
        do {
          response = await _gameChannel!.sendBroadcastMessage(
            event: 'game_state',
            payload: {
              'x': position.x,
              'y': position.y,
              'health': health,
            },
          );

          // wait for a frame to avoid infinite rate limiting loops...
          await Future.delayed(Duration.zero);
          setState(() {});
        } while (response == ChannelResponse.rateLimited && health <= 0);
      },
      onGameOver: (playerWon) async {
        await showDialog(
          barrierDismissible: false,
          context: context,
          builder: ((context) {
            return AlertDialog(
              title: Text(playerWon ? 'You Won! Great Job!' : 'You Lost...'),
              actions: [
                TextButton(
                  onPressed: () async {
                    // Remove dialog
                    Navigator.of(context).pop();
                    await supabase.removeChannel(_gameChannel!);
                    _openLobbyDialog();
                  },
                  child: const Text('Play Again!'),
                ),
              ],
            );
          }),
        );
      },
    );

    // await for a frame so that the widget mounts
    await Future.delayed(Duration.zero);

    if (mounted) {
      _openLobbyDialog();
    }
  }

  void _openLobbyDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return LobbyDialog(
            onGameStarted: (gameId) async {
              // await a frame to allow subscribing to a new channel in a realtime callback
              await Future.delayed(Duration.zero);

              setState(() {});

              _game.startNewGame();

              _gameChannel = supabase.channel(gameId,
                  opts: const RealtimeChannelConfig(ack: true));

              _gameChannel!
                  .onBroadcast(
                    event: 'game_state',
                    callback: (payload, [_]) {
                      final position = Vector2(
                        payload['x'] as double,
                        payload['y'] as double,
                      );
                      final opponentHealth = payload['health'] as int;
                      _game.updateOpponent(
                        position: position,
                        health: opponentHealth,
                      );

                      if (opponentHealth <= 0) {
                        if (!_game.isGameOver) {
                          _game.isGameOver = true;
                          _game.onGameOver(true);
                        }
                      }
                    },
                  )
                  .subscribe();
            },
          );
        });
  }
}
