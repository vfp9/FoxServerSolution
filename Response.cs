using System.Collections.Generic;

namespace FoxServer {
    public class HttpResponse {
        public int StatusCode { get; set; }
        public string StatusMessage { get; set; }
        public string ContentType { get; set; }
        public string FilePath { get; set; }
        public byte[] BinaryData { get; set; }
        public string Content { get; set; }
        public string Location { get; set; }
        public Dictionary<string, string> Headers { get; set; }
        public bool IncludeContentType { get; set; }

        public HttpResponse() {
            StatusCode = 200;
            StatusMessage = "OK";
            ContentType = "text/plain";
            Headers = new Dictionary<string, string>();
            IncludeContentType = true;
        }
    }
}
