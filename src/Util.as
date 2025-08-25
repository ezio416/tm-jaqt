// c 2025-08-25
// m 2025-08-25

const string[] uuidChars  = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f" };
const uint8[]  uuidDashes = { 2, 3, 4, 5 };

string GenerateUUID() {
    string uuid;

    for (uint8 i = 0; i < 8; i++) {
        if (uuidDashes.Find(i) > -1) {
            uuid += "-";
        }

        for (uint8 j = 0; j < 4; j++) {
            uuid += uuidChars[Math::Rand(0, 16)];
        }
    }

    return uuid;
}

void PlaySound() {
    if (sound !is null) {
        Audio::Play(sound, S_Volume / 100.0f);
    }
}
