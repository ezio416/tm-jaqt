// c 2025-07-02
// m 2025-07-03

namespace API {
    namespace Nadeo {
        const string audienceLive  = "NadeoLiveServices";
        uint64       lastHeartbeat = 0;
        uint64       lastRequest   = 0;
        const uint64 waitTime      = 500;

        void CancelQueueAsync() {
            State::cancel = true;
            Log::Info("API::Nadeo::CancelQueueAsync", "canceling queue");
            PostMeetAsync("/matchmaking/ranked-2v2/cancel");
        }

        Json::Value@ GetDivisionDisplayRulesAsync() {
            const string funcName = "API::Nadeo::GetDivisionDisplayRulesAsync";

            const string endpoint = "/matchmaking/ranked-2v2/division/display-rules";
            Json::Value@ response = GetMeetAsync(endpoint);

            Log::Debug(funcName, endpoint + " | " + Json::Write(response));

            if (response !is null) {
                Log::ResponseToFile(funcName, response);

                if (response.GetType() == Json::Type::Object) {
                    return response;
                }
            }

            Log::Error(funcName, "bad response");
            return null;
        }

        Json::Value@ GetLeaderboardPlayersAsync(const string[]@ accountIDs) {
            const string funcName = "API::Nadeo::GetLeaderboardPlayersAsync";

            if (accountIDs.Length == 0) {
                Log::Warning(funcName, "accountIDs empty");
                return null;
            }

            const string endpoint = "/matchmaking/ranked-2v2/leaderboard/players?players[]=" + string::Join(accountIDs, "&players[]=");
            Json::Value@ response = GetMeetAsync(endpoint);

            Log::Debug(funcName, endpoint + " | " + Json::Write(response));

            if (response !is null) {
                Log::ResponseToFile(funcName, response);

                if (response.GetType() == Json::Type::Object) {
                    return response;
                }
            }

            Log::Error(funcName, "bad response");
            return null;
        }

        Json::Value@ GetMatchInfoAsync(const string&in liveId) {
            const string funcName = "API::Nadeo::GetMatchInfoAsync";

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

            Log::Error(funcName, "bad response");
            return null;
        }

        Json::Value@ GetMeetAsync(const string&in endpoint) {
            const string funcName = "API::Nadeo::GetMeetAsync";

            Net::HttpRequest@ req = NadeoServices::Get(
                audienceLive,
                NadeoServices::BaseURLMeet() + "/api/" + (endpoint.StartsWith("/") ? endpoint.SubStr(1) : endpoint)
            );
            StartRequestAsync(req);

            try {
                return req.Json();
            } catch {
                Log::Error(funcName, endpoint + " | " + getExceptionInfo());
                return null;
            }
        }

        Json::Value@ GetPlayerStatusAsync() {
            const string funcName = "API::Nadeo::GetPlayerStatusAsync";

            const string endpoint = "/matchmaking/ranked-2v2/player-status";
            Json::Value@ response = GetMeetAsync(endpoint);

            Log::Debug(funcName, endpoint + " | " + Json::Write(response));

            if (response !is null) {
                Log::ResponseToFile(funcName, response);

                if (response.GetType() == Json::Type::Object) {
                    return response;
                }
            }

            Log::Error(funcName, "bad response");
            return null;
        }

        void InitAsync() {
            NadeoServices::AddAudience(audienceLive);
            while (!NadeoServices::IsAuthenticated(audienceLive)) {
                yield();
            }
        }

        Json::Value@ PostMeetAsync(const string&in endpoint, const string&in body = "") {
            const string funcName = "API::Nadeo::PostMeetAsync";

            Net::HttpRequest@ req = NadeoServices::Post(
                audienceLive,
                NadeoServices::BaseURLMeet() + "/api/" + (endpoint.StartsWith("/") ? endpoint.SubStr(1) : endpoint),
                body
            );
            StartRequestAsync(req);

            try {
                return req.Json();
            } catch {
                Log::Error(funcName, endpoint + " | " + body + " | " + getExceptionInfo());
                return null;
            }
        }

        Json::Value@ SendHeartbeatAsync() {
            const string funcName = "API::Nadeo::SendHeartbeatAsync";
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

            Log::Error(funcName, "bad response");
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
            uint64 now;
            while ((now = Time::Now) - lastRequest < waitTime) {
                yield();
            }
            lastRequest = now;
        }
    }
}
