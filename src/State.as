// c 2025-07-03
// m 2025-08-25

namespace State {
    uint                 activePlayers = 0;
    bool                 cancel        = false;
    bool                 frozen        = false;
    string               mapName;
    UI::Texture@         mapThumbnail;
    string               mapThumbnailUrl;
    Match@               match;
    Player               me;
    dictionary           players;
    Player@[]            playersArr;
    int64                queueStart    = 0;
    SimpleRanked::Status status        = SimpleRanked::Status::NotQueued;

    void SetStatus(const SimpleRanked::Status s) {
        status = s;
    }

    void SetStatus(const string&in s) {
        if (s == "queued") {
            SetStatus(SimpleRanked::Status::Queued);
        } else if (s == "match_ready") {
            SetStatus(SimpleRanked::Status::MatchFound);
        } else if (s == "canceled") {
            SetStatus(SimpleRanked::Status::NotQueued);
        } else if (s == "pending") {
            SetStatus(SimpleRanked::Status::WaitingForPartner);
        } else {
            Log::Error("unknown status: " + s);
            SetStatus(SimpleRanked::Status::NotQueued);
        }
    }
}
