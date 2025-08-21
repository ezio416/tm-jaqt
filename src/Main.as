// c 2025-07-02
// m 2025-08-20

const string  pluginIcon = Icons::Gamepad;
Meta::Plugin@ pluginMeta = Meta::ExecutingPlugin();

string get_pluginColor() {
    return State::me !is null ? Text::FormatOpenplanetColor(State::me.division.color.xyz) : "\\$641";
}

string get_pluginTitle() {
    return pluginColor + pluginIcon + "\\$G " + pluginMeta.Name;
}

Division@[]    divisions = { Division() };
Audio::Sample@ sound;

void Main() {
    @sound = Audio::LoadSample("assets/MatchFound.wav");

    Http::Nadeo::InitAsync();

    if (!GetDivisionsAsync()) {
        Log::Critical("Main", "failed to get divisions");
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
        case State::Status::Queueing:
        case State::Status::Queued:
            Log::Warning("OnDisabled", "canceling queue");

            NadeoServices::Post(
                Http::Nadeo::audienceLive,
                NadeoServices::BaseURLMeet() + "/api/matchmaking/ranked-2v2/cancel"
            ).Start();  // Openplanet throws a warning but it's fine
    }
}

void OnSettingsChanged() {
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

    const bool colorUI = true
        and S_RankColor
        and State::me !is null
    ;

    const vec4 color = colorUI ? State::me.division.color : vec4(1.0f);

    if (UI::Begin(pluginTitle + "###main-" + pluginMeta.ID, S_Enabled, UI::WindowFlags::MenuBar)) {
        if (colorUI) {
            UI::PushStyleColor(UI::Col::FrameBgHovered,   color * 1.2f);
            UI::PushStyleColor(UI::Col::FrameBgActive,    color * 0.8f);
            UI::PushStyleColor(UI::Col::CheckMark,        color);
            UI::PushStyleColor(UI::Col::SliderGrab,       color);
            UI::PushStyleColor(UI::Col::SliderGrabActive, color * 0.8f);
            UI::PushStyleColor(UI::Col::Button,           color);
            UI::PushStyleColor(UI::Col::ButtonHovered,    color * 1.2f);
            UI::PushStyleColor(UI::Col::ButtonActive,     color * 0.8f);
            UI::PushStyleColor(UI::Col::Tab,              color * 0.8f);
            UI::PushStyleColor(UI::Col::TabHovered,       color * 1.2f);
            UI::PushStyleColor(UI::Col::TabActive,        color);
        }

        RenderStatusBar();
        RenderMainTabs();

        if (colorUI) {
            UI::PopStyleColor(11);
        }
    }
    UI::End();
}

void RenderMenu() {
    if (UI::MenuItem(pluginTitle, "", S_Enabled)) {
        S_Enabled = !S_Enabled;
    }
}

void PlaySound() {
    if (sound !is null) {
        Audio::Play(sound, S_Volume / 100.0f);
    }
}
