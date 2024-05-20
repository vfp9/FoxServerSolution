using System;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading;

namespace FoxServer {
    internal class Program {
        private static readonly LogWriter logger = new LogWriter();
        private static string serverURL = "";
        private static readonly string directorioActual = AppDomain.CurrentDomain.BaseDirectory;
        private static readonly string publicDirectory = directorioActual + "public\\";
        private static foxserver.Wrapper server;
        private static readonly string logName = "FoxServer.log";
        private static string configFile = Path.Combine(directorioActual, "config.kvp");        

        static void Main(string[] args) {
            // Revisamos si existe el fichero de configuración
            logger.logFile = Path.Combine(directorioActual, logName);

            if (!File.Exists(configFile)) {
                logger.Log(LogType.ERROR, "The file 'config.kvp' does not exist in the server directory.");
                return;
            }

            server = new foxserver.Wrapper();
            server.SetConfigFile(configFile);
            server.SetLogFile(logger.logFile);
            server.LoadSettings();

            if (!server.IsReady()) {
                return;
            }
            Helper.server = server;
            Helper.publicDirectory = publicDirectory;
            Helper.notFoundPage = Path.Combine(publicDirectory + "404.html");

            string ipAddress = server.GetHost();
            int port = server.GetPort();
            string apiPath = server.GetAPIPath();

            serverURL = $"http://{server.GetHost()}:{server.GetPort()}/";
            if (!string.IsNullOrEmpty(apiPath)) {
                serverURL += apiPath;
            }
            
            try {
                TcpListener listener = new TcpListener(IPAddress.Parse(ipAddress), port);
                listener.Start();
                logger.Log(LogType.INFORMATION, $"Web service listening at http://{ipAddress}:{port}/");

                while (true) {
                    TcpClient client = listener.AcceptTcpClient();
                    ThreadPool.QueueUserWorkItem(ProcessRequest, client);
                }
            } catch(Exception ex) {
                logger.Log(LogType.ERROR, ex.Message);
            }
        }

