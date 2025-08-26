// c 2025-08-25
// m 2025-08-25

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
