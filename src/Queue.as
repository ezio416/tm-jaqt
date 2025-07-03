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

                while (true) {
                    @State::match = Match(Http::Nadeo::GetMatchInfoAsync(liveId));

                    if (State::match.status == MatchStatus::COMPLETED) {
                        Log::Info(funcName, "match completed");
                        State::SetStatus(State::Status::NotQueued);
                        break;
                    }

                    sleep(5000);
                }

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
