using System;
using System.IO;

namespace FoxServer {
    public class LogWriter {
        public string logFile;
        public void Log(LogType tnType, string tcMessage) {
            try {
                string lcType = "";
                switch (tnType) {
                    case LogType.ERROR:
                        lcType = "ERROR  ";
                        break;
                    case LogType.INFORMATION:
                        lcType = "INFO   ";
                        break;
                    case LogType.WARNING:
                        lcType = "WARNING";
                        break;
                }

                string logText = $"{DateTime.Now:dd-MM-yyyy HH:mm:ss} | {lcType} | {tcMessage}"+ Environment.NewLine;
                if (!File.Exists(logFile)) {
                    File.Create(logFile).Close();
                }
                File.AppendAllText(logFile, logText);
            } catch {
            }
        }
    }
    public enum LogType {
        ERROR = 0,
        INFORMATION = 1,
        WARNING = 2
    }
}
