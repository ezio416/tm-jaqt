// c 2025-07-02
// m 2025-07-03

class Player {
    Division@ division     = Division();
    bool      hasPenalty   = false;
    uint      immunityDays = 0;
    uint      matchPb      = 0;
    bool      mvp          = false;
    bool      myself       = false;
    uint      pb           = 0;
    uint64    pbTimestamp  = 0;
    int       penalty      = 0;
    uint      points       = 0;
    uint      progression  = 0;
    uint      rank         = 0;

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
        ret["myself"]       = myself;
        ret["pb"]           = pb;
        ret["pbTimestamp"]  = pbTimestamp;
        ret["penalty"]      = penalty;
        ret["points"]       = points;
        ret["progression"]  = progression;
        ret["rank"]         = rank;

        return ret;
    }

    string ToString() {
        return Json::Write(ToJson());
    }
}

void GetMyStatusAsync() {
    try {
        Json::Value@ response = API::Nadeo::GetPlayerStatusAsync();
        print("GetMyStatusAsync | " + Json::Write(response, true));

        if (me is null) {
            @me = Player();
            me.myself = true;
        }

        if (response.HasKey("currentHeartbeat")) {
            // print("currentHeartbeat: " + Json::Write(response["currentHeartbeat"], true));
        }

        if (true
            and response.HasKey("currentProgression")
            and response["currentProgression"].GetType() == Json::Type::Number
        ) {
            me.progression = uint(response["currentProgression"]);
            me.GetDivision();
        }

        if (response.HasKey("inactivity")) {
            Json::Value@ inactivity = response["inactivity"];

            if (inactivity.HasKey("inactivityPenaltyEnabled")) {
                me.hasPenalty = bool(inactivity["inactivityPenaltyEnabled"]);

                if (true
                    and inactivity.HasKey("penalty")
                    and inactivity["penalty"].GetType() == Json::Type::Number
                ) {
                    me.penalty = int(inactivity["penalty"]);
                }
            }

            if (true
                and inactivity.HasKey("immunityDays")
                and inactivity["immunityDays"].GetType() == Json::Type::Number
            ) {
                me.immunityDays = uint(inactivity["immunityDays"]);
            }
        }

    } catch {
        error("GetMyStatusAsync | " + getExceptionInfo());
        return;
    }
}
