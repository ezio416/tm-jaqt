// c 2025-07-03
// m 2025-07-03

namespace State {
    bool    cancel = false;
    Match@  match;
    Player@ me;
    Status  status = Status::None;

    enum Status {
        None,
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
            SetStatus(Status::None);
        } else {
            Log::Warning(funcName, "unknown status: " + s);
            SetStatus(Status::None);
        }
    }
}
