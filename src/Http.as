// c 2025-07-02
// m 2025-08-21

namespace Http {
    namespace Nadeo {
        const string audienceLive  = "NadeoLiveServices";
        uint64       lastHeartbeat = 0;
        uint64       lastRequest   = 0;
        const uint64 waitTime      = 500;

        void CancelQueueAsync() {
            State::cancel = true;
            Log::Info("Http::Nadeo::CancelQueueAsync", "canceling queue");
            PostMeetAsync("/matchmaking/ranked-2v2/cancel");
        }

        Json::Value@ GetDivisionDisplayRulesAsync() {
            const string funcName = "Http::Nadeo::GetDivisionDisplayRulesAsync";

            const string endpoint = "/matchmaking/ranked-2v2/division/display-rules";
            Json::Value@ response = GetMeetAsync(endpoint);

            Log::Debug(funcName, endpoint + " | " + Json::Write(response));

            if (response !is null) {
                Log::ResponseToFile(funcName, response);

                if (response.GetType() == Json::Type::Object) {
                    return response;
                }
            }

            Log::Error("bad response");
            return null;
        }

        Json::Value@ GetLeaderboardPlayersAsync(const string[]@ accountIds) {
            const string funcName = "Http::Nadeo::GetLeaderboardPlayersAsync";

            if (accountIds.Length == 0) {
                Log::Warning(funcName, "accountIds empty");
                return null;
            }

            const string endpoint = "/matchmaking/ranked-2v2/leaderboard/players?players[]=" + string::Join(accountIds, "&players[]=");
            Json::Value@ response = GetMeetAsync(endpoint);

            Log::Debug(funcName, endpoint + " | " + Json::Write(response));

            if (response !is null) {
                Log::ResponseToFile(funcName, response);

                if (response.GetType() == Json::Type::Object) {
                    return response;
                }
            }

            Log::Error("bad response");
            return null;
        }

        Json::Value@ GetLiveAsync(const string&in endpoint) {
            const string funcName = "Http::Nadeo::GetLiveAsync";

            Net::HttpRequest@ req = NadeoServices::Get(
                audienceLive,
                NadeoServices::BaseURLLive() + "/api/" + (endpoint.StartsWith("/") ? endpoint.SubStr(1) : endpoint)
            );
            StartRequestAsync(req);

            try {
                return req.Json();
            } catch {
                Log::Error(endpoint + " | " + getExceptionInfo());
                return null;
            }
        }

        Json::Value@ GetMapInfo(const string&in mapUid) {
            const string funcName = "Http::Nadeo::GetMapInfo";

            if (mapUid.Length == 0) {
                Log::Warning(funcName, "mapUid blank");
                return null;
            }

            const string endpoint = "/token/map/" + mapUid;
            Json::Value@ response = GetLiveAsync(endpoint);

            Log::Debug(funcName, endpoint + " | " + Json::Write(response));

            if (response !is null) {
                Log::ResponseToFile(funcName, response);

                if (response.GetType() == Json::Type::Object) {
                    return response;
                }
            }

            Log::Error("bad response");
            return null;
        }

        Json::Value@ GetMatchInfoAsync(const string&in liveId) {
            const string funcName = "Http::Nadeo::GetMatchInfoAsync";

            if (liveId.Length == 0) {
                Log::Warning(funcName, "liveId blank");
                return null;
            }

            const string endpoint = "/matches/" + liveId;
            Json::Value@ response = GetMeetAsync(endpoint);

            Log::Debug(funcName, endpoint + " | " + Json::Write(response));

            if (response !is null) {
                Log::ResponseToFile(funcName, response);

                if (response.GetType() == Json::Type::Object) {
                    return response;
                }
            }

            Log::Error("bad response");
            return null;
        }

        Json::Value@ GetMatchParticipantsAsync(const string&in liveId) {
            const string funcName = "Http::Nadeo::GetMatchParticipantsAsync";

            if (liveId.Length == 0) {
                Log::Warning(funcName, "liveId blank");
                return null;
            }

            const string endpoint = "/matches/" + liveId + "/participants";
            Json::Value@ response = GetMeetAsync(endpoint);

            Log::Debug(funcName, endpoint + " | " + Json::Write(response));

            if (response !is null) {
                Log::ResponseToFile(funcName, response);

                if (response.GetType() == Json::Type::Array) {
                    return response;
                }
            }

            Log::Error("bad response");
            return null;
        }

