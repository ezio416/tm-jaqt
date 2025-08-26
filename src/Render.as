// c 2025-07-03
// m 2025-08-25

const vec4 rowBgColor = vec4(vec3(), 0.5f);

FakePlayer@ devPlayer;

void RenderMainTabs() {
    UI::BeginTabBar("##tabbar-main");

    const bool color = S_RankColor;  // set here as it can change between its references below

    if (color) {
        const vec4 active = State::me.division.color * 0.8f;
        const vec4 hovered = State::me.division.color * 1.1f;

        UI::PushStyleColor(UI::Col::FrameBgActive,    active);
        UI::PushStyleColor(UI::Col::CheckMark,        State::me.division.color);
        UI::PushStyleColor(UI::Col::SliderGrab,       State::me.division.color);
        UI::PushStyleColor(UI::Col::SliderGrabActive, active);
        UI::PushStyleColor(UI::Col::Button,           State::me.division.color);
        UI::PushStyleColor(UI::Col::ButtonHovered,    hovered);
        UI::PushStyleColor(UI::Col::ButtonActive,     active);
        UI::PushStyleColor(UI::Col::Tab,              active);
        UI::PushStyleColor(UI::Col::TabHovered,       hovered);
        UI::PushStyleColor(UI::Col::TabActive,        State::me.division.color);
    }

    RenderTabRanked();
    RenderTabParty();
    RenderTabSettings();

    if (S_Debug) {
        RenderTabDebug();
    }

#if SIG_DEVELOPER
    RenderTabDev();
#endif

    if (color) {
        UI::PopStyleColor(10);
    }

    UI::EndTabBar();
}

void RenderRankedContents() {
    const float scale = UI::GetScale();

    if (State::mapThumbnail !is null) {
        const vec2 pre = UI::GetCursorPos();
        UI::ImageWithBg(State::mapThumbnail, UI::GetContentRegionAvail(), tint_col: vec4(vec3(1.0f), 0.05f));
        UI::SetCursorPos(pre);
    }

    State::me.division.RenderIcon(vec2(scale * 64.0f), true);

    UI::SameLine();
    UI::AlignTextToFramePadding();
    UI::BeginGroup();

    UI::Text("Points: " + State::me.progression);

    string rank = "Rank: " + State::me.rank;
    if (State::activePlayers > 0) {
        rank += " / " + State::activePlayers + Text::Format(" (top %.1f%%)", float(State::me.rank) / State::activePlayers * 100.0f);
    }
    UI::Text(rank);

    if (State::me.hasPenalty) {
        UI::Text("Immunity: " + State::me.immunityDays + " days (" + State::me.penalty + " pts)");

        UI::SameLine();
        UI::Text(Icons::InfoCircle);
        UI::SetItemTooltip("After not playing for this many days, you will lose this many points each day thereafter.");
    }

    UI::EndGroup();

    const vec2 buttonSize = vec2(UI::GetContentRegionAvail().x, scale * 50.0f);

    UI::PushFont(UI::Font::DefaultBold, 24.0f);

    switch (State::status) {
        case JAQT::Status::NotQueued:
        case JAQT::Status::MatchEnd:
            if (UI::Button(
                Icons::Play + " Queue" + (Partner::exists ? " with " + Partner::partner.name : ""),
                buttonSize
            )) {
                startnew(StartQueueAsync);
            }
            break;

        case JAQT::Status::MatchFound:
        case JAQT::Status::Joining:
            UI::BeginDisabled();
            UI::Button(Icons::ClockO + " Joining Match", buttonSize);
            UI::EndDisabled();
            break;

        case JAQT::Status::InMatch:
            UI::BeginDisabled();
            UI::Button(Icons::Kenney::SignIn + " In Match", buttonSize );
            UI::EndDisabled();
            break;

        case JAQT::Status::Banned:
            UI::BeginDisabled();
            UI::Button(Icons::Ban + " Banned", buttonSize);
            UI::EndDisabled();
            break;

        default:
            UI::BeginDisabled(false
                or State::cancel
                or (true
                    and State::status != JAQT::Status::Queueing
                    and State::status != JAQT::Status::WaitingForPartner
                    and State::status != JAQT::Status::Queued
                )
            );
            if (UI::ButtonColored(
                Icons::Times + " Cancel",
                0.0f,
                size: buttonSize
            )) {
                startnew(Http::Nadeo::CancelQueueAsync);
            }
            UI::EndDisabled();
    }

    UI::PopFont();

    if (State::mapName.Length > 0) {
        UI::SeparatorText(State::mapName);
    }

    if (false
        or State::status == JAQT::Status::InMatch
        or State::status == JAQT::Status::MatchEnd
    ) {
        if (UI::BeginTable("##table-players", 4, UI::TableFlags::SizingStretchProp)) {
            UI::TableSetupColumn("team",   UI::TableColumnFlags::WidthFixed, scale * 20.0f);
            UI::TableSetupColumn("points", UI::TableColumnFlags::WidthFixed, scale * 20.0f);
            UI::TableSetupColumn("rank",   UI::TableColumnFlags::WidthFixed, scale * 30.0f);
            UI::TableSetupColumn("name");

            for (uint i = 0; i < State::playersArr.Length; i++) {
                if (State::playersArr[i].team == 1) {
                    RenderPlayerRow(State::playersArr[i]);
                }
            }

            for (uint i = 0; i < State::playersArr.Length; i++) {
                if (State::playersArr[i].team == 2) {
                    RenderPlayerRow(State::playersArr[i]);
                }
            }

            UI::EndTable();
        }
    }
}

