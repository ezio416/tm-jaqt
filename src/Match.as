// c 2025-07-02
// m 2025-07-03

class Match {
    string joinLink;
    string liveId;
    string mapUid;

    Match(Json::Value@ json) {
        if (true
            and json.HasKey("joinLink")
            and json["joinLink"].GetType() == Json::Type::String
        ) {
            joinLink = string(json["joinLink"]).Replace("#join=", "#qjoin=");
        }

        if (true
            and json.HasKey("liveId")
            and json["liveId"].GetType() == Json::Type::String
        ) {
            liveId = string(json["liveId"]);
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

    bool JoinAsync() {
        if (joinLink.Length == 0) {
            return false;
        }

        print("joining: " + joinLink);

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

        App.ManiaPlanetScriptAPI.OpenLink(
            joinLink,
            CGameManiaPlanetScriptAPI::ELinkType::ManialinkBrowser
        );

        status = QueueStatus::Joining;
        return true;
    }

    Json::Value@ ToJson() {
        Json::Value@ ret = Json::Object();

        ret["joinLink"] = joinLink;
        ret["liveId"]   = liveId;
        ret["mapUid"]   = mapUid;

        return ret;
    }

    string ToString() {
        return Json::Write(ToJson());
    }
}
