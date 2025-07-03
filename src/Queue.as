// c 2025-07-02
// m 2025-07-03

enum QueueStatus {
    None,
    Queueing,
    Queued,
    MatchFound,
    Joining,
    InMatch
}

void QueueAsync() {
    if (status != QueueStatus::None) {
        return;
    }

    status = QueueStatus::Queueing;

    while (false
        or status == QueueStatus::Queueing
        or status == QueueStatus::Queued
    ) {
        if (cancel) {
            cancel = false;
            status = QueueStatus::None;
            break;
        }

        Json::Value@ heartbeat = API::Nadeo::SendHeartbeatAsync();
        print("heartbeat: " + Json::Write(heartbeat, true));
        if (heartbeat !is null) {
            if (true
                and heartbeat.HasKey("status")
                and heartbeat["status"].GetType() == Json::Type::String
            ) {
                SetStatus(string(heartbeat["status"]));
            }

            if (true
                and heartbeat.HasKey("matchLiveId")
                and heartbeat["matchLiveId"].GetType() == Json::Type::String
            ) {
                matchID = string(heartbeat["matchLiveId"]);

                while (true) {
                    Json::Value@ matchInfo = API::Nadeo::GetMatchInfoAsync();
                    print("match info: " + Json::Write(matchInfo, true));

                    @match = Match(matchInfo);
                    if (match.JoinAsync()) {
                        break;
                    }

                    sleep(5000);
                }

                auto App = cast<CTrackMania>(GetApp());
                auto Network = cast<CTrackManiaNetwork>(App.Network);
                auto ServerInfo = cast<CTrackManiaNetworkServerInfo>(Network.ServerInfo);

                while (ServerInfo.ServerLogin.Length == 0) {
                    yield();
                }

                if (ServerInfo.ServerLogin == match.joinLink.Replace("#qjoin=", "").Replace("@Trackmania", "")) {
                    status = QueueStatus::InMatch;
                    break;
                }
            }
        }

        while (Time::Now - API::Nadeo::lastHeartbeat < 5000) {
            yield();

            if (cancel) {
                cancel = false;
                break;
            }
        }
    }

    print("QueueAsync | end");
}

void QueueCancelAsync() {
    API::Nadeo::SendQueueCancelAsync();
}

void SetStatus(const string&in s) {
    if (s == "queued") {
        status = QueueStatus::Queued;
    } else if (s == "match_ready") {
        status = QueueStatus::MatchFound;
    } else if (s == "canceled") {
        status = QueueStatus::None;
    } else {
        warn("SetStatus | unknown status: " + s);
    }
}
