import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../models/team.dart';
import '../../services/api_service.dart';

class JoinTeamScreen extends StatefulWidget {
  const JoinTeamScreen({Key? key}) : super(key: key);

  @override
  State<JoinTeamScreen> createState() => _JoinTeamScreenState();
}

class _JoinTeamScreenState extends State<JoinTeamScreen> {
  bool _isLoading = true;
  List<Team> _availableTeams = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = GetIt.I<ApiService>();
      final teamsData = await apiService.get('teams');

      setState(() {
        _availableTeams = List<Team>.from(
          teamsData.map((teamData) => Team.fromJson(teamData))
        );
        _isLoading = false;
      });
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _errorMessage = l10n.errorLoadingTeams(e.toString());
        _isLoading = false;
      });
    }
  }

  Future<void> _joinTeam(Team team) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = GetIt.I<ApiService>();
      await apiService.post('teams/${team.id}/join', {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.joinedTeamSuccess(team.name)),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.error +e.toString()),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.joinTeamTitle),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTeams,
                        child: Text(l10n.retryButton),
                      ),
                    ],
                  ),
                )
              : _availableTeams.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.people, size: 80, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noTeamsAvailableTitle,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.noTeamsAvailableMessage,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _loadTeams,
                            child: Text(l10n.refreshButton),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _availableTeams.length,
                      itemBuilder: (context, index) {
                        final team = _availableTeams[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: team.color != null
                                  ? _hexToColor(team.color!)
                                  : Colors.grey,
                              child: Text(
                                team.name.substring(0, 1).toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(team.name),
                            subtitle: team.description != null && team.description!.isNotEmpty
                                ? Text(team.description!)
                                : null,
                            trailing: ElevatedButton(
                              onPressed: () => _joinTeam(team),
                              child: Text(l10n.joinButton),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