void RenderPlayerAddButton(Player@ player, const int i) {
    if (true
        and Partner::partner !is null
        and Partner::partner.accountId == player.accountId
    ) {
        if (UI::ButtonColored(Icons::UserTimes + "##" + i, 0.0f)) {
            Partner::Remove();
        }
        UI::SetItemTooltip("Remove player as partner");

    } else if (player.canPartner) {
        if (UI::ButtonColored(Icons::UserPlus + "##" + i, 0.3f)) {
            Partner::Add(player);
        }
        UI::SetItemTooltip("Add player as partner");

    } else {
        UI::PushStyleColor(UI::Col::Button, vec4(vec3(0.5f), 1.0f));
        UI::BeginDisabled();
        UI::Button(Icons::UserPlus + "##" + i);
        UI::EndDisabled();
        if (UI::IsItemHovered(UI::HoveredFlags::AllowWhenDisabled)) {
            UI::SetTooltip("You're too far apart!");
        }
        UI::PopStyleColor();
    }
}

void RenderPlayerRow(Player@ player) {
    UI::TableNextRow();

    UI::TableNextColumn();
    UI::AlignTextToFramePadding();
    switch (player.team) {
        case 1:  // blue
            UI::Text("\\$66F" + Icons::Circle);
            break;

        case 2:  // red
            UI::Text("\\$F66" + Icons::Circle);
            break;

        default:
            UI::Text("\\$666" + Icons::Circle);
    }

    UI::TableNextColumn();
    UI::AlignTextToFramePadding();
    UI::Text(tostring(player.score));

    UI::TableNextColumn();
    player.division.RenderIcon(UI::GetScale() * 24.0f, true);

    UI::TableNextColumn();
    UI::AlignTextToFramePadding();
    UI::Text(player.name);
}

void RenderSoundTestButton() {
    if (UI::Button(Icons::Play + " Test sound")) {
        PlaySound();
    }
}

void RenderStatusBar() {
    if (UI::BeginMenuBar()) {
        string text = "\\$AAA ";

        switch (State::status) {
            case JAQT::Status::NotQueued:
                text += "Not in Queue";
                break;

            case JAQT::Status::WaitingForPartner:
                text += "Waiting for Partner";
                break;

            case JAQT::Status::MatchFound:
                text += "Match Found";
                break;

            case JAQT::Status::InMatch:
                text += "In Match";
                break;

            case JAQT::Status::MatchEnd:
                text += "End of Match";
                break;

            default:
                text += tostring(State::status);
        }

        switch (State::status) {
            case JAQT::Status::Queueing:
            case JAQT::Status::WaitingForPartner:
            case JAQT::Status::Queued:
                text += "  " + Time::Format((Time::Stamp - State::queueStart) * 1000, false);
        }

        UI::Text(text);
        UI::EndMenuBar();
    }
}

