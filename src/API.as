// c 2025-07-02
// m 2025-07-02

namespace API {
    namespace Nadeo {
        const string audienceLive = "NadeoLiveServices";
        uint64       lastRequest  = 0;
        const uint64 waitTime     = 500;

        Json::Value@ GetDivisionDisplayRulesAsync() {
            return GetMeetAsync("matchmaking/ranked-2v2/division/display-rules");
        }

        Json::Value@ GetLeaderboardPlayersAsync(const string[]@ accountIDs) {
            return GetMeetAsync("matchmaking/ranked-2v2/leaderboard/players?players[]=" + string::Join(accountIDs, "&players[]="));
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

        Json::Value@ PostMeetAsync(const string&in endpoint, Json::Value@ body = null) {
            return PostMeetAsync(endpoint, Json::Write(body));
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
