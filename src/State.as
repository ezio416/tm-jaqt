// c 2025-07-03
// m 2025-07-03

namespace State {
    bool    cancel      = false;
    Match@  match;
    Player@ me;
    uint64  queueStart = 0;
    Status  status     = Status::NotQueued;

    enum Status {
        NotQueued,
        Queueing,
        Queued,
        MatchFound,
        Joining,
        InMatch
    }

    void SetStatus(const Status s) {
        status = s;
    }

    void SetStatus(const string&in s) {
        const string funcName = "State::SetStatus";

        if (s == "queued") {
            SetStatus(Status::Queued);
        } else if (s == "match_ready") {
            SetStatus(Status::MatchFound);
        } else if (s == "canceled") {
            SetStatus(Status::NotQueued);
        } else {
            Log::Warning(funcName, "unknown status: " + s);
            SetStatus(Status::NotQueued);
        }
    }
}