void RenderTabDebug() {
    if (!UI::BeginTabItem(Icons::Bug + " Debug")) {
        return;
    }

    UI::BeginTabBar("##tabs-debug");

    if (UI::BeginTabItem(Icons::User + " Me")) {
        if (UI::BeginChild("##child-debug-me")) {
            UI::TextWrapped(Json::Write(State::me.ToJson(), true));
        }

        UI::EndChild();
        UI::EndTabItem();
    }

    if (UI::BeginTabItem(Icons::Users + " Match Players")) {
        if (UI::BeginChild("##child-debug-players")) {
            for (uint i = 0; i < State::playersArr.Length; i++) {
                if (i > 0) {
                    UI::Separator();
                }

                // UI::TextWrapped(Json::Write(State::playersArr[i].ToJson(), true));
                UI::Text("name: "        + State::playersArr[i].name);
                UI::Text("progression: " + State::playersArr[i].progression);
                UI::Text("div name: "    + State::playersArr[i].division.name);
                UI::Text("team: "        + State::playersArr[i].team);
                UI::Text("score: "       + State::playersArr[i].score);
            }
        }

        UI::EndChild();
        UI::EndTabItem();
    }

    if (UI::BeginTabItem(Icons::ListUl + " Divisions")) {
        if (UI::BeginChild("##child-debug-divs")) {
            for (uint i = 0; i < divisions.Length; i++) {
                divisions[i].RenderIcon(vec2(32.0f), true);
                UI::SameLine();
                UI::AlignTextToFramePadding();
                UI::TextWrapped(tostring(divisions[i]));
            }
        }

        UI::EndChild();
        UI::EndTabItem();
    }

    if (UI::BeginTabItem(Icons::QuestionCircle + " Other")) {
        if (UI::BeginChild("##child-debug-other")) {
            UI::Text("active players: " + State::activePlayers);
            UI::Text("cancel: " + State::cancel);
            UI::Text("frozen: " + State::frozen);
            UI::Text("map name: " + State::mapName);
            UI::Text("map thumbnail URL: " + State::mapThumbnailUrl);
            UI::Text("queueStart: " + State::queueStart);
            UI::Text("status: " + tostring(State::status));
            UI::TextWrapped("partner: " + (Partner::exists ? Json::Write(Partner::partner.ToJson(), true) : ""));

            if (UI::TreeNode("friends", UI::TreeNodeFlags::Framed)) {
                for (uint i = 0; i < Partner::friends.Length; i++) {
                    UI::TextWrapped(Json::Write(Partner::friends[i].ToJson(), true));
                }
                UI::TreePop();
            }

            if (UI::TreeNode("recent", UI::TreeNodeFlags::Framed)) {
                for (uint i = 0; i < Partner::recent.Length; i++) {
                    UI::TextWrapped(Json::Write(Partner::recent[i].ToJson(), true));
                }
                UI::TreePop();
            }

            if (UI::TreeNode("search", UI::TreeNodeFlags::Framed)) {
                for (uint i = 0; i < Partner::search.Length; i++) {
                    UI::TextWrapped(Json::Write(Partner::search[i].ToJson(), true));
                }
                UI::TreePop();
            }
        }

        UI::EndChild();
        UI::EndTabItem();
    }

    UI::EndTabBar();
    UI::EndTabItem();
}

