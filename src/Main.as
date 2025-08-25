// c 2025-07-02
// m 2025-08-25

const string  pluginIcon = Icons::Gamepad;
Meta::Plugin@ pluginMeta = Meta::ExecutingPlugin();

string get_pluginColor() {
    return State::me.division.colorStr;
}

string get_pluginTitle() {
    return pluginColor + pluginIcon + "\\$G " + pluginMeta.Name;
}

Audio::Sample@ sound;

void Main() {
    @sound = Audio::LoadSample("assets/MatchFound.wav");

    Http::Nadeo::InitAsync();

    Partner::LoadRecent();

    if (!GetDivisionsAsync()) {
        Log::Error("failed to get divisions");
        return;
    }

    GetMyStatusAsync();
    Http::Tmio::GetActivePlayersAsync();
}

void OnDestroyed() {
    OnDisabled();
}

void OnDisabled() {
    switch (State::status) {
        case SimpleRanked::Status::Queueing:
        case SimpleRanked::Status::WaitingForPartner:
        case SimpleRanked::Status::Queued:
            Log::Warning("OnDisabled", "canceling queue");

            NadeoServices::Post(
                Http::Nadeo::audienceLive,
                NadeoServices::BaseURLMeet() + "/api/matchmaking/ranked-2v2/cancel"
            ).Start();  // Openplanet throws a warning but it's fine
    }
}

void OnSettingsChanged() {
    const uint recent = S_RecentRemember;
    S_RecentRemember = Math::Clamp(S_RecentRemember, 0, 1000);
    if (S_RecentRemember != recent) {
        while (Partner::recent.Length >= S_RecentRemember) {
            Partner::recent.RemoveAt(0);
        }
    }

    S_Volume = Math::Clamp(S_Volume, 0.0f, 100.0f);
}

void Render() {
    if (false
        or !S_Enabled
        or (true
            and S_HideWithGame
            and !UI::IsGameUIVisible()
        )
        or (true
            and S_HideWithOP
            and !UI::IsOverlayShown()
        )
    ) {
        return;
    }

    UI::SetNextWindowSize(300, 300, UI::Cond::FirstUseEver);

    if (UI::Begin(
        pluginTitle + "\\$666 v" + pluginMeta.Version + "###main-" + pluginMeta.ID,
        S_Enabled,
        UI::WindowFlags::MenuBar
    )) {
        RenderStatusBar();
        RenderMainTabs();
    }
    UI::End();
}

void RenderMenu() {
    if (UI::MenuItem(pluginTitle, "", S_Enabled)) {
        S_Enabled = !S_Enabled;
    }
}

void RenderMenuMain() {
    if (!S_MenuMain) {
        return;
    }

    string title = pluginColor + pluginIcon + "\\$G Ranked";
    switch (State::status) {
        case SimpleRanked::Status::NotQueued:
            break;

        case SimpleRanked::Status::WaitingForPartner:
            title += "\\$6C6 (waiting for partner)";
            break;

        case SimpleRanked::Status::Queueing:
        case SimpleRanked::Status::Queued:
            title += "\\$6C6 (queued for " + Time::Format((Time::Stamp - State::queueStart) * 1000, false) + ")";
            break;

        case SimpleRanked::Status::MatchFound:
        case SimpleRanked::Status::Joining:
            title += "\\$6CC (match found)";
            break;

        case SimpleRanked::Status::InMatch:
            title += "\\$6CC (in match)";
            break;

        case SimpleRanked::Status::MatchEnd:
            title += "\\$66C (match end)";
            break;

        case SimpleRanked::Status::Banned:
            title += "\\$C66 (banned)";
            break;
    }

    if (Partner::exists) {
        title += "\\$888 (with " + Partner::partner.name + ")";
    }

    if (UI::BeginMenu(title + "###menumain-" + pluginMeta.ID)) {
        if (S_RankColor) {
            UI::PushStyleColor(UI::Col::Button,        State::me.division.color);
            UI::PushStyleColor(UI::Col::ButtonHovered, State::me.division.color * 1.2f);
            UI::PushStyleColor(UI::Col::ButtonActive,  State::me.division.color * 0.8f);
        }

        RenderRankedContents();

        if (S_RankColor) {
            UI::PopStyleColor(3);
        }

        UI::EndMenu();
    }
}
