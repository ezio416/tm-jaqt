// c 2025-08-22
// m 2025-08-25

namespace Partner {
    Player@[]    friends;
    bool         gettingFriends = false;
    bool         gettingRecent  = false;
    bool         gotFriends     = false;
    bool         gotRecent      = false;
    Player@      partner;
    Player@[]    recent;
    const string recentFile     = IO::FromStorageFolder("recent.json");
    Player@[]    search;
    bool         searching      = false;

    bool get_exists() {
        return partner !is null;
    }

    void Add(Player@ player) {
        @partner = player;
    }

    void AddRecent(Player@ player) {
        const string funcName = "Partner::AddRecent";

        if (false
            or S_RecentRemember == 0
            or player.accountId == State::me.accountId
        ) {
            return;
        }

        while (recent.Length >= S_RecentRemember) {
            recent.RemoveAt(0);
        }

        for (uint i = 0; i < recent.Length; i++) {
            if (player.accountId == recent[i].accountId) {
                Log::Debug(funcName, "found player '" + player.name + "' at index " + i);
                recent.RemoveAt(i);
                break;
            }
        }

        player.lastMatch = Time::Stamp;
        recent.InsertLast(player);
        Log::Debug(funcName, tostring(player));
        SaveRecent();
    }

    void GetFriendsAsync() {
        if (gettingFriends) {
            return;
        }

        const string funcName = "Partner::GetFriendsAsync";

        auto App = cast<CTrackMania>(GetApp());
        if (false
            or App.ManiaPlanetScriptAPI is null
            or App.ManiaPlanetScriptAPI.UserMgr is null
            or App.ManiaPlanetScriptAPI.UserMgr.Users.Length == 0
            or App.ManiaPlanetScriptAPI.UserMgr.Users[0] is null
        ) {
            Log::Warning(funcName, "unable to get friends list");
            return;
        }

        gettingFriends = true;

        CWebServicesTaskResult_FriendListScript@ task = App.ManiaPlanetScriptAPI.UserMgr.Friend_GetList(
            App.ManiaPlanetScriptAPI.UserMgr.Users[0].Id
        );
        while (task.IsProcessing) {
            yield();
        }

        if (false
            or task.HasFailed
            or !task.HasSucceeded
        ) {
            Log::Warning(funcName, "task failed: " + task.ErrorCode + " | " + task.ErrorDescription);
            try {
                App.ManiaPlanetScriptAPI.UserMgr.TaskResult_Release(task.Id);
            } catch { }
            gettingFriends = false;
            return;
        }

        friends = {};

        if (task.FriendList.Length == 0) {
            Log::Warning(funcName, "you have no friends :(");
            gettingFriends = false;
            return;
        }

        for (uint i = 0; i < task.FriendList.Length; i++) {
            if (task.FriendList[i] !is null) {
                Log::Debug(funcName, "found friend: " + task.FriendList[i].DisplayName + " | "
                    + task.FriendList[i].AccountId + " | " + task.FriendList[i].Presence);
                friends.InsertLast(Player(task.FriendList[i]));
            } else {
                Log::Warning(funcName, "null friend");
            }
        }

        try {
            App.ManiaPlanetScriptAPI.UserMgr.TaskResult_Release(task.Id);
        } catch { }

        friends.SortNonConst(SortPlayersAsc);

        dictionary friendsById;
        for (uint i = 0; i < friends.Length; i++) {
            friendsById.Set(friends[i].accountId, @friends[i]);
        }

        Json::Value@ req = Http::Nadeo::GetLeaderboardPlayersAsync(friendsById.GetKeys());
        if (true
            and req !is null
            and req.GetType() == Json::Type::Object
            and req["results"].GetType() == Json::Type::Array
        ) {
            Json::Value@ results = req["results"];
            for (uint i = 0; i < results.Length; i++) {
                try {
                    Player@ friend = cast<Player>(friendsById[string(results[i]["player"])]);
                    friend.progression = uint(results[i]["score"]);
                    friend.rank = uint(results[i]["rank"]);
                    Log::Debug(funcName, friend.name + " | prog " + friend.progression + " | rank " + friend.rank);
                } catch {
                    Log::Error(getExceptionInfo());
                }
            }
        }

        gettingFriends = false;
    }

