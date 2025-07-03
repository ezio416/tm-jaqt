// c 2025-07-02
// m 2025-07-02

const string  pluginColor = "\\$FAF";
const string  pluginIcon  = Icons::Gamepad;
Meta::Plugin@ pluginMeta  = Meta::ExecutingPlugin();
const string  pluginTitle = pluginColor + pluginIcon + "\\$G " + pluginMeta.Name;

Division@[] divisions = { Division() };

void Main() {
    API::Nadeo::InitAsync();

    if (!GetDivisionsAsync()) {
        return;
    }

    print(Json::Write(API::Nadeo::GetLeaderboardPlayersAsync({ "594be80b-62f3-4705-932b-e743e97882cf" })));
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
            UI::Text(tostring(divisions[i]));
        }
    }
    UI::End();
}

void RenderMenu() {
    if (UI::MenuItem(pluginTitle, "", S_Enabled)) {
        S_Enabled = !S_Enabled;
    }
}
