// c 2025-07-02
// m 2025-08-23

const vec4[] divisionColors = {
    vec4(vec3(0.45f, 0.27f, 0.13f), 1.0f),
    vec4(vec3(0.44f), 1.0f),
    vec4(vec3(0.82f, 0.56f, 0.0f), 1.0f),
    vec4(vec3(0.36f, 0.68f, 0.12f), 1.0f)
};

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

const string[] divisionShortNames = {
    "--",
    "B1",
    "B2",
    "B3",
    "S1",
    "S2",
    "S3",
    "G1",
    "G2",
    "G3",
    "M1",
    "M2",
    "M3",
    "TM"
};

enum DivisionRuleType {
    Unknown,
    MinimumPoints,
    MinimumRankAndPoints,
    PointsRange
}

class Division {
    vec4             color         = divisionColors[0];
    string           colorStr      = Text::FormatOpenplanetColor(color.xyz);
    UI::Texture@     icon;
    uint             maximumPoints = 0;
    uint             minimumPoints = 0;
    uint             minimumRank   = 0;
    string           name          = divisionNames[0];
    uint             position      = 0;
    string           shortName     = divisionShortNames[0];
    DivisionRuleType type          = DivisionRuleType::Unknown;

    Division() { }
    Division(Json::Value@ json) {
        if (true
            and json.HasKey("position")
            and json["position"].GetType() == Json::Type::Number
        ) {
            position = uint(json["position"]);
        } else {
            Log::Warning("Division", "error with 'position'");
        }

        if (true
            and position >= 1
            and position <= 13
        ) {
            color = divisionColors[Math::Min(position - 1, 11) / 3];
            colorStr = Text::FormatOpenplanetColor(color.xyz);
            name = divisionNames[position];
            shortName = divisionShortNames[position];
        } else {
            Log::Warning("Division", "unknown position: " + position);
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
            Log::Warning("Division", "error with 'displayRuleType'");
        }

        if (true
            and json.HasKey("displayRuleMinimumPoints")
            and json["displayRuleMinimumPoints"].GetType() == Json::Type::Number
        ) {
            minimumPoints = uint(json["displayRuleMinimumPoints"]);
        } else {
            Log::Warning("Division", "error with 'displayRuleMinimumPoints'");
        }

        if (true
            and json.HasKey("displayRuleMaximumPoints")
            and json["displayRuleMaximumPoints"].GetType() == Json::Type::Number
        ) {
            maximumPoints = uint(json["displayRuleMaximumPoints"]);
        } else if (type == DivisionRuleType::PointsRange) {
            Log::Warning("Division", "error with 'displayRuleMaximumPoints'");
        }

        if (true
            and json.HasKey("displayRuleMinimumRank")
            and json["displayRuleMinimumRank"].GetType() == Json::Type::Number
        ) {
            minimumRank = uint(json["displayRuleMinimumRank"]);
        } else if (type == DivisionRuleType::MinimumRankAndPoints) {
            Log::Warning("Division", "error with 'displayRuleMinimumRank'");
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
        @icon = UI::LoadTexture(path);

        if (icon is null) {
            Log::Error("not found: " + path);
        }
    }

    void RenderIcon(const vec2&in size, bool hover = false) {
        if (icon is null) {
            UI::Dummy(size);
            return;
        }

        UI::Image(icon, size);

        if (true
            and hover
            and UI::IsItemHovered()
        ) {
            UI::BeginTooltip();
            UI::Image(icon, icon.GetSize());
            UI::EndTooltip();
        }
    }

    Json::Value@ ToJson() {
        Json::Value@ ret = Json::Object();

        ret["maximumPoints"] = maximumPoints;
        ret["minimumPoints"] = minimumPoints;
        ret["minimumRank"]   = minimumRank;
        ret["name"]          = name;
        ret["position"]      = position;
        ret["shortName"]     = shortName;
        ret["type"]          = int(type);

        return ret;
    }

    string ToString() {
        return Json::Write(ToJson());
    }
}

bool GetDivisionsAsync() {
    try {
        Json::Value@ response = Http::Nadeo::GetDivisionDisplayRulesAsync()["divisions"];

        divisions = { Division() };
        for (uint i = 0; i < response.Length; i++) {
            divisions.InsertLast(Division(response[i]));
        }
        divisions.Sort(function(a, b) { return a.position < b.position; });

        for (uint i = 0; i < divisions.Length; i++) {
            divisions[i].LoadIcon("assets/" + divisions[i].position + ".png");
        }

        if (divisions.Length > 1) {
            divisions[1].minimumPoints = 1;
        }

        return true;

    } catch {
        Log::Error(getExceptionInfo());
        return false;
    }
}

Division@ GetPlayerDivision(const uint progression, const uint rank = 0) {
    for (int i = divisions.Length - 1; i > 0; i--) {
        if (divisions[i].In(progression, rank)) {
            return divisions[i];
        }
    }
    return divisions[0];
}
