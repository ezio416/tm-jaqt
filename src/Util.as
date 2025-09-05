// c 2025-08-25
// m 2025-09-04

Audio::Sample@ sound;
const string   uuidChars  = "0123456789abcdef";
const uint8[]  uuidDashes = { 2, 3, 4, 5 };

string GenerateUUID() {
    string uuid;
    string char = " ";

    for (uint8 i = 0; i < 8; i++) {
        if (uuidDashes.Find(i) > -1) {
            uuid += "-";
        }

        for (uint8 j = 0; j < 4; j++) {
            char[0] = uuidChars[Math::Rand(0, 16)];
            uuid += char;
        }
    }

    return uuid;
}

void PlaySound() {
    if (sound !is null) {
        Audio::Play(sound, S_Volume / 100.0f);
    }
}

string FormatSeconds(int64 seconds, const bool day = false, const bool hour = false, const bool minute = false) {
    int minutes = seconds / 60;
    seconds %= 60;
    int hours = minutes / 60;
    minutes %= 60;
    int days = hours / 24;
    hours %= 24;

    if (days > 0)
        return days + "d " + hours + "h " + minutes + "m " + seconds + "s";
    if (hours > 0)
        return (day ? "0d " : "") + hours + "h " + minutes + "m " + seconds + "s";
    if (minutes > 0)
        return (day ? "0d " : "") + (hour ? "0h " : "") + minutes + "m " + seconds + "s";
    return (day ? "0d " : "") + (hour ? "0h " : "") + (minute ? "0m " : "") + seconds + "s";
}
