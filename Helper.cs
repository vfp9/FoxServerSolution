using System;
using System.Collections.Generic;
using System.IO;
using System.Net.Sockets;
using System.Net;
using System.Text;
using System.Web;
using System.Text.RegularExpressions;
using System.Linq;
using System.Web.UI.WebControls;

namespace FoxServer {
    public static class Helper {
        public static foxserver.Wrapper server;

        public static string publicDirectory;
        private static readonly string patron = @"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$";
        public static string notFoundPage;
        private static readonly LogWriter logger = new LogWriter();

        public static string BuildHttpResponse(HttpResponse httpResponse) {
            StringBuilder responseBuilder = new StringBuilder();
            responseBuilder.AppendLine($"HTTP/1.1 {httpResponse.StatusCode} {httpResponse.StatusMessage}");
            if (httpResponse.IncludeContentType) {
                responseBuilder.AppendLine($"Content-Type: {httpResponse.ContentType}");
            }

            if (!string.IsNullOrEmpty(httpResponse.Content)) {
                responseBuilder.AppendLine($"Content-Length: {Encoding.UTF8.GetByteCount(httpResponse.Content)}");
            }

            if (httpResponse.StatusCode == 201) {
                responseBuilder.AppendLine($"Location: {httpResponse.Location}");
            }

            if (httpResponse.Headers != null) {
                foreach (var header in httpResponse.Headers) {
                    responseBuilder.AppendLine($"{header.Key}: {header.Value}");
                }
            }

            responseBuilder.AppendLine(); // Línea en blanco antes del cuerpo
            responseBuilder.Append(httpResponse.Content);

            return responseBuilder.ToString();
        }

        public static string ParseHTML(string html) {
            string expPattern = @"<vfp:exp>(.*?)<\/vfp:exp>";
            string scriptPattern = @"<vfp:script>([\s\S]*?)<\/vfp:script>";
            html = ProcesarEtiquetas(html, expPattern, true);
            html = ProcesarEtiquetas(html, scriptPattern, false);
            return html;
        }

        private static string ProcesarEtiquetas(string input, string pattern, bool isExp) {
            Regex regex = new Regex(pattern, RegexOptions.Compiled);
            MatchCollection matches = regex.Matches(input);

            foreach (Match match in matches) {
                string contenidoOriginal = match.Groups[1].Value;
                contenidoOriginal = contenidoOriginal.Replace("\n", "\r\n");
                string contenidoTratado = server.ParseVFPCode(contenidoOriginal, isExp, false);
                string etiquetaCompleta = match.Value;
                input = input.Replace(etiquetaCompleta, contenidoTratado);
            }

            return input;
        }

        public static string GetContentType(string filePath) { 
            switch (Path.GetExtension(filePath).ToLower()) {
                case ".html":
                    return "text/html";
                case ".txt":
                case ".prg":
                case ".log":
                    return "text/plain";
                case ".css":
                    return "text/css";
                case ".js":
                    return "application/javascript";
                case ".xml":
                    return "application/xml";
                case ".json":
                    return "application/json";
                case ".md":
                    return "text/markdown";
                case ".csv":
                    return "text/csv";
                case ".yml":
                case ".yaml":
                    return "application/x-yaml";
                case ".sql":
                    return "application/sql";
                case ".png":
                    return "image/png";
                case ".jpg":
                case ".jpeg":
                    return "image/jpeg";
                case ".ico":
                    return "image/x-icon";
                default:
                    return "application/octet-stream";
            }
        }

        public static bool IsBasedOnText(string extension) {
            string[] opciones = { ".html", ".txt", ".prg", ".log", ".css", ".js", ".xml", ".json", ".md", ".csv", ".yml", ".yaml", ".sql" };
            return opciones.Any(extension.Contains);
        }

