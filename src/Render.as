// c 2025-07-03
// m 2025-08-20

void RenderMainTabs() {
    UI::BeginTabBar("##tabbar-main");

    RenderTabRanked();
    RenderTabSettings();

    if (S_Debug) {
        RenderTabDebug();
    }

    UI::EndTabBar();
}

void RenderStatusBar() {
    if (UI::BeginMenuBar()) {
        string statusString = "\\$AAA" + tostring(State::status);

        switch (State::status) {
            case State::Status::Queueing:
            case State::Status::Queued:
                statusString += "  " + Time::Format(Time::Now - State::queueStart, false);
        }

        UI::Text(statusString);
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
            if (State::me !is null) {
                UI::TextWrapped(Json::Write(State::me.ToJson(), true));
            }
        }

        UI::EndChild();
        UI::EndTabItem();
    }

    if (UI::BeginTabItem(Icons::Users + " Players")) {
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
            UI::Text("map name: " + State::mapName);
            UI::Text("map thumbnail URL: " + State::mapThumbnailUrl);
            UI::Text("queueStart: " + State::queueStart);
            UI::Text("status: " + tostring(State::status));
        }

        UI::EndChild();
        UI::EndTabItem();
    }

    UI::EndTabBar();
    UI::EndTabItem();
}

void RenderTabRanked() {
    if (!UI::BeginTabItem(Icons::Trophy + " Ranked")) {
        return;
    }

    if (!UI::BeginChild("##child-ranked")) {
        UI::EndChild();
        return;
    }

    const float scale = UI::GetScale();

    if (State::mapThumbnail !is null) {
        const vec2 pre = UI::GetCursorPos();
        UI::ImageWithBg(State::mapThumbnail, UI::GetContentRegionAvail(), tint_col: vec4(vec3(1.0f), 0.05f));
        UI::SetCursorPos(pre);
    }

    if (State::me !is null) {
        State::me.division.RenderIcon(vec2(scale * 48.0f), true);

        UI::SameLine();
        UI::AlignTextToFramePadding();
        UI::BeginGroup();
        UI::Text("Points: " + State::me.progression);
        string rank = "Rank: " + State::me.rank;
        if (State::activePlayers > 0) {
            rank += " / " + State::activePlayers + Text::Format(" (top %.1f%%)", float(State::me.rank) / State::activePlayers * 100.0f);
        }
        UI::Text(rank);
        UI::EndGroup();
    }

    UI::BeginDisabled(State::status != State::Status::NotQueued);
    if (UI::Button(Icons::Play + " Queue")) {
        startnew(StartQueueAsync);
    }
    UI::EndDisabled();

    UI::SameLine();
    UI::BeginDisabled(false
        or State::cancel
        or (true
            and State::status != State::Status::Queueing
            and State::status != State::Status::Queued
        )
    );
    if (UI::Button(Icons::Times + " Cancel")) {
        startnew(CancelQueueAsync);
    }
    UI::EndDisabled();

    if (State::mapName.Length > 0) {
        UI::Text(State::mapName);
    }

    if (State::status == State::Status::InMatch) {
        Player@ player;

        UI::SeparatorText("Blue");
        for (uint i = 0; i < State::playersArr.Length; i++) {
            @player = State::playersArr[i];
            if (player.team == 1) {
                player.division.RenderIcon(scale * 24.0f, true);
                UI::SameLine();
                UI::AlignTextToFramePadding();
                UI::Text(player.name + " | " + player.score);
            }
        }

        UI::SeparatorText("Red");
        for (uint i = 0; i < State::playersArr.Length; i++) {
            @player = State::playersArr[i];
            if (player.team == 2) {
                player.division.RenderIcon(scale * 24.0f, true);
                UI::SameLine();
                UI::AlignTextToFramePadding();
                UI::Text(player.name + " | " + player.score);
            }
        }
    }

    UI::EndChild();
    UI::EndTabItem();
}

void RenderTabSettings() {
    if (!UI::BeginTabItem(Icons::Cogs + " Settings")) {
        return;
    }

    if (UI::BeginChild("##child-settings")) {
        ;
    }

    UI::EndChild();
    UI::EndTabItem();
}
