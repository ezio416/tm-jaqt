// c 2025-07-02
// m 2025-08-25

enum FriendStatus {
    Online,
    Away,
    DoNotDisturb,
    Offline
}

class Player {
    string       accountId;
    bool         frozen       = false;
    bool         hasPenalty   = false;
    uint         immunityDays = 0;
    int64        lastMatch    = 0;
    string       name;
    FriendStatus status       = FriendStatus::Offline;
    int          penalty      = 0;
    CSmPlayer@   player;
    uint         progression  = 0;
    uint         rank         = 0;
    bool         self         = false;

    bool get_canPartner() {
        return Math::Abs(int(State::me.progression) - progression) <= 1000;
    }

    Division@ get_division() {
        return GetPlayerDivision(progression, rank);
    }

    protected int _score = 0;
    int get_score() {
        if (true
            and !frozen
            and player !is null
            and player.Score !is null
        ) {
            _score = player.Score.Points;
        }

        return _score;
    }

    protected int _team = -1;
    int get_team() {
        if (true
            and !frozen
            and player !is null
            and player.Score !is null
        ) {
            _team = player.Score.TeamNum;
        }

        return _team;
    }

    Player() { }

    Player(CSmPlayer@ player) {
        accountId    = player.User.WebServicesUserId;
        name         = player.User.Name;
        @this.player = player;
        this.player.MwAddRef();
    }

    Player(CFriend@ friend) {
        accountId = friend.AccountId;
        name      = friend.DisplayName;

        if (friend.Presence == "Online") {
            status = FriendStatus::Online;
        } else if (friend.Presence == "Away") {
            status = FriendStatus::Away;
        } else if (friend.Presence == "DoNotDisturb") {
            status = FriendStatus::DoNotDisturb;
        }
    }

    Player(Json::Value@ json, const bool recent = true) {
        if (recent) {
            accountId = string(json["accountId"]);
            lastMatch = int64(json["lastMatch"]);
        } else {  // tmio search
            accountId = string(json["id"]);
            name      = string(json["name"]);
        }
    }

    Json::Value@ ToJson() {
        Json::Value@ ret = Json::Object();

        ret["accountId"]    = accountId;
        ret["division"]     = division.ToJson();
        ret["hasPenalty"]   = hasPenalty;
        ret["immunityDays"] = immunityDays;
        ret["name"]         = name;
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

class FakePlayer : Player {
    FakePlayer() {
        accountId = GenerateUUID();
    }

    int get_score() override {
        return _score;
    }

    int get_team() override {
        return _team;
    }

    void set_score(const int s) {
        _score = s;
    }

    void set_team(const int t) {
        _team = t;
    }
}

void GetMyStatusAsync() {
    const string funcName = "GetMyStatusAsync";

    if (!State::me.self) {
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

bool SortPlayersAsc(Player@&in a, Player@&in b) {
    if (a.status != b.status) {
        return a.status < b.status;
    }

    if (a.team != b.team) {
        return a.team < b.team;
    }

    return a.name.ToLower() < b.name.ToLower();
}