        public static URI DesgloseURL(HttpRequest httpRequest) {
            URI uri = new URI();
            // Desglosar todas las partes de la URL
            uri.apiPath = server.GetAPIPath();          // ej: api/v1/
            uri.url = httpRequest.Url.AbsolutePath;     // api/v1/customers
            uri.path = httpRequest.Url.AbsolutePath;    // ej: customers/
            uri.urlFile = "";
            uri.urlParam = "";
            server.SetRequestURLParam("");

            if (uri.apiPath.Length > 0) {
                if (!uri.apiPath.StartsWith("/")) {
                    uri.apiPath = "/" + uri.apiPath;
                }
                if (uri.url.Substring(0, uri.apiPath.Length) != uri.apiPath) {
                    return null;
                }
                uri.path = uri.path.Substring(uri.apiPath.Length);
            }

            if (uri.url.Contains(".")) { // es un fichero ej: customers.html
                uri.urlFile = Path.GetFileName(httpRequest.Url.LocalPath);
                uri.path = uri.path.Replace(uri.urlFile, "");
            } else { // es un identificador ej: customers/fdsf8432749
                if (uri.path.Count(c => c == '/') > 1) {
                    uri.urlParam = uri.path.Substring(uri.path.LastIndexOf('/') + 1);
                    if (!string.IsNullOrEmpty(uri.urlParam)) {
                        //if (Regex.IsMatch(uri.urlParam, patron) || int.TryParse(uri.urlParam, out _)) {
                            server.SetRequestURLParam(uri.urlParam);
                            uri.path = uri.path.Replace(uri.urlParam, "");
                        //}
                    }
                }
            }
            if (uri.path.Length > 1 && uri.path.EndsWith("/")) {
                uri.path = uri.path.Substring(0, uri.path.LastIndexOf("/"));
            }
            return uri;
        }

        public static void UpdateFoxServerHTTPObjects(HttpRequest httpRequest, foxserver.Request foxRequest, foxserver.Response foxResponse, HttpResponse httpResponse) {
            foxRequest.SetMethod(httpRequest.HttpMethod);
            foxRequest.SetBody(httpRequest.Body);

            if (httpRequest.IsJSON) {
                // server.ParseJsonBodyFromRequest(foxRequest);
                server.SetIsPostAndJSon(true);
            }

            // 1. Headers
            foreach (var pair in httpRequest.Headers) {
                foxserver.Tuple tuple1 = new foxserver.Tuple();
                tuple1.SetKey(pair.Key);
                tuple1.SetValue(pair.Value);
                foxRequest.AddHeader(tuple1);
            }

            // 2. QueryParameters
            foreach (var pair in httpRequest.QueryParameters) {
                foxserver.Tuple tuple1 = new foxserver.Tuple();
                tuple1.SetKey(pair.Key);
                tuple1.SetValue(pair.Value);
                foxRequest.AddQueryParameter(tuple1);
            }

            // 3. Multipart
            foreach (var pair in httpRequest.MultiPart) {
                foxserver.Tuple tuple1 = new foxserver.Tuple();
                tuple1.SetKey(pair.Key);
                tuple1.SetValue(pair.Value);
                foxRequest.AddMultipart(tuple1);
            }
            // <------------------------------

            // Response de FoxServer            
            foxResponse.SetStatusCode(httpResponse.StatusCode);
            foxResponse.SetContentType(httpResponse.ContentType);
            foxResponse.SetContent(httpResponse.Content);
            // <------------------------------
        }

        public static bool IsPreflight(string method, NetworkStream networkStream) {
            if (method == "OPTIONS") {
                // Es una solicitud OPTIONS (preflight)
                // Devolver los encabezados CORS permitiendo cualquier cosa
                string responseHeaders = $"Access-Control-Allow-Origin: {server.GetAllowedOrigins()}\r\n" +
                                         "Access-Control-Allow-Methods: *\r\n" +
                                         "Access-Control-Allow-Headers: *\r\n" +
                                         "Allow: GET, POST, OPTIONS, PUT, DELETE\r\n";
                string resp = $"HTTP/1.1 200 OK\r\n{responseHeaders}\r\n";
                byte[] responseBytes = Encoding.UTF8.GetBytes(resp);
                networkStream.Write(responseBytes, 0, responseBytes.Length);
                return true;
            }
            return false;
        }