void RenderTabDev() {
    if (!UI::BeginTabItem(Icons::Code + " Dev")) {
        return;
    }

    if (!UI::BeginChild("##child-dev")) {
        UI::EndChild();
        UI::EndTabItem();
        return;
    }

    UI::PushFont(UI::Font::DefaultBold, 26.0f);
    UI::TextWrapped(
        "Since you're in developer mode, I assume you know what you're doing!"
        " Don't complain if you break stuff in here!"
    );
    UI::PopFont();

    if (UI::TreeNode("Me", UI::TreeNodeFlags::Framed)) {
        if (UI::Button("Get My Status")) {
            startnew(GetMyStatusAsync);
        }

        State::me.progression = Math::Clamp(
            UI::InputInt("Progression", State::me.progression),
            0,
            10000
        );

        State::me.rank = Math::Clamp(
            UI::InputInt("Rank", State::me.rank),
            0,
            1000000
        );

        State::me.hasPenalty = UI::Checkbox("Penalty", State::me.hasPenalty);

        UI::TreePop();
    }

    if (UI::TreeNode("Match Players", UI::TreeNodeFlags::Framed)) {
        if (UI::Button("New")) {
            @devPlayer = FakePlayer();
        }

        if (devPlayer !is null) {
            UI::SameLine();
            if (UI::Button("Randomize")) {
                const uint nameLength = Math::Rand(4, 20);
                const string nameChars = "-012345679ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz";
                string char = " ";
                devPlayer.name = "";
                for (uint8 i = 0; i < nameLength; i++) {
                    char[0] = nameChars[Math::Rand(0, 63)];
                    devPlayer.name += char;
                }

                devPlayer.progression = Math::Rand(0, 6969);
                devPlayer.rank = Math::Rand(1, 200000);
                devPlayer.score = Math::Rand(0, 50);
                devPlayer.team = Math::Rand(1, 3);
            }

            UI::SameLine();
            if (UI::Button("Add")) {
                State::players.Set(devPlayer.accountId, @devPlayer);
                State::playersArr.InsertLast(devPlayer);
                @devPlayer = null;
            } else {
                devPlayer.name        = UI::InputText("name", devPlayer.name);
                devPlayer.progression = UI::InputInt("progression", devPlayer.progression);
                devPlayer.rank        = UI::InputInt("rank", devPlayer.rank);
                devPlayer.score       = UI::InputInt("score", devPlayer.score);
                devPlayer.team        = UI::InputInt("team", devPlayer.team);
            }
        }

        if (State::playersArr.Length > 0) {
            UI::SeparatorText("Existing");

            if (UI::Button("Clear")) {
                State::players.DeleteAll();
                State::playersArr = {};
            }

            UI::SameLine();
            if (UI::Button("Sort")) {
                State::playersArr.SortNonConst(SortPlayersAsc);
            }
        }

        for (uint i = 0; i < State::playersArr.Length; i++) {
            Player@ player = State::playersArr[i];

            UI::Separator();

            if (UI::Button("Remove##" + i)) {
                State::playersArr.RemoveAt(i);
                State::players.Delete(player.accountId);
                break;
            }

            player.name        = UI::InputText("name##" + i, player.name);
            player.progression = UI::InputInt("progression##" + i, player.progression);
            player.rank        = UI::InputInt("rank##" + i, player.rank);

            FakePlayer@ fake = cast<FakePlayer>(player);
            if (fake !is null) {
                fake.score = UI::InputInt("score##" + i, fake.score);
                fake.team  = UI::InputInt("team##" + i, fake.team);
            } else {
                UI::BeginDisabled();
                UI::InputInt("score##" + i, player.score);
                UI::InputInt("team##" + i, player.team);
                UI::EndDisabled();
            }
        }

        UI::TreePop();
    }

    if (UI::TreeNode("Other", UI::TreeNodeFlags::Framed)) {
        if (UI::BeginCombo("Status", tostring(State::status), UI::ComboFlags::HeightLargest)) {
            JAQT::Status status;
            for (uint i = 0; i < JAQT::Status::_Count; i++) {
                status = JAQT::Status(i);
                if (UI::Selectable(tostring(status), State::status == status)) {
                    State::status = status;
                }
            }

            UI::EndCombo();
        }

        UI::TreePop();
    }

    UI::EndChild();
    UI::EndTabItem();
}

void RenderTabFriends() {
    if (!UI::BeginTabItem(Icons::Users + " Friends")) {
        return;
    }

    const float scale = UI::GetScale();

    if (!Partner::gotFriends) {
        Partner::gotFriends = true;
        startnew(Partner::GetFriendsAsync);
    }

    UI::BeginDisabled(Partner::gettingFriends);
    if (UI::Button(Icons::Refresh + " Refresh", vec2(UI::GetContentRegionAvail().x, scale * 25.0f))) {
        startnew(Partner::GetFriendsAsync);
    }
    UI::EndDisabled();

    if (UI::BeginTable("##table-friends", 5, UI::TableFlags::RowBg | UI::TableFlags::ScrollY)) {
        UI::PushStyleColor(UI::Col::TableRowBgAlt, rowBgColor);

        UI::TableSetupColumn("button", UI::TableColumnFlags::WidthFixed, scale * 30.0f);
        UI::TableSetupColumn("online", UI::TableColumnFlags::WidthFixed, scale * 15.0f);
        UI::TableSetupColumn("name",   UI::TableColumnFlags::WidthStretch);
        UI::TableSetupColumn("points", UI::TableColumnFlags::WidthFixed, scale * 60.0f);
        UI::TableSetupColumn("rank",   UI::TableColumnFlags::WidthFixed, scale * 30.0f);

        UI::ListClipper clipper(Partner::friends.Length);
        while (clipper.Step()) {
            for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
                Player@ player = Partner::friends[i];

                UI::TableNextRow();

                UI::TableNextColumn();
                RenderPlayerAddButton(player, i);

                UI::TableNextColumn();
                UI::AlignTextToFramePadding();
                switch (player.status) {
                    case FriendStatus::Online:
                        UI::Text("\\$0C0" + Icons::Circle);
                        UI::SetItemTooltip("Online");
                        break;

                    case FriendStatus::Away:
                        UI::Text("\\$CC0" + Icons::Circle);
                        UI::SetItemTooltip("Away");
                        break;

                    case FriendStatus::DoNotDisturb:
                        UI::Text("\\$C00" + Icons::Circle);
                        UI::SetItemTooltip("Do Not Disturb");
                        break;

                    case FriendStatus::Offline:
                        UI::Text("\\$666" + Icons::Circle);
                        UI::SetItemTooltip("Offline");
                        break;
                }

                UI::TableNextColumn();
                UI::AlignTextToFramePadding();
                UI::Text(player.name);

                UI::TableNextColumn();
                UI::AlignTextToFramePadding();
                UI::Text(tostring(player.progression) + " pts");

                UI::TableNextColumn();
                player.division.RenderIcon(scale * 24.0f, true);
            }
        }

        UI::PopStyleColor();
        UI::EndTable();
    }

    UI::EndTabItem();
}

