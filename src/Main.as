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

    ;
}

void Render() {
    if (false
        or !S_Enabled
        or (S_HideWithGame and !UI::IsGameUIVisible())
        or (S_HideWithOP and !UI::IsOverlayShown())
    ) {
        return;
    }

    if (UI::Begin(pluginTitle, S_Enabled, UI::WindowFlags::None)) {
        for (uint i = 0; i < divisions.Length; i++) {
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
