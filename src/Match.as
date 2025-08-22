// c 2025-07-02
// m 2025-08-21

enum MatchStatus {
    Unknown,
    PENDING,
    ONGOING,
    COMPLETED
}

class Match {
    string      joinLink;
    string      liveId;
    string      mapUid;
    string      serverLogin;
    MatchStatus status = MatchStatus::Unknown;

    Match(Json::Value@ json) {
        if (true
            and json.HasKey("joinLink")
            and json["joinLink"].GetType() == Json::Type::String
        ) {
            joinLink = string(json["joinLink"]).Replace("#join=", "#qjoin=");
            serverLogin = joinLink.Replace("#qjoin=", "").Replace("@Trackmania", "");
        }

        if (true
            and json.HasKey("liveId")
            and json["liveId"].GetType() == Json::Type::String
        ) {
            liveId = string(json["liveId"]);
        }

        if (true
            and json.HasKey("status")
            and json["status"].GetType() == Json::Type::String
        ) {
            const string matchStatus = string(json["status"]);

            if (matchStatus == "PENDING") {
                status = MatchStatus::PENDING;
            } else if (matchStatus == "ONGOING") {
                status = MatchStatus::ONGOING;
            } else if (matchStatus == "COMPLETED") {
                status = MatchStatus::COMPLETED;
            } else {
                Log::Warning("Match", "unknown status: " + matchStatus);
            }
        }

        if (true
            and json.HasKey("publicConfig")
            and json["publicConfig"].GetType() == Json::Type::Object
            and json["publicConfig"].HasKey("maps")
            and json["publicConfig"]["maps"].GetType() == Json::Type::Array
            and json["publicConfig"]["maps"].Length > 0
            and json["publicConfig"]["maps"][0].GetType() == Json::Type::String
        ) {
            mapUid = string(json["publicConfig"]["maps"][0]);
        }
    }

    bool In() {
        auto App = cast<CTrackMania>(GetApp());
        auto Network = cast<CTrackManiaNetwork>(App.Network);
        auto ServerInfo = cast<CTrackManiaNetworkServerInfo>(Network.ServerInfo);

        return true
            and ServerInfo.ServerLogin.Length > 0
            and ServerInfo.ServerLogin == serverLogin
        ;
    }

    bool JoinAsync() {
        if (joinLink.Length == 0) {
            return false;
        }

        Log::Info("Match::JoinAsync", "joining | " + joinLink);

        auto App = cast<CTrackMania>(GetApp());

        if (true
            and App.ManiaPlanetScriptAPI.ActiveContext_InGameMenuDisplayed
            and App.CurrentPlayground !is null
            and App.CurrentPlayground.Interface !is null
        ) {
            App.CurrentPlayground.Interface.ManialinkScriptHandler.CloseInGameMenu(
                CGameScriptHandlerPlaygroundInterface::EInGameMenuResult::Resume
            );
            yield();
        }

        App.ManiaPlanetScriptAPI.OpenLink(joinLink, CGameManiaPlanetScriptAPI::ELinkType::ManialinkBrowser);

        State::SetStatus(State::Status::Joining);

        return true;
    }

    Json::Value@ ToJson() {
        Json::Value@ ret = Json::Object();

        ret["joinLink"]    = joinLink;
        ret["liveId"]      = liveId;
        ret["mapUid"]      = mapUid;
        ret["serverLogin"] = serverLogin;

        return ret;
    }

    string ToString() {
        return Json::Write(ToJson());
    }
}