void RenderTabParty() {
    if (!UI::BeginTabItem(Icons::Kenney::Users + " Party")) {
        return;
    }

    UI::AlignTextToFramePadding();
    UI::Text("Partner: ");

    UI::SameLine();

    if (Partner::exists) {
        if (UI::ButtonColored(Icons::UserTimes, 0.0f)) {
            Partner::Remove();
        } else {
            UI::SameLine();
            UI::AlignTextToFramePadding();
            UI::Text(Partner::partner.name + "\\$888 | \\$G" + Partner::partner.progression + " pts\\$888 |");

            UI::SameLine();
            Partner::partner.division.RenderIcon(UI::GetScale() * 24.0f, true);
        }
    } else {
        UI::Text("None");
    }

    UI::Text("Note: You and your partner need to add each other!");

    UI::BeginTabBar("##tabs-partner");

    RenderTabFriends();
    RenderTabRecent();
    RenderTabSearch();

    UI::EndTabBar();

    UI::EndTabItem();
}

void RenderTabRanked() {
    if (!UI::BeginTabItem(Icons::Trophy + " Ranked")) {
        return;
    }

    if (!UI::BeginChild("##child-ranked")) {
        UI::EndChild();
        UI::EndTabItem();
        return;
    }

    RenderRankedContents();

    UI::EndChild();
    UI::EndTabItem();
}

void RenderTabRecent() {
    if (false
        or S_RecentRemember == 0
        or Partner::recent.Length == 0
        or !UI::BeginTabItem(Icons::ClockO + " Recent")
    ) {
        return;
    }

    const float scale = UI::GetScale();

    if (!Partner::gotRecent) {
        Partner::gotRecent = true;
        startnew(Partner::GetRecentInfoAsync);
    }

    UI::BeginDisabled(Partner::gettingRecent);
    if (UI::Button(Icons::Refresh + " Refresh", vec2(UI::GetContentRegionAvail().x, scale * 25.0f))) {
        startnew(Partner::GetRecentInfoAsync);
    }
    UI::EndDisabled();

    if (UI::BeginTable("##table-recent", 5, UI::TableFlags::RowBg | UI::TableFlags::ScrollY)) {
        UI::PushStyleColor(UI::Col::TableRowBgAlt, rowBgColor);

        UI::TableSetupColumn("button", UI::TableColumnFlags::WidthFixed, scale * 30.0f);
        UI::TableSetupColumn("name",   UI::TableColumnFlags::WidthStretch);
        UI::TableSetupColumn("time",   UI::TableColumnFlags::WidthFixed, scale * 80.0f);
        UI::TableSetupColumn("points", UI::TableColumnFlags::WidthFixed, scale * 60.0f);
        UI::TableSetupColumn("rank",   UI::TableColumnFlags::WidthFixed, scale * 30.0f);

        UI::ListClipper clipper(Partner::recent.Length);
        while (clipper.Step()) {
            for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
                Player@ player = Partner::recent[Partner::recent.Length - 1 - i];

                UI::TableNextRow();

                UI::TableNextColumn();
                RenderPlayerAddButton(player, i);

                UI::TableNextColumn();
                UI::AlignTextToFramePadding();
                UI::Text(player.name.Length > 0 ? player.name : player.accountId);

                UI::TableNextColumn();
                UI::AlignTextToFramePadding();
                UI::Text(Time::FormatString(Time::Stamp - player.lastMatch >= 86400 ? "%F" : "%T", player.lastMatch));
                UI::SetItemTooltip(Time::FormatString("%F %T", player.lastMatch) + "\n"
                    + Time::Format((Time::Stamp - player.lastMatch) * 1000, false) + " ago");

                UI::TableNextColumn();
                UI::AlignTextToFramePadding();
                UI::Text(tostring(player.progression) + " pts");

                UI::TableNextColumn();
                player.division.RenderIcon(scale * 24.0f, true);
            }
        }

        UI::PopStyleColor();
        UI::EndTable();
    }

    UI::EndTabItem();
}