        Json::Value@ GetMeetAsync(const string&in endpoint) {
            const string funcName = "Http::Nadeo::GetMeetAsync";

            Net::HttpRequest@ req = NadeoServices::Get(
                audienceLive,
                NadeoServices::BaseURLMeet() + "/api/" + (endpoint.StartsWith("/") ? endpoint.SubStr(1) : endpoint)
            );
            StartRequestAsync(req);

            try {
                return req.Json();
            } catch {
                Log::Error(endpoint + " | " + getExceptionInfo());
                return null;
            }
        }

        Json::Value@ GetPlayerStatusAsync() {
            const string funcName = "Http::Nadeo::GetPlayerStatusAsync";

            const string endpoint = "/matchmaking/ranked-2v2/player-status";
            Json::Value@ response = GetMeetAsync(endpoint);

            Log::Debug(funcName, endpoint + " | " + Json::Write(response));

            if (response !is null) {
                Log::ResponseToFile(funcName, response);

                if (response.GetType() == Json::Type::Object) {
                    return response;
                }
            }

            Log::Error("bad response");
            return null;
        }

        void InitAsync() {
            NadeoServices::AddAudience(audienceLive);
            while (!NadeoServices::IsAuthenticated(audienceLive)) {
                yield();
            }
        }

        Json::Value@ PostMeetAsync(const string&in endpoint, const string&in body = "") {
            const string funcName = "Http::Nadeo::PostMeetAsync";

            Net::HttpRequest@ req = NadeoServices::Post(
                audienceLive,
                NadeoServices::BaseURLMeet() + "/api/" + (endpoint.StartsWith("/") ? endpoint.SubStr(1) : endpoint),
                body
            );
            StartRequestAsync(req);

            try {
                return req.Json();
            } catch {
                Log::Error(endpoint + " | " + body + " | " + getExceptionInfo());
                return null;
            }
        }

        Json::Value@ SendHeartbeatAsync() {
            const string funcName = "Http::Nadeo::SendHeartbeatAsync";
            const string endpoint = "/matchmaking/ranked-2v2/heartbeat";
            const string body = '{"code":"","playWith":[]}';  // party code would go here

            Json::Value@ response = PostMeetAsync(endpoint, body);
            lastHeartbeat = Time::Now;

            Log::Debug(funcName, endpoint + " | " + Json::Write(response));

            if (response !is null) {
                Log::ResponseToFile(funcName, response);

                if (response.GetType() == Json::Type::Object) {
                    return response;
                }
            }

            Log::Error("bad response");
            return null;
        }

        void StartRequestAsync(Net::HttpRequest@ req) {
            WaitAsync();
            req.Start();
            while (!req.Finished()) {
                yield();
            }
        }

        void WaitAsync() {
            const uint64 now = Time::Now;
            if (now - lastRequest < waitTime) {
                sleep(lastRequest + waitTime - now);
            }
            lastRequest = Time::Now;
        }
    }

    namespace Tmio {
        void GetActivePlayersAsync() {
            const string funcName = "Http::Tmio::GetActivePlayersAsync";

            Net::HttpRequest@ req = Net::HttpGet("https://trackmania.io/api/player/" + GetApp().LocalPlayerInfo.WebServicesUserId);
            while (!req.Finished()) {
                yield();
            }

            try {
                Json::Value@ response = req.Json();
                Log::ResponseToFile(funcName, response);

                Json::Value@ mm = response["matchmaking"];
                for (uint i = 0; i < mm.Length; i++) {
                    if (string(mm[i]["info"]["typename"]) == "2v2") {
                        State::activePlayers = uint(mm[i]["totalactive"]);
                        Log::Info(funcName, "active players: " + State::activePlayers);
                        return;
                    }
                }

                Log::Warning(funcName, "didn't find active players");

            } catch {
                Log::Error(getExceptionInfo());
            }
        }
    }
}
