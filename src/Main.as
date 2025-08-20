// c 2025-07-02
// m 2025-08-20

const string  pluginColor = "\\$F6F";
const string  pluginIcon  = Icons::Gamepad;
Meta::Plugin@ pluginMeta  = Meta::ExecutingPlugin();
const string  pluginTitle = pluginColor + pluginIcon + "\\$G " + pluginMeta.Name;

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

    if (UI::Begin(pluginTitle + "###main-" + pluginMeta.ID, S_Enabled, UI::WindowFlags::MenuBar)) {
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

void PlaySound() {
    if (sound !is null) {
        Audio::Play(sound, S_Volume / 100.0f);
    }
}