void RenderTabSearch() {
    if (!UI::BeginTabItem(Icons::Search + " Search")) {
        return;
    }

    const float scale = UI::GetScale();

    UI::Text("Note: This search only returns 50 results");

    bool changed;
    UI::SetNextItemWidth((UI::GetContentRegionAvail().x - 15.0f) / scale - scale * 25.0f);
    Http::Tmio::playerSearch = UI::InputText(
        "##search",
        Http::Tmio::playerSearch,
        changed,
        UI::InputTextFlags::EnterReturnsTrue
    );

    const bool disabled = false
        or Partner::searching
        or Time::Now - Http::Tmio::lastRequest < Http::Tmio::waitTime
        or Http::Tmio::playerSearch.Length < 4
    ;

    if (disabled) {
        changed = false;
    }

    UI::SameLine();
    UI::BeginDisabled(disabled);
    if (false
        or UI::Button(Icons::Search)
        or changed
    ) {
        startnew(Partner::SearchAsync);
    }
    UI::EndDisabled();

    if (UI::BeginTable("##table-search", 4, UI::TableFlags::RowBg | UI::TableFlags::ScrollY)) {
        UI::PushStyleColor(UI::Col::TableRowBgAlt, rowBgColor);

        UI::TableSetupColumn("button", UI::TableColumnFlags::WidthFixed, scale * 30.0f);
        UI::TableSetupColumn("name",   UI::TableColumnFlags::WidthStretch);
        UI::TableSetupColumn("points", UI::TableColumnFlags::WidthFixed, scale * 60.0f);
        UI::TableSetupColumn("rank",   UI::TableColumnFlags::WidthFixed, scale * 30.0f);

        UI::ListClipper clipper(Partner::search.Length);
        while (clipper.Step()) {
            for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
                Player@ player = Partner::search[i];

                UI::TableNextRow();

                UI::TableNextColumn();
                RenderPlayerAddButton(player, i);

                UI::TableNextColumn();
                UI::AlignTextToFramePadding();
                UI::Text(player.name.Length > 0 ? player.name : player.accountId);

                UI::TableNextColumn();
                UI::AlignTextToFramePadding();
                UI::Text(tostring(player.progression) + " pts");

                UI::TableNextColumn();
                player.division.RenderIcon(scale * 24.0f, true);
            }
        }

        UI::PopStyleColor();
        UI::EndTable();
    }

    UI::EndTabItem();
}

void RenderTabSettings() {
    if (!UI::BeginTabItem(Icons::Cogs + " Settings")) {
        return;
    }

    if (UI::BeginChild("##child-settings")) {
        if (UI::Button("Reset to default")) {
            Meta::PluginSetting@[]@ settings = pluginMeta.GetSettings();
            for (uint i = 0; i < settings.Length; i++) {
                if (settings[i].Category == "General") {
                    settings[i].Reset();
                }
            }
        }

        S_HideWithGame = UI::Checkbox("Show/hide with game UI", S_HideWithGame);
        S_HideWithOP = UI::Checkbox("Show/hide with Openplanet UI", S_HideWithOP);
        S_RankColor = UI::Checkbox("Use current rank for UI color", S_RankColor);
        S_MenuMain = UI::Checkbox("Show item in top menu", S_MenuMain);
        S_RecentRemember = UI::SliderInt("Recent players to remember", S_RecentRemember, 0, 1000, flags: UI::SliderFlags::AlwaysClamp);

        S_Volume = UI::SliderFloat("Notification volume", S_Volume, 0.0f, 100.0f, flags: UI::SliderFlags::AlwaysClamp);
        RenderSoundTestButton();

        if (UI::BeginCombo("Log level", tostring(S_LogLevel), UI::ComboFlags::HeightLargest)) {
            for (uint i = 0; i <= Log::Level::Debug; i++) {
                const Log::Level level = Log::Level(i);
                if (UI::Selectable(tostring(level), S_LogLevel == level)) {
                    S_LogLevel = level;
                }
            }

            UI::EndCombo();
        }

        S_Debug = UI::Checkbox("Show debug tab", S_Debug);
    }

    UI::EndChild();
    UI::EndTabItem();
}
