// c 2025-07-03
// m 2025-07-03

namespace Log {
    enum Level {
        Critical,
        Error,
        Warning,
        Info,
        Debug
    }

    void Critical(const string&in func, const string&in msg) {
        Write(Level::Critical, func, msg);
    }

    void Debug(const string&in func, const string&in msg) {
        Write(Level::Debug, func, msg);
    }

    void Error(const string&in func, const string&in msg) {
        Write(Level::Error, func, msg);
    }

    void Info(const string&in func, const string&in msg) {
        Write(Level::Info, func, msg);
    }

    void ResponseToFile(const string&in func, Json::Value@ response) {
        ToFile(func + ".json", Json::Write(response, true));
    }

    void ToFile(const string&in filename, const string&in msg) {
        IO::File file(IO::FromStorageFolder(Path::SanitizeFileName(filename)), IO::FileMode::Write);
        file.Write(msg);
        file.Close();
    }

    void Warning(const string&in func, const string&in msg) {
        Write(Level::Warning, func, msg);
    }

    void Write(const Level level, const string&in func, const string&in msg) {
        if (level > S_LogLevel) {
            return;
        }

        const string message = func + " | " + msg;

        switch (level) {
            case Level::Critical:
                error(Icons::ExclamationTriangle + " " + message);
                break;

            case Level::Error:
                error(message);
                break;

            case Level::Warning:
                warn(message);
                break;

            case Level::Info:
                trace(message);
                break;

            case Level::Debug:
                print(message);
                break;
        }
    }
}
