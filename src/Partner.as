// c 2025-08-22
// m 2025-08-23

namespace Partner {
    Player@[] friends;
    bool      gettingFriends = false;
    Player@   partner;

    bool get_exists() {
        return partner !is null;
    }

    void Add(Player@ player) {
        @partner = player;
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

        friends.Sort(SortFriendsAsc);

        dictionary friendsById;
        for (uint i = 0; i < friends.Length; i++) {
            friendsById.Set(friends[i].accountId, @friends[i]);
        }

        Json::Value@ req = Http::Nadeo::GetLeaderboardPlayersAsync(friendsById.GetKeys());
        if (true
            and req !is null
            and req.GetType() == Json::Type::Object
            and req.HasKey("results")
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

    void Remove() {
        @partner = null;
    }

    bool SortFriendsAsc(const Player@const&in a, const Player@const&in b) {
        if (a.online != b.online) {
            return a.online;
        }

        return a.name.ToLower() < b.name.ToLower();
    }
}
