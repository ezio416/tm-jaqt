// c 2025-07-02
// m 2025-07-02

namespace API {
    namespace Nadeo {
        const string audienceLive = "NadeoLiveServices";

        Json::Value@ GetMeetAsync(const string&in endpoint) {
            Net::HttpRequest@ req = NadeoServices::Get(
                audienceLive,
                NadeoServices::BaseURLMeet() + "/api/" + endpoint
            );
            req.Start();
            while (!req.Finished()) {
                yield();
            }

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
            req.Start();
            while (!req.Finished()) {
                yield();
            }

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
    }
}
