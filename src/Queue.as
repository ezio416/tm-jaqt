// c 2025-07-02
// m 2025-07-03

void CancelQueueAsync() {
    Http::Nadeo::CancelQueueAsync();
}

void StartQueueAsync() {
    const string funcName = "StartQueueAsync";

    if (State::status != State::Status::NotQueued) {
        Log::Warning(funcName, "can't start queue, status: " + tostring(State::status));
        return;
    }

    State::SetStatus(State::Status::Queueing);
    State::queueStart = Time::Now;

    while (false
        or State::status == State::Status::Queueing
        or State::status == State::Status::Queued
    ) {
        if (State::cancel) {
            State::cancel = false;
            State::SetStatus(State::Status::NotQueued);
            break;
        }

        Json::Value@ heartbeat = Http::Nadeo::SendHeartbeatAsync();
        if (heartbeat !is null) {
            if (true
                and heartbeat.HasKey("status")
                and heartbeat["status"].GetType() == Json::Type::String
            ) {
                State::SetStatus(string(heartbeat["status"]));
            }

            if (true
                and heartbeat.HasKey("matchLiveId")
                and heartbeat["matchLiveId"].GetType() == Json::Type::String
            ) {
                const string liveId = string(heartbeat["matchLiveId"]);
                Log::Info(funcName, "got match live ID: " + liveId);

                PlaySound();

                while (true) {
                    @State::match = Match(Http::Nadeo::GetMatchInfoAsync(liveId));

                    if (State::match.JoinAsync()) {
                        break;
                    }

                    Log::Info(funcName, "waiting for server...");

                    sleep(5000);
                }

                while (!State::match.In()) {
                    yield();
                }

                State::SetStatus(State::Status::InMatch);

                auto App = cast<CTrackMania>(GetApp());
                uint playerCount = 0;

                while (true) {
                    if (cast<CSmArenaClient>(App.CurrentPlayground) !is null) {
                        if (playerCount != App.CurrentPlayground.Players.Length) {
                            Log::Debug(funcName, "player count changed: " + playerCount);

                            playerCount = App.CurrentPlayground.Players.Length;
                            State::players.DeleteAll();
                            State::playersArr = {};

                            string[] accountIds;

                            for (uint i = 0; i < App.CurrentPlayground.Players.Length; i++) {
                                auto player = Player(cast<CSmPlayer>(App.CurrentPlayground.Players[i]));
                                if (player.accountId.Length > 0) {
                                    State::playersArr.InsertLast(player);
                                    State::players.Set(player.accountId, @player);

                                    accountIds.InsertLast(player.accountId);
                                }
                            }

                            Json::Value@ leaderboard = Http::Nadeo::GetLeaderboardPlayersAsync(accountIds);
                            if (leaderboard !is null) {
                                if (leaderboard.HasKey("results")) {
                                    Json::Value@ results = leaderboard["results"];
                                    if (true
                                        and results.GetType() == Json::Type::Array
                                        and results.Length == accountIds.Length
                                    ) {
                                        for (uint i = 0; i < results.Length; i++) {
                                            try {
                                                auto player = cast<Player>(State::players[string(results[i]["player"])]);
                                                player.rank        = uint(results[i]["rank"]);
                                                player.progression = uint(results[i]["score"]);
                                            } catch {
                                                Log::Error(funcName, getExceptionInfo());
                                            }
                                        }
                                    }
                                } else {
                                    Log::Error(funcName, "leaderboard error");
                                }
                            }
                        }
                    } else {
                        State::players.DeleteAll();
                        State::playersArr = {};
                        playerCount = 0;
                    }

                    @State::match = Match(Http::Nadeo::GetMatchInfoAsync(liveId));

                    if (State::match.status == MatchStatus::COMPLETED) {
                        Log::Info(funcName, "match completed");
                        State::SetStatus(State::Status::NotQueued);
                        startnew(GetMyStatusAsync);
                        break;
                    }

                    sleep(5000);
                }

                State::players.DeleteAll();
                State::playersArr = {};

                break;
            }
        }

        while (Time::Now - Http::Nadeo::lastHeartbeat < 5000) {
            yield();

            if (State::cancel) {
                State::cancel = false;
                break;
            }
        }
    }

    Log::Info(funcName, "end");
}
