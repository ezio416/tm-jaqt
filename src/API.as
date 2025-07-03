// c 2025-07-02
// m 2025-07-02

namespace API {
    namespace Nadeo {
        const string audienceLive  = "NadeoLiveServices";
        uint64       lastHeartbeat = 0;
        uint64       lastRequest   = 0;
        const uint64 waitTime      = 500;

        Json::Value@ GetDivisionDisplayRulesAsync() {
            Json::Value@ response = GetMeetAsync("matchmaking/ranked-2v2/division/display-rules");

            if (true
                and response !is null
                and response.GetType() == Json::Type::Object
            ) {
                return response;
            }

            warn("GetDivisionDisplayRulesAsync | bad response: " + Json::Write(response));
            return null;
        }

        Json::Value@ GetLeaderboardPlayersAsync(const string[]@ accountIDs) {
            Json::Value@ response = GetMeetAsync("matchmaking/ranked-2v2/leaderboard/players?players[]=" + string::Join(accountIDs, "&players[]="));

            if (true
                and response !is null
                and response.GetType() == Json::Type::Object
            ) {
                return response;
            }

            warn("GetLeaderboardPlayersAsync | bad response: " + Json::Write(response));
            return null;
        }

        Json::Value@ GetMatchInfoAsync() {
            if (matchID.Length == 0) {
                warn("GetMatchInfoAsync | no match ID");
                return null;
            }

            Json::Value@ response = GetMeetAsync("matches/" + matchID);

            if (true
                and response !is null
                and response.GetType() == Json::Type::Object
            ) {
                return response;
            }

            warn("GetMatchInfoAsync | bad response: " + Json::Write(response));
            return null;
        }

        Json::Value@ GetMeetAsync(const string&in endpoint) {
            Net::HttpRequest@ req = NadeoServices::Get(
                audienceLive,
                NadeoServices::BaseURLMeet() + "/api/" + endpoint
            );
            StartRequestAsync(req);

            try {
                return req.Json();
            } catch {
                error("API::Nadeo::GetMeetAsync | " + endpoint + " | " + getExceptionInfo());
                return null;
            }
        }

        Json::Value@ GetPlayerStatusAsync() {
            Json::Value@ response = GetMeetAsync("matchmaking/ranked-2v2/player-status");

            if (true
                and response !is null
                and response.GetType() == Json::Type::Object
            ) {
                return response;
            }

            warn("GetPlayerStatusAsync | bad response: " + Json::Write(response));
            return null;
        }

        void InitAsync() {
            NadeoServices::AddAudience(audienceLive);
            while (!NadeoServices::IsAuthenticated(audienceLive)) {
                yield();
            }
        }

        Json::Value@ PostMeetAsync(const string&in endpoint, const string&in body = "") {
            Net::HttpRequest@ req = NadeoServices::Post(
                audienceLive,
                NadeoServices::BaseURLMeet() + "/api/" + endpoint,
                body
            );
            StartRequestAsync(req);

            try {
                return req.Json();
            } catch {
                error("API::Nadeo::PostMeetAsync | " + endpoint + " | " + getExceptionInfo());
                return null;
            }
        }

        Json::Value@ SendHeartbeatAsync() {
            Json::Value@ response = PostMeetAsync("matchmaking/ranked-2v2/heartbeat", '{"code":"","playWith":[]}');
            lastHeartbeat = Time::Now;

            if (true
                and response !is null
                and response.GetType() == Json::Type::Object
            ) {
                return response;
            }

            warn("SendHeartbeatAsync | bad response: " + Json::Write(response));
            return null;
        }

        void SendQueueCancelAsync() {
            cancel = true;
            warn("cancelling queue");
            PostMeetAsync("matchmaking/ranked-2v2/cancel");
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
