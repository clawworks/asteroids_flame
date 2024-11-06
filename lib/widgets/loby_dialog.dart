import 'package:asteroids_flame/main.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class LobbyDialog extends StatefulWidget {
  const LobbyDialog({
    required this.onGameStarted,
    super.key,
  });

  final void Function(String gameId) onGameStarted;

  @override
  State<LobbyDialog> createState() => _LobbyDialogState();
}

class _LobbyDialogState extends State<LobbyDialog> {
  List<String> _userIds = [];
  bool _loading = false;

  /// Unique identifier for each players to identify each other in lobby
  final myUserId = const Uuid().v4();

  late final RealtimeChannel _lobbyChannel;

  @override
  void initState() {
    super.initState();

    _lobbyChannel = supabase.channel(
      'lobby',
      opts: const RealtimeChannelConfig(self: true),
    );
    _lobbyChannel
        .onPresenceSync((payload, [ref]) {
          // Update the lobby count
          final presenceStates = _lobbyChannel.presenceState();

          setState(() {
            _userIds = presenceStates
                .map((presenceState) => (presenceState.presences.first)
                    .payload['user_id'] as String)
                .toList();
          });
        })
        .onBroadcast(
            event: 'game_start',
            callback: (payload, [_]) {
              // Start the game if someone has started a game with you
              final participantIds = List<String>.from(payload['participants']);
              if (participantIds.contains(myUserId)) {
                final gameId = payload['game_id'] as String;
                widget.onGameStarted(gameId);
                Navigator.of(context).pop();
              }
            })
        .subscribe(
          (status, _) async {
            if (status == RealtimeSubscribeStatus.subscribed) {
              await _lobbyChannel.track({'user_id': myUserId});
            }
          },
        );
  }

  @override
  void dispose() {
    supabase.removeChannel(_lobbyChannel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Lobby'),
      content: _loading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : Text('${_userIds.length} users waiting'),
      actions: [
        TextButton(
          onPressed: _userIds.length < 2
              ? null
              : () async {
                  setState(() {
                    _loading = true;
                  });

                  final opponentId =
                      _userIds.firstWhere((userId) => userId != myUserId);
                  final gameId = const Uuid().v4();
                  await _lobbyChannel.sendBroadcastMessage(
                    event: 'game_start',
                    payload: {
                      'participants': [
                        opponentId,
                        myUserId,
                      ],
                      'game_id': gameId,
                    },
                  );
                },
          child: const Text('start'),
        ),
      ],
    );
  }
}
