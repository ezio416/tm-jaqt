// c 2025-07-02
// m 2025-07-02

const string[] divisionNames = {
    "Unknown",
    "Bronze I",
    "Bronze II",
    "Bronze III",
    "Silver I",
    "Silver II",
    "Silver III",
    "Gold I",
    "Gold II",
    "Gold III",
    "Master I",
    "Master II",
    "Master III",
    "Trackmaster"
};

enum DivisionRuleType {
    Unknown,
    MinimumPoints,
    MinimumRankAndPoints,
    PointsRange
}

class Division {
    UI::Texture@     icon;
    uint             maximumPoints = 0;
    uint             minimumPoints = 0;
    uint             minimumRank   = 0;
    string           name          = divisionNames[0];
    uint             position      = 0;
    DivisionRuleType type          = DivisionRuleType::Unknown;

    Division() { }
    Division(Json::Value@ json) {
        if (true
            and json.HasKey("position")
            and json["position"].GetType() == Json::Type::Number
        ) {
            position = uint(json["position"]);
        } else {
            warn("Division | error with 'position'");
        }

        if (true
            and position >= 1
            and position <= 13
        ) {
            name = divisionNames[position];
        } else {
            warn("Division | unknown position: " + position);
        }

        if (true
            and json.HasKey("displayRuleType")
            and json["displayRuleType"].GetType() == Json::Type::String
        ) {
            const string _type = string(json["displayRuleType"]);
            if (_type == "minimum_points") {
                type = DivisionRuleType::MinimumPoints;
            } else if (_type == "minimum_rank_and_points") {
                type = DivisionRuleType::MinimumRankAndPoints;
            } else if (_type == "points_range") {
                type = DivisionRuleType::PointsRange;
            }
        } else {
            warn("Division | error with 'displayRuleType'");
        }

        if (true
            and json.HasKey("displayRuleMinimumPoints")
            and json["displayRuleMinimumPoints"].GetType() == Json::Type::Number
        ) {
            minimumPoints = uint(json["displayRuleMinimumPoints"]);
        } else {
            warn("Division | error with 'displayRuleMinimumPoints'");
        }

        if (true
            and json.HasKey("displayRuleMaximumPoints")
            and json["displayRuleMaximumPoints"].GetType() == Json::Type::Number
        ) {
            maximumPoints = uint(json["displayRuleMaximumPoints"]);
        } else if (type == DivisionRuleType::PointsRange) {
            warn("Division | error with 'displayRuleMaximumPoints'");
        }

        if (true
            and json.HasKey("displayRuleMinimumRank")
            and json["displayRuleMinimumRank"].GetType() == Json::Type::Number
        ) {
            minimumRank = uint(json["displayRuleMinimumRank"]);
        } else if (type == DivisionRuleType::MinimumRankAndPoints) {
            warn("Division | error with 'displayRuleMinimumRank'");
        }
    }

    bool In(const uint points, const uint rank = 0) {
        switch (type) {
            case DivisionRuleType::MinimumPoints:
                return points >= minimumPoints;

            case DivisionRuleType::MinimumRankAndPoints:
                return true
                    and points >= minimumPoints
                    and rank <= minimumRank
                ;

            case DivisionRuleType::PointsRange:
                return true
                    and points >= minimumPoints
                    and points <= maximumPoints
                ;

            default:
                return false;
        }
    }

    void LoadIcon(const string&in path) {
        if (IO::FileExists(path)) {
            @icon = UI::LoadTexture(path);
        } else {
            warn("Division::LoadIcon | not found: " + path);
        }
    }

    void RenderIcon(const vec2&in size) {
        if (icon is null) {
            return;
        }

        UI::Image(icon, size);
    }

    string ToString() {
        string ret = "division " + position + " (" + name + "): ";

        switch (type) {
            case DivisionRuleType::MinimumPoints:
                ret += "min points: " + minimumPoints;
                break;

            case DivisionRuleType::MinimumRankAndPoints:
                ret += "min rank: " + minimumRank + ", min points: " + minimumPoints;
                break;

            case DivisionRuleType::PointsRange:
                ret += "points range: " + minimumPoints + "-" + maximumPoints;
                break;

            default:
                ret += "unknown";
        }

        return ret;
    }
}

Division@ GetDivision(const uint points, const uint rank = 0) {
    for (uint i = 1; i < divisions.Length; i++) {
        if (divisions[i].In(points, rank)) {
            return divisions[i];
        }
    }
    return divisions[0];
}

bool GetDivisionsAsync() {
    try {
        Json::Value@ response = API::Nadeo::GetMeetAsync("matchmaking/ranked-2v2/division/display-rules")["divisions"];
        divisions = { Division() };
        for (uint i = 0; i < response.Length; i++) {
            divisions.InsertLast(Division(response[i]));
        }
        divisions.Sort(function(a, b) { return a.position < b.position; });
        return true;
    } catch {
        error("Divisions::GetAsync | " + getExceptionInfo());
        return false;
    }
}