    void GetRecentInfoAsync() {
        if (gettingRecent) {
            return;
        }
        gettingRecent = true;

        const string funcName = "Partner::GetRecentInfoAsync";

        dictionary recentById;
        for (uint i = 0; i < recent.Length; i++) {
            recentById.Set(recent[i].accountId, @recent[i]);
        }

        Json::Value@ req = Http::Nadeo::GetLeaderboardPlayersAsync(recentById.GetKeys());
        if (true
            and req !is null
            and req.GetType() == Json::Type::Object
            and req["results"].GetType() == Json::Type::Array
        ) {
            Json::Value@ results = req["results"];
            for (uint i = 0; i < results.Length; i++) {
                try {
                    Player@ player = cast<Player>(recentById[string(results[i]["player"])]);
                    player.progression = uint(results[i]["score"]);
                    player.rank = uint(results[i]["rank"]);
                    Log::Debug(funcName, player.name + " | prog " + player.progression + " | rank " + player.rank);
                } catch {
                    Log::Error(getExceptionInfo());
                }
            }
        }

        dictionary@ names = NadeoServices::GetDisplayNamesAsync(recentById.GetKeys());
        for (uint i = 0; i < recent.Length; i++) {
            recent[i].name = string(names[recent[i].accountId]);
        }

        gettingRecent = false;
    }

    void LoadRecent() {
        if (!IO::FileExists(recentFile)) {
            return;
        }

        recent = {};

        try {
            Json::Value@ loaded = Json::FromFile(recentFile);
            for (uint i = 0; i < loaded.Length; i++) {
                recent.InsertLast(Player(loaded[i]));
            }

            Log::Info("Partner::LoadRecent", "loaded " + recent.Length + " players");

        } catch {
            Log::Error(getExceptionInfo());
        }
    }

    void Remove() {
        @partner = null;
    }

    void SaveRecent() {
        Json::Value@ data = Json::Array();

        for (uint i = 0; i < recent.Length; i++) {
            Json::Value@ player = Json::Object();
            player["accountId"] = recent[i].accountId;
            player["lastMatch"] = recent[i].lastMatch;
            player["name"] = recent[i].name;
            data.Add(player);
        }

        try {
            Json::ToFile(recentFile, data, true);
            Log::Info("Partner::SaveRecent", "saved " + recent.Length + " players");
        } catch {
            Log::Error(getExceptionInfo());
        }
    }

    void SearchAsync() {
        if (false
            or searching
            or Http::Tmio::playerSearch.Length < 4
        ) {
            return;
        }
        searching = true;

        const string funcName = "Partner::SearchAsync";

        search = {};

        Json::Value@ req = Http::Tmio::GetAccountsFromSearchAsync();
        if (false
            or req is null
            or req.GetType() != Json::Type::Array
        ) {
            Log::Error("bad response");
            searching = false;
            return;
        }

        dictionary searchById;

        for (uint i = 0; i < req.Length; i++) {
            if (req[i]["player"].GetType() != Json::Type::Object) {
                Log::Warning(funcName, "bad player: " + Json::Write(req[i]));
                continue;
            }

            try {
                Player@ player = Player(req[i]["player"], false);
                search.InsertLast(player);
                searchById.Set(player.accountId, @player);
            } catch {
                Log::Error(getExceptionInfo());
            }
        }

        if (search.Length > 1) {
            search.SortNonConst(SortPlayersAsc);
        }

        @req = Http::Nadeo::GetLeaderboardPlayersAsync(searchById.GetKeys());
        if (true
            and req !is null
            and req.GetType() == Json::Type::Object
            and req["results"].GetType() == Json::Type::Array
        ) {
            Json::Value@ results = req["results"];
            for (uint i = 0; i < results.Length; i++) {
                try {
                    Player@ player = cast<Player>(searchById[string(results[i]["player"])]);
                    player.progression = uint(results[i]["score"]);
                    player.rank = uint(results[i]["rank"]);
                    Log::Debug(funcName, player.name + " | prog " + player.progression + " | rank " + player.rank);
                } catch {
                    Log::Error(getExceptionInfo());
                }
            }
        }

        searching = false;
    }
}