        public static HttpRequest CreateHttpRequest(NetworkStream networkStream, string host) {
            //logger.logFile = Path.Combine(@"c:\a1\findom\dist\", "FoxServer.log");
            HttpRequest httpRequest = new HttpRequest();
            StreamReader reader = new StreamReader(networkStream, Encoding.UTF8);

            // Leer la primera línea de la solicitud HTTP
            string requestLine = reader.ReadLine();
            //logger.Log(LogType.INFORMATION, requestLine);
            if (requestLine == null) {
                return null;
            }

            string[] requestParts = requestLine.Split(' ');
            if (requestParts.Length >= 3) {
                httpRequest.HttpMethod = requestParts[0];
                httpRequest.Url = new Uri($"http://{host}" + requestParts[1]); // Construye una URI absoluta
            }

            // Leer y analizar los encabezados HTTP
            string line;
            httpRequest.Headers = new Dictionary<string, string>();
            while (!string.IsNullOrEmpty(line = reader.ReadLine())) {
                //logger.Log(LogType.INFORMATION, line);
                string[] headerParts = line.Split(':');
                if (headerParts.Length == 2) {
                    string headerName = headerParts[0].Trim();
                    string headerValue = headerParts[1].Trim();
                    // IRODG 2024-04-15
                    httpRequest.Headers.Remove(headerName);
                    // IRODG 2024-04-15
                    httpRequest.Headers.Add(headerName, headerValue);
                }
            }

            // Analizar los parámetros de consulta en la URL
            if (httpRequest.Url != null && httpRequest.HttpMethod.Contains("GET")) {
                string queryString = HttpUtility.UrlDecode(httpRequest.Url.Query.TrimStart('?'));
                httpRequest.QueryParameters = ParseQueryString(queryString);
            }
            // Leer el cuerpo (body) de la solicitud y asignarlo a la propiedad Body
            else if (httpRequest.HttpMethod.Contains("POST") || httpRequest.HttpMethod.Contains("PUT")) {
                bool hasContentType = httpRequest.Headers.ContainsKey("Content-Type");                
                
                string contentType = "";
                if (hasContentType) contentType = httpRequest.Headers["Content-Type"];

                if (hasContentType &&
                    (contentType.StartsWith("text/") ||
                    contentType.StartsWith("application/json") ||
                    contentType.StartsWith("application/xml") ||
                    contentType.StartsWith("application/x-www-form-urlencoded") ||
                    contentType.StartsWith("multipart/form-data"))) {
                    // Procesar la solicitud que llega como texto
                    if (httpRequest.Headers.ContainsKey("Content-Length") && int.TryParse(httpRequest.Headers["Content-Length"], out int contentLength)) {
                        char[] buffer = new char[contentLength];
                        int bytesRead = reader.Read(buffer, 0, contentLength);
                        //logger.Log(LogType.INFORMATION, bytesRead.ToString());
                        httpRequest.Body = new string(buffer, 0, bytesRead);
                    }
                }

                // Procesar el body de aquellos contenidos con formato
                if (contentType.StartsWith("application/x-www-form-urlencoded")) {
                    // Analizar los datos x-www-form-urlencoded en un diccionario
                    httpRequest.MultiPart = ParseFormUrlEncodedData(httpRequest.Body);
                } else if (contentType.StartsWith("multipart/form-data")) {
                    string boundary = GetBoundaryFromContentType(contentType);
                    if (boundary != null) {
                        httpRequest.MultiPart = ParseMultipartFormData(httpRequest.Body, boundary);
                    }
                } else if (contentType.StartsWith("application/json")) {
                    httpRequest.IsJSON = true;
                }
            }
            return httpRequest;
        }

        public static string GetStatusMessage(int statusCode) {
            switch (statusCode) {
                case 100:
                    return "Continue";
                case 101:
                    return "Switching Protocols";
                case 102:
                    return "Processing";
                case 103:
                    return "Early Hints";
                case 200:
                    return "OK";
                case 201:
                    return "Created";
                case 202:
                    return "Accepted";
                case 203:
                    return "Non-Authoritative Information";
                case 204:
                    return "No Content";
                case 205:
                    return "Reset Content";
                case 206:
                    return "Partial Content";
                case 207:
                    return "Multi-Status";
                case 208:
                    return "Already Reported";
                case 226:
                    return "IM Used";
                case 300:
                    return "Multiple Choices";
                case 301:
                    return "Moved Permanently";
                case 302:
                    return "Found";
                case 303:
                    return "See Other";
                case 304:
                    return "Not Modified";
                case 305:
                    return "Use Proxy";
                case 307:
                    return "Temporary Redirect";
                case 308:
                    return "Permanent Redirect";
                case 400:
                    return "Bad Request";
                case 401:
                    return "Unauthorized";
                case 402:
                    return "Payment Required";
                case 403:
                    return "Forbidden";
                case 404:
                    return "Not Found";
                case 405:
                    return "Method Not Allowed";
                case 406:
                    return "Not Acceptable";
                case 407:
                    return "Proxy Authentication Required";
                case 408:
                    return "Request Timeout";
                case 409:
                    return "Conflict";
                case 410:
                    return "Gone";
                case 411:
                    return "Length Required";
                case 412:
                    return "Precondition Failed";
                case 413:
                    return "Payload Too Large";
                case 414:
                    return "URI Too Long";
                case 415:
                    return "Unsupported Media Type";
                case 416:
                    return "Range Not Satisfiable";
                case 417:
                    return "Expectation Failed";
                case 418:
                    return "I'm a Teapot";
                case 421:
                    return "Misdirected Request";
                case 422:
                    return "Unprocessable Entity";
                case 423:
                    return "Locked";
                case 424:
                    return "Failed Dependency";
                case 425:
                    return "Too Early";
                case 426:
                    return "Upgrade Required";
                case 428:
                    return "Precondition Required";
                case 429:
                    return "Too Many Requests";
                case 431:
                    return "Request Header Fields Too Large";
                case 451:
                    return "Unavailable For Legal Reasons";
                case 500:
                    return "Internal Server Error";
                case 501:
                    return "Not Implemented";
                case 502:
                    return "Bad Gateway";
                case 503:
                    return "Service Unavailable";
                case 504:
                    return "Gateway Timeout";
                case 505:
                    return "HTTP Version Not Supported";
                case 506:
                    return "Variant Also Negotiates";
                case 507:
                    return "Insufficient Storage";
                case 508:
                    return "Loop Detected";
                case 510:
                    return "Not Extended";
                case 511:
                    return "Network Authentication Required";
                default:
                    return "Unknown";
            }
        }