        static void ProcessRequest(object tcpClient) {
            try {
                TcpClient client = (TcpClient)tcpClient;
                NetworkStream networkStream = client.GetStream();

                // Crear los objetos HttpRequest y HttpResponse
                HttpRequest httpRequest = Helper.CreateHttpRequest(networkStream, server.GetHost());                
                HttpResponse httpResponse = new HttpResponse();

                if (httpRequest == null) {
                    client.Close();
                    return;
                }

                // Revisar si es petición preflight
                if (Helper.IsPreflight(httpRequest.HttpMethod, networkStream)) {
                    client.Close();
                    return;
                }

                // Resetear el objeto JSON (por peticiones anteriores)
                server.ResetJsonObject();

                // Request de FoxServer
                foxserver.Request foxRequest = new foxserver.Request();
                foxserver.Response foxResponse = new foxserver.Response();

                Helper.UpdateFoxServerHTTPObjects(httpRequest, foxRequest, foxResponse, httpResponse);

                // Setear los objetos
                server.SetResponse(foxResponse);
                server.SetRequest(foxRequest);

                // Impedir las peticiones tipo PATCH y HEAD
                if (httpRequest.HttpMethod == "PATCH" || httpRequest.HttpMethod == "HEAD") {
                    httpResponse.StatusCode = 405;
                    httpResponse.StatusMessage = "Method Not Allowed";
                    httpResponse.ContentType = "application/json";
                    string msg = "Método no permitido. FoxServer solo admite los métodos GET, POST, PUT y DELETE.";
                    if (server.GetLang().ToLower() == "en") {
                        msg = "Method not allowed. FoxServer only supports the GET, POST, PUT, and DELETE methods.";
                    }
                    httpResponse.Content = server.GetJsonResponse("error", null, msg);
                    WriteHttpResponse(httpResponse, networkStream, client);
                    return;
                }

                // Desglosar la URL
                URI uri = Helper.DesgloseURL(httpRequest);
                if (uri == null) {
                    httpResponse.StatusCode = 400;
                    httpResponse.StatusMessage = "Bad Request";
                    httpResponse.ContentType = "application/json";
                    string msg = "La URL no contiene el path correcto";
                    if (server.GetLang().ToLower() == "en") {
                        msg = "The URL path is not correct.";
                    }
                    httpResponse.Content = server.GetJsonResponse("error", null, msg);
                    WriteHttpResponse(httpResponse, networkStream, client);
                    return;
                }

                // Verificamos si están pidiendo el landing page
                if ((string.IsNullOrEmpty(uri.path) || uri.path == "/") && string.IsNullOrEmpty(uri.urlFile)) {
                    string indexHTML = Path.Combine(publicDirectory, "index.html");
                    if (File.Exists(indexHTML)) {
                        httpResponse.StatusCode = 200;
                        httpResponse.ContentType = "text/html";
                        httpResponse.Content = Helper.ParseHTML(File.ReadAllText(indexHTML));
                        WriteHttpResponse(httpResponse, networkStream, client);
                        return;
                    }
                }
                string lcPath = uri.path;
                // Verificamos si se trata de un recurso estático ej: "script.js"
                if (!string.IsNullOrEmpty(uri.urlFile)) {
                    string filePath = "";
                    bool isHTML = false;

                    if (uri.path != "/") {
                        string path = uri.path;
                        if (uri.path.StartsWith("/")) {
                            path = path.Substring(1);
                        }
                        if (path.EndsWith("/")) {
                            path = path.Substring(0, path.Length - 1);
                        }
                        path = path.Replace("/", "\\");

                        filePath = Path.Combine(publicDirectory, path, uri.urlFile);
                    } else if (uri.urlFile.EndsWith(".html")) {
                        isHTML = true;
                        if (uri.urlFile != "index.html") {
                            filePath = Path.Combine(publicDirectory + "html\\", uri.urlFile);
                        } else {
                            filePath = Path.Combine(publicDirectory, uri.urlFile);
                        }
                    } else {
                        filePath = Path.Combine(publicDirectory, uri.urlFile);
                    }

                    bool isBasedOnText = Helper.IsBasedOnText(Path.GetExtension(filePath));

                    if (!File.Exists(filePath)) {
                        httpResponse.StatusCode = 404;
                        if (File.Exists(Helper.notFoundPage)) {
                            httpResponse.ContentType = "text/html";
                            httpResponse.Content = Helper.ParseHTML(File.ReadAllText(Helper.notFoundPage));
                        } else {
                            httpResponse.ContentType = "text/plain";
                            httpResponse.Content = "404-Not Found";
                        }
                        WriteHttpResponse(httpResponse, networkStream, client);
                        return;
                    } else if (!filePath.EndsWith(".prg")) {
                        httpResponse.StatusCode = 200;
                        httpResponse.ContentType = Helper.GetContentType(filePath);
                        if (isBasedOnText) {
                            if (isHTML) {
                                httpResponse.Content = Helper.ParseHTML(File.ReadAllText(filePath));
                            } else {
                                httpResponse.Content = File.ReadAllText(filePath);
                            }
                        } else {
                            httpResponse.Content = "";
                            httpResponse.BinaryData = File.ReadAllBytes(filePath);
                        }
                        WriteHttpResponse(httpResponse, networkStream, client);
                        return;
                    } else { // Es un PRG
                        lcPath = filePath;
                    }
                }

                // Es una petición para API RESTful ej: "/api/productos"                
                server.HandleRequest(lcPath);
                server.UpdateResponseFromInstance(foxResponse);

                httpResponse.StatusCode = foxResponse.GetStatusCode();
                httpResponse.StatusMessage = Helper.GetStatusMessage(httpResponse.StatusCode);
                httpResponse.ContentType = foxResponse.GetContentType();
                httpResponse.Content = foxResponse.GetContent();
                if (httpResponse.Content == " ") {
                    httpResponse.Content = "";
                }
                // ¿Devolver un fichero?
                httpResponse.FilePath = foxResponse.GetFileName();

                if (!string.IsNullOrEmpty(httpResponse.FilePath) && File.Exists(httpResponse.FilePath)) {
                    httpResponse.BinaryData = File.ReadAllBytes(httpResponse.FilePath);
                }

                if (httpResponse.StatusCode == 201) {
                    string location = uri.path;
                    if (!location.EndsWith("/")) {
                        location += "/";
                    }
                    location += foxResponse.GetLocation();
                    httpResponse.Location = location;
                }                            
                httpResponse.IncludeContentType = httpRequest.HttpMethod != "OPTIONS";

                while (foxResponse.HasNextHeader()) {
                    foxserver.Tuple headerTuple = new foxserver.Tuple();
                    foxResponse.GetNextHeader(headerTuple);
                    // IRODG 2024-04-15
                    httpResponse.Headers.Remove(headerTuple.GetKey());
                    // IRODG 2024-04-15
                    httpResponse.Headers.Add(headerTuple.GetKey(), headerTuple.GetValue());
                }
                WriteHttpResponse(httpResponse, networkStream, client);
            } catch (Exception ex){
                logger.Log(LogType.ERROR, $"Error en ProcessRequest: {ex.Message}");
                Console.WriteLine(ex.ToString());
            }
        }
        private static void WriteHttpResponse(HttpResponse httpResponse, NetworkStream networkStream, TcpClient client) {
            // Construir la respuesta HTTP basada en el objeto HttpResponse
            string header = Helper.BuildHttpResponse(httpResponse);
            byte[] headerBytes = Encoding.UTF8.GetBytes(header);
            byte[] binaryData = httpResponse.BinaryData;

            // Escribir la respuesta en el flujo de red usando MemoryStream
            using (MemoryStream responseStream = new MemoryStream()) {
                responseStream.Write(headerBytes, 0, headerBytes.Length);
                if (binaryData != null) responseStream.Write(binaryData, 0, binaryData.Length);

                responseStream.Seek(0, SeekOrigin.Begin);
                responseStream.CopyTo(networkStream);
            }
            // Resetar las propiedades del Helper
            client.Close();
        }
    }
}
