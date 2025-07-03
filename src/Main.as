// c 2025-07-02
// m 2025-07-03

const string  pluginColor = "\\$FAF";
const string  pluginIcon  = Icons::Gamepad;
Meta::Plugin@ pluginMeta  = Meta::ExecutingPlugin();
const string  pluginTitle = pluginColor + pluginIcon + "\\$G " + pluginMeta.Name;

Division@[] divisions = { Division() };

void OnDestroyed() {
    switch (State::status) {
        case State::Status::Queueing:
        case State::Status::Queued:
            Log::Warning("OnDestroyed", "canceling queue");

            NadeoServices::Post(
                API::Nadeo::audienceLive,
                NadeoServices::BaseURLMeet() + "/api/matchmaking/ranked-2v2/cancel"
            ).Start();  // Openplanet throws a warning but it's fine
    }
}

void OnDisabled() {
    OnDestroyed();
}

void Main() {
    API::Nadeo::InitAsync();

    if (!GetDivisionsAsync()) {
        Log::Critical("Main", "failed to get divisions");
        return;
    }

    GetMyStatusAsync();
}

void Render() {
    if (false
        or !S_Enabled
        or (S_HideWithGame and !UI::IsGameUIVisible())
        or (S_HideWithOP and !UI::IsOverlayShown())
    ) {
        return;
    }

    if (UI::Begin(pluginTitle + "###main-" + pluginMeta.ID, S_Enabled, UI::WindowFlags::None)) {
        for (uint i = 0; i < divisions.Length; i++) {
            divisions[i].RenderIcon(vec2(32.0f), true);
            UI::SameLine();
            UI::AlignTextToFramePadding();
            UI::TextWrapped(tostring(divisions[i]));
        }

        UI::Separator();

        if (State::me !is null) {
            UI::TextWrapped(Json::Write(State::me.ToJson(), true));
        }

        UI::Separator();

        UI::Text("status: " + tostring(State::status));

        UI::BeginDisabled(State::status != State::Status::None);
        if (UI::Button("start queue")) {
            startnew(StartQueueAsync);
        }
        UI::EndDisabled();

        // UI::BeginDisabled(true
        //     and status != QueueStatus::Queueing
        //     and status != QueueStatus::Queued
        // );
        if (UI::Button("cancel")) {
            startnew(CancelQueueAsync);
        }
        // UI::EndDisabled();

        if (UI::Button("get status")) {
            startnew(GetMyStatusAsync);
        }
    }
    UI::End();
}

void RenderMenu() {
    if (UI::MenuItem(pluginTitle, "", S_Enabled)) {
        S_Enabled = !S_Enabled;
    }
}
