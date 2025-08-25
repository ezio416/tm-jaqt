// c 2025-07-03
// m 2025-08-24

namespace State {
    uint         activePlayers = 0;
    bool         cancel        = false;
    bool         frozen        = false;
    string       mapName;
    UI::Texture@ mapThumbnail;
    string       mapThumbnailUrl;
    Match@       match;
    Player       me;
    dictionary   players;
    Player@[]    playersArr;
    uint64       queueStart    = 0;
    Status       status        = Status::NotQueued;

    enum Status {
        NotQueued,
        Queueing,
        WaitingForPartner,
        Queued,
        MatchFound,
        Joining,
        InMatch,
        MatchEnd,
        Banned,
        _Count
    }

    void SetStatus(const Status s) {
        status = s;
    }

    void SetStatus(const string&in s) {
        if (s == "queued") {
            SetStatus(Status::Queued);
        } else if (s == "match_ready") {
            SetStatus(Status::MatchFound);
        } else if (s == "canceled") {
            SetStatus(Status::NotQueued);
        } else if (s == "pending") {
            SetStatus(Status::WaitingForPartner);
        } else {
            Log::Error("unknown status: " + s);
            SetStatus(Status::NotQueued);
        }
    }
}
