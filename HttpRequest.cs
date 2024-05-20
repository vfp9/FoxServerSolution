using System;
using System.Collections.Generic;

namespace FoxServer {
    public class HttpRequest {
        public string HttpMethod { get; set; }
        public Uri Url { get; set; }
        public Dictionary<string, string> Headers { get; set; }
        public Dictionary<string, string> QueryParameters { get; set; }
        public Dictionary<string, string> MultiPart { get; set; }
        public string Body { get; set; }

        public bool IsJSON { get; set; }

        public HttpRequest() {
            Headers = new Dictionary<string, string>();
            QueryParameters = new Dictionary<string, string>();
            MultiPart = new Dictionary<string, string>();
            IsJSON = false;
        }
    }
}
