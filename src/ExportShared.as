// c 2025-08-25
// m 2025-08-25

namespace SimpleRanked {
    shared enum Status {
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
}
