// c 2025-07-03
// m 2025-08-21

[Setting category="General" name="Show window"]
bool S_Enabled = true;

[Setting category="General" name="Show/hide with game UI"]
bool S_HideWithGame = true;

[Setting category="General" name="Show/hide with Openplanet UI"]
bool S_HideWithOP = false;

[Setting category="General" name="Use current rank for UI color"]
bool S_RankColor = true;

[Setting category="General" name="Show item in top menu"]
bool S_MenuMain = true;

[Setting category="General" name="Notification volume" min=0.0f max=100.0f afterrender="RenderSoundTestButton"]
float S_Volume = 50.0f;

[Setting category="General" name="Log level"]
Log::Level S_LogLevel = Log::Level::Info;

[Setting category="General" name="Show debug tab"]
bool S_Debug = false;
