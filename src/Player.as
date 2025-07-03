// c 2025-07-02
// m 2025-07-03

class Player {
    Division@ division     = Division();
    bool      hasPenalty   = false;
    uint      immunityDays = 0;
    uint      matchPb      = 0;
    bool      mvp          = false;
    uint      pb           = 0;
    uint64    pbTimestamp  = 0;
    int       penalty      = 0;
    uint      points       = 0;
    uint      progression  = 0;
    uint      rank         = 0;
    bool      self         = false;

    Division@ GetDivision() {
        @division = GetPlayerDivision(progression, rank);
        return division;
    }

    Json::Value@ ToJson() {
        Json::Value@ ret = Json::Object();

        ret["division"]     = division.ToJson();
        ret["hasPenalty"]   = hasPenalty;
        ret["immunityDays"] = immunityDays;
        ret["matchPb"]      = matchPb;
        ret["mvp"]          = mvp;
        ret["pb"]           = pb;
        ret["pbTimestamp"]  = pbTimestamp;
        ret["penalty"]      = penalty;
        ret["points"]       = points;
        ret["progression"]  = progression;
        ret["rank"]         = rank;
        ret["self"]         = self;

        return ret;
    }

    string ToString() {
        return Json::Write(ToJson());
    }
}

void GetMyStatusAsync() {
    const string funcName = "GetMyStatusAsync";

    Json::Value@ status = API::Nadeo::GetPlayerStatusAsync();

    if (State::me is null) {
        @State::me = Player();
        State::me.self = true;
    }

    if (true
        and status.HasKey("currentProgression")
        and status["currentProgression"].GetType() == Json::Type::Number
    ) {
        State::me.progression = uint(status["currentProgression"]);
        State::me.GetDivision();
    }

    if (status.HasKey("inactivity")) {
        Json::Value@ inactivity = status["inactivity"];

        if (true
            and inactivity.HasKey("inactivityPenaltyEnabled")
            and inactivity["inactivityPenaltyEnabled"].GetType() == Json::Type::Boolean
        ) {
            State::me.hasPenalty = bool(inactivity["inactivityPenaltyEnabled"]);
        }

        if (true
            and inactivity.HasKey("immunityDays")
            and inactivity["immunityDays"].GetType() == Json::Type::Number
        ) {
            State::me.immunityDays = uint(inactivity["immunityDays"]);
        }

        if (true
            and inactivity.HasKey("penalty")
            and inactivity["penalty"].GetType() == Json::Type::Number
        ) {
            State::me.penalty = int(inactivity["penalty"]);
        }
    }
}