        private static string GetBoundaryFromContentType(string contentType) {
            string boundary = null;

            if (contentType != null) {
                string[] parts = contentType.Split(';');
                foreach (string part in parts) {
                    string trimmedPart = part.Trim();
                    if (trimmedPart.StartsWith("boundary=")) {
                        boundary = trimmedPart.Substring("boundary=".Length).Trim('"');
                        break;
                    }
                }
            }

            return boundary;
        }

        private static Dictionary<string, string> ParseMultipartFormData(string data, string boundary) {
            Dictionary<string, string> formData = new Dictionary<string, string>();
            string[] parts = data.Split(new string[] { boundary }, StringSplitOptions.RemoveEmptyEntries);

            foreach (string part in parts) {
                int dataStartIndex = part.IndexOf("\r\n\r\n", StringComparison.Ordinal);

                if (dataStartIndex >= 0) {
                    dataStartIndex += 4; // Avanzar al inicio de los datos
                    string partData = part.Substring(dataStartIndex);

                    // Eliminar cualquier cadena "--" que aparezca al final de los datos
                    partData = partData.TrimEnd('-', '>').Trim();

                    // Buscar el encabezado Content-Disposition en busca del nombre del campo
                    string contentDispositionHeader = part.Substring(0, dataStartIndex);
                    string[] contentDispositionLines = contentDispositionHeader.Split('\n');

                    string fieldName = null;
                    foreach (string line in contentDispositionLines) {
                        if (line.StartsWith("Content-Disposition", StringComparison.OrdinalIgnoreCase)) {
                            int nameIndex = line.IndexOf("name=\"", StringComparison.OrdinalIgnoreCase);
                            if (nameIndex >= 0) {
                                int startIndex = nameIndex + 6;
                                int endIndex = line.IndexOf("\"", startIndex);
                                if (endIndex >= 0) {
                                    fieldName = line.Substring(startIndex, endIndex - startIndex);
                                    break;
                                }
                            }
                        }
                    }

                    if (!string.IsNullOrEmpty(fieldName)) {
                        formData[fieldName] = partData;
                    }
                }
            }

            return formData;
        }

        private static Dictionary<string, string> ParseFormUrlEncodedData(string data) {
            Dictionary<string, string> formData = new Dictionary<string, string>();
            string[] keyValuePairs = data.Split('&');

            foreach (string keyValuePair in keyValuePairs) {
                string[] keyValue = keyValuePair.Split('=');
                if (keyValue.Length == 2) {
                    string key = WebUtility.UrlDecode(keyValue[0]);
                    string value = WebUtility.UrlDecode(keyValue[1]);
                    formData[key] = value;
                }
            }

            return formData;
        }

        private static Dictionary<string, string> ParseQueryString(string queryString) {
            // Este método analiza una cadena de consulta y devuelve un diccionario
            Dictionary<string, string> queryParams = new Dictionary<string, string>();

            string[] paramsPairs = queryString.Split('&');
            foreach (string paramPair in paramsPairs) {
                string[] keyValue = paramPair.Split('=');
                if (keyValue.Length == 2) {
                    string key = WebUtility.UrlDecode(keyValue[0]);
                    string value = WebUtility.UrlDecode(keyValue[1]);
                    queryParams[key] = value;
                }
            }
            return queryParams;
        }
    }
}
