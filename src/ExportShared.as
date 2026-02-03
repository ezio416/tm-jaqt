namespace JAQT {
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
