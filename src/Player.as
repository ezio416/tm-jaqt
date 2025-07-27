// c 2025-07-02
// m 2025-07-26

class Player {
    string     accountId;
    bool       hasPenalty   = false;
    uint       immunityDays = 0;
    uint       matchPb      = 0;
    bool       mvp          = false;
    string     name;
    uint       pb           = 0;
    uint64     pbTimestamp  = 0;
    int        penalty      = 0;
    CSmPlayer@ player;
    uint       progression  = 0;
    uint       rank         = 0;
    uint       score        = 0;
    bool       self         = false;
    int        team         = -1;

    Division@ get_division() {
        return GetPlayerDivision(progression, rank);
    }

    uint get_score() {
        // auto Playground = cast<CSmArenaClient>(GetApp().CurrentPlayground);
        // if (Playground !is null) {
        //     for (uint i = 0; i < Playground.Players.Length; i++) {
        //         auto player = cast<CSmPlayer>(Playground.Players[i]);
        //         if (true
        //             and player !is null
        //             and player.User !is null
        //             and player.User.WebServicesUserId == accountId
        //             and player.Score !is null
        //         ) {
        //             return player.Score.Points;
        //         }
        //     }
        // }

        if (true
            and player !is null
            and player.Score !is null
        ) {
            return player.Score.Points;
        }

        return 0;
    }

    int get_team() {
        // auto Playground = cast<CSmArenaClient>(GetApp().CurrentPlayground);
        // if (Playground !is null) {
        //     for (uint i = 0; i < Playground.Players.Length; i++) {
        //         auto player = cast<CSmPlayer>(Playground.Players[i]);
        //         if (true
        //             and player !is null
        //             and player.User !is null
        //             and player.User.WebServicesUserId == accountId
        //             and player.Score !is null
        //         ) {
        //             return player.Score.TeamNum;
        //         }
        //     }
        // }

        if (true
            and player !is null
            and player.Score !is null
        ) {
            return player.Score.TeamNum;
        }

        return -1;
    }

    Player() { }
    Player(CSmPlayer@ player) {
        accountId    = player.User.WebServicesUserId;
        name         = player.User.Name;
        @this.player = player;
        this.player.MwAddRef();
    }

    Json::Value@ ToJson() {
        Json::Value@ ret = Json::Object();

        ret["accountId"]    = accountId;
        ret["division"]     = division.ToJson();
        ret["hasPenalty"]   = hasPenalty;
        ret["immunityDays"] = immunityDays;
        ret["matchPb"]      = matchPb;
        ret["mvp"]          = mvp;
        ret["name"]         = name;
        ret["pb"]           = pb;
        ret["pbTimestamp"]  = pbTimestamp;
        ret["penalty"]      = penalty;
        ret["progression"]  = progression;
        ret["rank"]         = rank;
        ret["score"]        = score;
        ret["self"]         = self;
        ret["team"]         = team;

        return ret;
    }

    string ToString() {
        return Json::Write(ToJson());
    }
}

void GetMyStatusAsync() {
    const string funcName = "GetMyStatusAsync";

    if (State::me is null) {
        @State::me = Player();

        State::me.accountId = GetApp().LocalPlayerInfo.WebServicesUserId;
        State::me.self = true;
    }

    Json::Value@ status = Http::Nadeo::GetPlayerStatusAsync();

    if (true
        and status.HasKey("currentProgression")
        and status["currentProgression"].GetType() == Json::Type::Number
    ) {
        State::me.progression = uint(status["currentProgression"]);
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

    Json::Value@ leaderboard = Http::Nadeo::GetLeaderboardPlayersAsync({ State::me.accountId });

    if (true
        and leaderboard.HasKey("results")
        and leaderboard["results"].GetType() == Json::Type::Array
        and leaderboard["results"].Length > 0
        and leaderboard["results"][0].GetType() == Json::Type::Object
        and leaderboard["results"][0].HasKey("rank")
        and leaderboard["results"][0]["rank"].GetType() == Json::Type::Number
    ) {
        State::me.rank = uint(leaderboard["results"][0]["rank"]);
    } else {
        Log::Warning(funcName, "error getting my rank");
    }
}

void SetMVP() {
    uint bestTime = uint(-1);
    Player@ mvp;
    Player@ player;

    const MLFeed::HookRaceStatsEventsBase_V4@ raceData = MLFeed::GetRaceData_V4();

    for (uint i = 0; i < State::playersArr.Length; i++) {
        @player = State::playersArr[i];
        player.mvp = false;

        if (player.score == 0) {
            continue;
        }

        if (false
            or mvp is null
            or player.score > mvp.score
        ) {
            @mvp = player;
            bestTime = raceData.GetPlayer_V4(player.name).BestTime;
            continue;
        }

        if (player.score == mvp.score) {
            const uint newBest = raceData.GetPlayer_V4(player.name).BestTime;
            if (newBest < bestTime) {
                @mvp = player;
                bestTime = newBest;
            }
        }
    }

    if (mvp !is null) {
        mvp.mvp = true;
    }
}
