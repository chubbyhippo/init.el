;;; java.el --- Java development extras  -*- lexical-binding: t; -*-

;; Optional Java layer for init.el. Disabled by default — uncomment the matching
;; loader at the bottom of init.el to enable it.
;;
;; Most of the stack is built in: the major mode (java-mode, or the tree-sitter
;; java-ts-mode) and eglot, which init.el already hooks onto prog-mode. You
;; supply two external programs:
;;   - jdtls (the Eclipse JDT language server) — eglot launches it automatically
;;     once it's on PATH; it imports Maven/Gradle projects on its own and gives
;;     completion / xref / rename / code actions / formatting — the IntelliJ
;;     core, minus the decompiler view and the test-runner UI
;;   - the java-debug plugin (com.microsoft.java.debug.plugin jar from Maven
;;     Central) — loaded into jdtls below so dape's built-in `jdtls' config can
;;     set breakpoints and step
;;
;; Both are installed by wsl-ubuntu-settings' init-el-extras.sh: jdtls into
;; ~/.local/share/jdtls (linked at ~/.local/bin/jdtls), the debug jar into
;; ~/.local/share/java-debug/.
;;
;; ELPA-only: dape, yasnippet, and javaimp are on GNU ELPA; the major mode and
;; eglot are built in. (eglot-java / lsp-java are MELPA-only, so they're
;; intentionally not used here.)
;;
;; Beyond expanding jdtls' LSP snippets, yasnippet here bundles an inline port
;; of the personal IntelliJ live templates (the Java / JUnit / Spring / Mockito
;; / WireMock groups from intellij-community-settings) as tab-triggers — see the
;; yasnippet block below. IntelliJ's built-in templates are left to jdtls, which
;; already serves them type-aware; only your own templates are ported here.

;;; Built-in
;; .java opens in the classic cc-mode `java-mode'. If the tree-sitter Java
;; grammar is installed (`M-x treesit-install-language-grammar RET java' — the
;; repo URL is pre-registered in :init, so there's no URL prompt), prefer the
;; faster `java-ts-mode'. eglot attaches to either one.
(use-package java-ts-mode
  :ensure nil
  :init
  ;; Register the grammar source (no URL prompt on install); prefer java-ts-mode
  ;; once the grammar exists.
  (when (and (require 'treesit nil t) (treesit-available-p))
    (add-to-list 'treesit-language-source-alist
                 '(java "https://github.com/tree-sitter/tree-sitter-java"))
    (when (treesit-language-available-p 'java)
      (add-to-list 'major-mode-remap-alist '(java-mode . java-ts-mode))))
  :custom
  (java-ts-mode-indent-offset 4))
;;; End Built-in

;;; GNU ELPA
;; snippet expansion for LSP completions AND a port of the personal IntelliJ
;; live templates (exported in intellij-community-settings, decoded to
;; yasnippet): with yas-minor-mode on, eglot expands jdtls' completion snippets
;; — a method's args drop in as TAB-able placeholders — and the tab-triggers
;; below expand too. IntelliJ's *built-in* Java templates (sout/iter/psvm…) are
;; deliberately NOT ported: jdtls already serves those, and type-aware, whereas
;; yasnippet cannot infer types. Ported nuances: `className()' becomes the
;; file's basename; IntelliJ smart-var functions (suggestVariableName,
;; variableOfType, …) downgrade to plain fields; the JUnit `test' method name
;; mirrors its @DisplayName via `my/java-camelcase'. `yas-indent-line' is set to
;; `fixed' so the multi-line blocks keep their own formatting on expansion.
(defun my/java-class-name ()
  "The enclosing file's class name (its basename), for className()-style snippets."
  (if (buffer-file-name) (file-name-base (buffer-file-name)) "Main"))

(defun my/java-camelcase (s)
  "Convert a display-name sentence S to a camelCase identifier."
  (let ((words (split-string (downcase s) "[^[:alnum:]]+" t)))
    (if words (concat (car words) (mapconcat #'capitalize (cdr words) "")) "")))

(defun my/java-yas-fixed-indent ()
  "Keep the bundled multi-line templates' own indentation on expansion."
  (setq-local yas-indent-line 'fixed))

(use-package yasnippet
  :ensure t
  :hook (((java-mode java-ts-mode) . yas-minor-mode)
         ((java-mode java-ts-mode) . my/java-yas-fixed-indent))
  :config
  ;; java-ts-mode does not derive from java-mode, so register for both.
  (dolist (mode '(java-mode java-ts-mode))
    (yas-define-snippets
     mode
     '(
       ;; ── Java ── files · HTTP client · sockets · loggers · concurrency
       ("log" "private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(`(my/java-class-name)`.class);"
        "SLF4J logger" nil "Java")

       ("random" "java.util.concurrent.ThreadLocalRandom.current()"
        "ThreadLocalRandom.current()" nil "Java")

       ("utilClass" "private `(my/java-class-name)`() {
    throw new java.lang.IllegalStateException(\"Utility class\");
}"
        "Util class private constructor" nil "Java")

       ("writeFile" "String content = \"${1:content}\";
java.nio.file.Path filePath = java.nio.file.Path.of(\"$2\");
java.nio.file.Files.writeString(filePath, content);"
        "Write content to file" nil "Java")

       ("readFile" "java.nio.file.Path filePath = java.nio.file.Path.of(\"$1\");
String content = java.nio.file.Files.readString(filePath);
System.out.println(content);"
        "Get string from reading text file" nil "Java")

       ("readFileLineByLine" "java.nio.file.Path filePath = java.nio.file.Path.of(\"$1\");

try (java.util.stream.Stream<String> lines = java.nio.file.Files.lines(filePath)) {
    lines.forEach(System.out::println);

} catch (java.io.IOException e) {
    throw new RuntimeException(e);
}"
        "Read file line by line" nil "Java")

       ("writeFileBuffer" "String content = \"${1:content}\";
java.nio.file.Path filePath = java.nio.file.Path.of(\"$2\");

try (java.io.BufferedWriter writer = java.nio.file.Files.newBufferedWriter(filePath, java.nio.charset.StandardCharsets.UTF_8)) {
    writer.write(content);
} catch (java.io.IOException e) {
    throw new RuntimeException(e);
}"
        "Write content to file using buffer" nil "Java")

       ("writeFileBufferLineByLine" "java.nio.file.Path filePath = java.nio.file.Path.of(\"$1\");

try (java.io.BufferedWriter writer = java.nio.file.Files.newBufferedWriter(filePath)) {
    writer.write(\"First line\");
    writer.newLine();
    writer.write(\"Second line\");

} catch (java.io.IOException e) {
    throw new RuntimeException(e);
}"
        "Write content to file using buffer" nil "Java")

       ("httpGetExample" " String url = \"https://jsonplaceholder.typicode.com/posts/1\";

 try (java.net.http.HttpClient httpClient = HttpClient.newBuilder()
         .executor(java.util.concurrent.Executors.newVirtualThreadPerTaskExecutor())
         .version(java.net.http.HttpClient.Version.HTTP_2)
         .connectTimeout(java.time.Duration.ofSeconds(10))
         .build()) {

     java.net.http.HttpRequest request = HttpRequest.newBuilder()
             .uri(java.net.URI.create(url))
             .timeout(java.time.Duration.ofSeconds(10))
             .header(\"Accept\", \"application/json\")
             .GET()
             .build();

     java.net.http.HttpResponse<String> response = httpClient.send(request, java.net.http.HttpResponse.BodyHandlers.ofString());
     System.out.println(\"Response status code: \" + response.statusCode());
     System.out.println(\"Response body: \" + response.body());

 } catch (java.io.IOException | InterruptedException e) {
     e.printStackTrace();
 }
 "
        "HttpClient blocking GET Example" nil "Java")

       ("httpGetAsyncExample" "String url = \"https://jsonplaceholder.typicode.com/posts/1\";

try (java.net.http.HttpClient httpClient = java.net.http.HttpClient.newBuilder()
        .version(java.net.http.HttpClient.Version.HTTP_2)
        .connectTimeout(java.time.Duration.ofSeconds(10))
        .build()) {

    java.net.http.HttpRequest request = java.net.http.HttpRequest.newBuilder()
            .uri(java.net.URI.create(url))
            .timeout(java.time.Duration.ofSeconds(10))
            .header(\"Accept\", \"application/json\")
            .GET()
            .build();

    java.util.concurrent.CompletableFuture<java.net.http.HttpResponse<String>> responseCompletableFuture = httpClient.sendAsync(request, java.net.http.HttpResponse.BodyHandlers.ofString());
    responseCompletableFuture.thenAccept(stringHttpResponse -> {
                System.out.println(\"Response status code: \" + stringHttpResponse.statusCode());
                System.out.println(\"Response body: \" + stringHttpResponse.body());
            })
            .exceptionally(throwable -> {
                throwable.printStackTrace();
                return null;
            })
            .join();
}
"
        "HttpClient non-blocking GET example" nil "Java")

       ("httpPostExample" "String url = \"https://jsonplaceholder.typicode.com/posts\";

try (java.net.http.HttpClient httpClient = java.net.http.HttpClient.newBuilder()
        .executor(java.util.concurrent.Executors.newVirtualThreadPerTaskExecutor()) 
        .version(java.net.http.HttpClient.Version.HTTP_2)
        .connectTimeout(java.time.Duration.ofSeconds(10))
        .build()) {

    String json = \"\"\"
            {
              \"id\": 101,
              \"title\": \"foo\",
              \"body\": \"bar\",
              \"userId\": 1
            }
            \"\"\";

    java.net.http.HttpRequest request = java.net.http.HttpRequest.newBuilder()
            .uri(java.net.URI.create(url))
            .timeout(java.time.Duration.ofSeconds(10))
            .header(\"Content-Type\", \"application/json; charset=utf-8\")
            .POST(java.net.http.HttpRequest.BodyPublishers.ofString(json))
            .build();

    java.net.http.HttpResponse<String> response = httpClient.send(request, java.net.http.HttpResponse.BodyHandlers.ofString());
    System.out.println(\"Response status code: \" + response.statusCode());
    System.out.println(\"Response body: \" + response.body());

} catch (java.io.IOException | InterruptedException e) {
    e.printStackTrace();
}
"
        "Httpclient blocking POST example" nil "Java")

       ("httpPutExample" "String url = \"https://jsonplaceholder.typicode.com/posts/1\";

try (java.net.http.HttpClient httpClient = java.net.http.HttpClient.newBuilder()
        .executor(java.util.concurrent.Executors.newVirtualThreadPerTaskExecutor())
        .version(java.net.http.HttpClient.Version.HTTP_2)
        .connectTimeout(java.time.Duration.ofSeconds(10))
        .build()) {

    String json = \"\"\"
            {
              \"id\": 101,
              \"title\": \"foo\",
              \"body\": \"bar\",
              \"userId\": 1
            }
            \"\"\";

    java.net.http.HttpRequest request = java.net.http.HttpRequest.newBuilder()
            .uri(java.net.URI.create(url))
            .timeout(java.time.Duration.ofSeconds(10))
            .header(\"Content-Type\", \"application/json; charset=utf-8\")
            .PUT(java.net.http.HttpRequest.BodyPublishers.ofString(json))
            .build();

    java.net.http.HttpResponse<String> response = httpClient.send(request, java.net.http.HttpResponse.BodyHandlers.ofString());
    System.out.println(\"Response status code: \" + response.statusCode());
    System.out.println(\"Response body: \" + response.body());

} catch (java.io.IOException | InterruptedException e) {
    e.printStackTrace();
}
"
        "Httpclient blocking PUT example" nil "Java")

       ("httpPatchExample" "String url = \"https://jsonplaceholder.typicode.com/posts/1\";

try (java.net.http.HttpClient httpClient = java.net.http.HttpClient.newBuilder()
        .executor(java.util.concurrent.Executors.newVirtualThreadPerTaskExecutor()) 
        .version(java.net.http.HttpClient.Version.HTTP_2)
        .connectTimeout(java.time.Duration.ofSeconds(10))
        .build()) {

    String json = \"\"\"
            {
              \"title\": \"foo\"
            }
            \"\"\";

    java.net.http.HttpRequest request = java.net.http.HttpRequest.newBuilder()
            .uri(java.net.URI.create(url))
            .timeout(java.time.Duration.ofSeconds(10))
            .header(\"Content-Type\", \"application/json; charset=utf-8\")
            .method(\"PATCH\", java.net.http.HttpRequest.BodyPublishers.ofString(json))
            .build();

    java.net.http.HttpResponse<String> response = httpClient.send(request, java.net.http.HttpResponse.BodyHandlers.ofString());
    System.out.println(\"Response status code: \" + response.statusCode());
    System.out.println(\"Response body: \" + response.body());

} catch (java.io.IOException | InterruptedException e) {
    e.printStackTrace();
}
"
        "HttpClient blocking PATCH example" nil "Java")

       ("httpDeleteExample" "String url = \"https://jsonplaceholder.typicode.com/posts/1\";

try (java.net.http.HttpClient httpClient = java.net.http.HttpClient.newBuilder()
        .executor(java.util.concurrent.Executors.newVirtualThreadPerTaskExecutor())
        .version(java.net.http.HttpClient.Version.HTTP_2)
        .connectTimeout(java.time.Duration.ofSeconds(10))
        .build()) {

    java.net.http.HttpRequest request = java.net.http.HttpRequest.newBuilder()
            .uri(java.net.URI.create(url))
            .timeout(java.time.Duration.ofSeconds(10))
            .DELETE()
            .build();

    java.net.http.HttpResponse<String> response = httpClient.send(request, java.net.http.HttpResponse.BodyHandlers.ofString());
    System.out.println(\"Response status code: \" + response.statusCode());
    System.out.println(\"Response body: \" + response.body());

} catch (java.io.IOException | InterruptedException e) {
    e.printStackTrace();
}
"
        "HttpClient blocking DELETE" nil "Java")

       ("webSocket" "try (java.net.http.HttpClient client = java.net.http.HttpClient.newBuilder().build()) {

    java.net.URI uri = java.net.URI.create(\"wss://echo.websocket.events\");

    java.net.http.WebSocket webSocket = client.newWebSocketBuilder()
            .buildAsync(uri,
                    new java.net.http.WebSocket.Listener() {
                        @Override
                        public void onOpen(java.net.http.WebSocket webSocket) {
                            System.out.println(\"Connected: \" + webSocket);
                            java.net.http.WebSocket.Listener.super.onOpen(webSocket);
                        }

                        @Override
                        public java.util.concurrent.CompletionStage<?> onText(java.net.http.WebSocket webSocket, CharSequence data, boolean last) {
                            System.out.println(\"Received: \" + data);
                            return java.net.http.WebSocket.Listener.super.onText(webSocket, data, last);
                        }

                        @Override
                        public java.util.concurrent.CompletionStage<?> onBinary(java.net.http.WebSocket webSocket, java.nio.ByteBuffer data, boolean last) {
                            System.out.println(\"onBinary Received: \" + data.toString());
                            return java.net.http.WebSocket.Listener.super.onBinary(webSocket, data, last);
                        }

                        @Override
                        public java.util.concurrent.CompletionStage<?> onPing(java.net.http.WebSocket webSocket, java.nio.ByteBuffer message) {
                            System.out.println(\"onPing Received: \" + message.toString());
                            return java.net.http.WebSocket.Listener.super.onPing(webSocket, message);
                        }

                        @Override
                        public java.util.concurrent.CompletionStage<?> onPong(java.net.http.WebSocket webSocket, java.nio.ByteBuffer message) {
                            System.out.println(\"onPong Received: \" + message.toString());
                            return java.net.http.WebSocket.Listener.super.onPong(webSocket, message);
                        }

                        @Override
                        public java.util.concurrent.CompletionStage<?> onClose(java.net.http.WebSocket webSocket, int statusCode, String reason) {
                            System.out.println(\"Closed: \" + webSocket + \" with statusCode: \" + statusCode + \", reason: \" + reason);
                            return java.net.http.WebSocket.Listener.super.onClose(webSocket, statusCode, reason);
                        }

                        @Override
                        public void onError(java.net.http.WebSocket webSocket, Throwable error) {
                            System.err.println(\"Error: \" + error.getMessage());
                            java.net.http.WebSocket.Listener.super.onError(webSocket, error);
                        }
                    })
            .join();

    webSocket.sendText(\"Hello, world!\", true);
    webSocket.sendClose(java.net.http.WebSocket.NORMAL_CLOSURE, \"Goodbye, world!\");

}"
        "WebSocket client" nil "Java")

       ("httpServerExample" "int port = 8080;

try {
    com.sun.net.httpserver.HttpServer server = com.sun.net.httpserver.HttpServer.create(new java.net.InetSocketAddress(port), 0);

    server.setExecutor(java.util.concurrent.Executors.newVirtualThreadPerTaskExecutor());

    server.createContext(\"/\", exchange -> {
        String response = \"Hello World!\";
        exchange.sendResponseHeaders(200, response.getBytes().length);
        exchange.getResponseBody().write(response.getBytes());
        exchange.close();
    });

    server.start();

    System.out.println(\"Server started on port \" + port);

} catch (java.io.IOException e) {
    throw new RuntimeException(e);
}
"
        "Simple HTTP server example" nil "Java")

       ("semaphoreExample" "final int MAX_CONCURRENT_THREADS = 2;
final java.util.concurrent.Semaphore semaphore = new java.util.concurrent.Semaphore(MAX_CONCURRENT_THREADS, true);

try (var executor = java.util.concurrent.Executors.newVirtualThreadPerTaskExecutor()) {

    for (int i = 0; i < 10; i++) {
        final int taskId = i;
        executor.submit(() -> {
            try {
                semaphore.acquire();
                System.out.println(\"Task \" + taskId + \" is acquiring the semaphore. thread id:\" + Thread.currentThread().threadId());
                Thread.sleep(2000);
                System.out.println(\"Task \" + taskId + \" is releasing the semaphore. thread id:\" + Thread.currentThread().threadId());
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                System.err.println(\"Task \" + taskId + \" was interrupted.\");
            } finally {
                semaphore.release();
            }
        });
    }
    
}
"
        "Semaphore example" nil "Java")

       ("semaphoreTimeLimitExample" " final int MAX_CONCURRENT_THREADS = 2;
 final java.util.concurrent.Semaphore semaphore = new java.util.concurrent.Semaphore(MAX_CONCURRENT_THREADS, true);

 try (var executor = java.util.concurrent.Executors.newVirtualThreadPerTaskExecutor()) {

     for (int i = 0; i < 10; i++) {
         final int taskId = i;
         executor.submit(() -> {
             try {
                 if (semaphore.tryAcquire(4000, java.util.concurrent.TimeUnit.MILLISECONDS)) {
                     
                     System.out.println(\"Task \" + taskId + \" is acquiring the semaphore. thread id:\" + Thread.currentThread().threadId());
                     Thread.sleep(1000);
                     System.out.println(\"Task \" + taskId + \" is releasing the semaphore. thread id:\" + Thread.currentThread().threadId());
                     
                 } else {
                     System.out.println(\"Task \" + taskId + \" was not able to acquire the semaphore.\");
                 }
                 
             } catch (InterruptedException e) {
                 Thread.currentThread().interrupt();
                 System.err.println(\"Task \" + taskId + \" was interrupted.\");
             } finally {
                 
                 int availablePermits = semaphore.availablePermits();
                 System.out.println(\"Semaphore available permits: \" + availablePermits);
                 
                 if (availablePermits < MAX_CONCURRENT_THREADS) {
                     semaphore.release();
                 }
             }
         });
     }

 }
"
        "Semaphore with time limit example" nil "Java")

       ("resourcesPrintFiles" " java.nio.file.Path path = java.nio.file.Path.of(ClassLoader.getSystemResource(\"\").toURI());
 try (java.util.stream.Stream<java.nio.file.Path> paths = java.nio.file.Files.walk(path)) {
     paths.filter(java.nio.file.Files::isRegularFile)
             .forEach(System.out::println);
} "
        "Print paths in resources" nil "Java")

       ("tcpServerExample" "try (java.net.ServerSocket serverSocket = new java.net.ServerSocket(1234)) {
    System.out.printf(\"Server is listening on port %s%n\", serverSocket.getLocalPort());

    while (true) {
        try (java.net.Socket socket = serverSocket.accept()) {
            System.out.println(\"New client connected\");

            java.io.InputStream input = socket.getInputStream();
            java.io.BufferedReader reader = new java.io.BufferedReader(new java.io.InputStreamReader(input));

            java.io.OutputStream output = socket.getOutputStream();
            java.io.PrintWriter writer = new java.io.PrintWriter(output, true);

            String clientMessage;
            while ((clientMessage = reader.readLine()) != null) {
                System.out.println(\"Received: \" + clientMessage);
                writer.println(clientMessage); // Echo back the message
            }
        } catch (java.io.IOException e) {
            e.printStackTrace();
        }
    }

} catch (java.io.IOException e) {
    e.printStackTrace();
}
"
        "Simple echo TCP server example" nil "Java")

       ("tcpClientExample" "String hostname = \"localhost\";
int port = 1234;

try (java.net.Socket socket = new java.net.Socket(hostname, port)) {
    java.io.InputStream input = socket.getInputStream();
    java.io.BufferedReader reader = new java.io.BufferedReader(new java.io.InputStreamReader(input));

    java.io.OutputStream output = socket.getOutputStream();
    java.io.PrintWriter writer = new java.io.PrintWriter(output, true);

    java.io.BufferedReader consoleReader = new java.io.BufferedReader(new java.io.InputStreamReader(System.in));
    String userInput;

    System.out.println(\"Connected to the server. Type messages to send:\");

    while ((userInput = consoleReader.readLine()) != null) {
        writer.println(userInput);
        String echoResponse = reader.readLine();
        System.out.println(\"Server echoed: \" + echoResponse);
    }

} catch (java.io.IOException ex) {
    ex.printStackTrace();
}
"
        "Simple echo TCP client example" nil "Java")

       ("consoleReaderBufferedReaderExample" "java.io.BufferedReader consoleReader = new java.io.BufferedReader(new java.io.InputStreamReader(System.in));
String userInput;
System.out.print(\"Enter a line of text: \");
while ((userInput = consoleReader.readLine()) != null) {
    System.out.println(\"userInput = \" + userInput);
}
"
        "Console reader using BufferedReader example" nil "Java")

       ("consoleReaderScannerExample" " java.util.Scanner consoleReader = new java.util.Scanner(System.in);
 String userInput;
 System.out.print(\"Enter a line of text: \");
 while (consoleReader.hasNextLine()) {
     userInput = consoleReader.nextLine();
     System.out.println(\"userInput = \" + userInput);
 }
"
        "Console reader using Scanner example" nil "Java")

       ("consoleReaderConsoleExample" "java.io.Console console = System.console();
if (console == null) {
    System.out.println(\"This code only works when run from a real console\");
    System.exit(1);
}

String username = console.readLine(\"Enter username: \");
char[] passwordChars = console.readPassword(\"Enter password: \");
String password = new String(passwordChars);

System.out.println(\"username = \" + username);
System.out.println(\"password = \" + password);
"
        "Console reader using Console example" nil "Java")

       ("loggerUtil" "private static final java.util.logging.Logger logger = java.util.logging.Logger.getLogger(`(my/java-class-name)`.class.getName());"
        "Java util logger" nil "Java")

       ("loggerPlatform" "private static final System.Logger logger = System.getLogger(`(my/java-class-name)`.class.getName());"
        "Java platform logger" nil "Java")

       ("httpGETBypassTLSSSL" "java.lang.String url = \"https://jsonplaceholder.typicode.com/posts/1\";

        // Trust-all SSL context (INSECURE: disables certificate and hostname verification)
        javax.net.ssl.TrustManager[] trustAll = new javax.net.ssl.TrustManager[]{
                new javax.net.ssl.X509TrustManager() {
                    @java.lang.Override
                    public void checkClientTrusted(java.security.cert.X509Certificate[] chain, java.lang.String authType) {
                    }

                    @java.lang.Override
                    public void checkServerTrusted(java.security.cert.X509Certificate[] chain, java.lang.String authType) {
                    }

                    @java.lang.Override
                    public java.security.cert.X509Certificate[] getAcceptedIssuers() {
                        return new java.security.cert.X509Certificate[0];
                    }
                }
        };
        javax.net.ssl.SSLContext sslContext;
        try {
            sslContext = javax.net.ssl.SSLContext.getInstance(\"TLS\");
            sslContext.init(null, trustAll, new java.security.SecureRandom());
        } catch (java.lang.Exception e) {
            throw new java.lang.RuntimeException(\"Failed to initialize insecure SSLContext\", e);
        }
        javax.net.ssl.SSLParameters sslParameters = new javax.net.ssl.SSLParameters();
        sslParameters.setEndpointIdentificationAlgorithm(null); // disables hostname verification

        try (java.net.http.HttpClient httpClient = java.net.http.HttpClient.newBuilder()
                .executor(java.util.concurrent.Executors.newVirtualThreadPerTaskExecutor())
                .version(java.net.http.HttpClient.Version.HTTP_2)
                .connectTimeout(java.time.Duration.ofSeconds(10))
                .sslContext(sslContext)
                .sslParameters(sslParameters)
                .build()) {

            java.net.http.HttpRequest request = java.net.http.HttpRequest.newBuilder()
                    .uri(java.net.URI.create(url))
                    .timeout(java.time.Duration.ofSeconds(10))
                    .header(\"Accept\", \"application/json\")
                    .GET()
                    .build();

            java.net.http.HttpResponse<java.lang.String> response = httpClient.send(request, java.net.http.HttpResponse.BodyHandlers.ofString());
            java.lang.System.out.println(\"Response status code: \" + response.statusCode());
            java.lang.System.out.println(\"Response body: \" + response.body());

        } catch (java.io.IOException | java.lang.InterruptedException e) {
            e.printStackTrace();
        }"
        "http get bypassing tls/ssl" nil "Java")

       ("scannerExample" "java.util.Scanner consoleReader = new java.util.Scanner(java.lang.System.in);
        java.lang.String userInput;
        java.lang.System.out.print(\"Enter a line of text: \");
        while (consoleReader.hasNextLine()) {
            userInput = consoleReader.nextLine();
            java.lang.System.out.println(\"userInput = \" + userInput);
        }"
        "Scanner example" nil "Java")

       ("mime" "java.nio.file.Files.probeContentType(java.nio.file.Path.of(\"file.pdf\"));"
        "MIME (please use apache Tika instead)" nil "Java")

       ;; ── JUnit ──
       ("utilTest" "@org.junit.jupiter.api.Test
@org.junit.jupiter.api.DisplayName(\"should throw illegal state exception when initialized\")
void shouldThrowIllegalStateExceptionWhenInitialized() {
    var constructor = `(let ((c (my/java-class-name))) (if (string-suffix-p \"Test\" c) (substring c 0 -4) c))`.class.getDeclaredConstructors()[0];
    constructor.setAccessible(true);
    try {
        constructor.newInstance();
    } catch (IllegalStateException | InstantiationException | IllegalAccessException |
             java.lang.reflect.InvocationTargetException exception) {
        org.assertj.core.api.Assertions.assertThat(exception.getCause().getClass()).isEqualTo(IllegalStateException.class);
        org.assertj.core.api.Assertions.assertThat(exception.getCause().getMessage()).isEqualTo(\"Utility class\");
    }
}
"
        "Create a new JUnit test for private constructor" nil "JUnit")

       ("test" "@org.junit.jupiter.api.Test
@org.junit.jupiter.api.DisplayName(\"${1:Display name for the test method}\")
void ${1:$(my/java-camelcase yas-text)}() {
    $0
    ${2:org.junit.jupiter.api.Assertions.fail(\"Not implemented\");}
}"
        "Create a new JUnit test that fails" nil "JUnit")

       ("tempDirPath" "@org.junit.jupiter.api.io.TempDir
    private java.nio.file.Path path;

    @org.junit.jupiter.api.Test
    @org.junit.jupiter.api.DisplayName(\"test path temp dir\")
    void testPathTempDir() throws java.io.IOException {
        var targetPath = \"etc/passwd/test.txt\";

        var nestedFile = path.resolve(targetPath);
        assertThat(nestedFile).isNotNull();

        java.nio.file.Files.createDirectories(nestedFile.getParent());
        assertThat(exists(nestedFile)).isFalse();

        java.nio.file.Files.write(nestedFile, \"test\".getBytes());
        assertThat(size(nestedFile)).isGreaterThan(0L);
    }"
        "JUnit @TempDir Path example" nil "JUnit")

       ;; ── Spring ──
       ("restTemplateBypassSSL" "javax.net.ssl.TrustManager[] trustAllCerts = new javax.net.ssl.TrustManager[]{
        new javax.net.ssl.X509TrustManager() {
            @java.lang.Override
            public void checkClientTrusted(java.security.cert.X509Certificate[] chain, java.lang.String authType) {
            }

            @java.lang.Override
            public void checkServerTrusted(java.security.cert.X509Certificate[] chain, java.lang.String authType) {
            }

            @java.lang.Override
            public java.security.cert.X509Certificate[] getAcceptedIssuers() {
                return new java.security.cert.X509Certificate[0];
            }
        }
};
try {
    javax.net.ssl.SSLContext sslContext = getInstance(\"TLS\");
    sslContext.init(null, trustAllCerts, new java.security.SecureRandom());

    setDefaultSSLSocketFactory(sslContext.getSocketFactory());
    javax.net.ssl.HostnameVerifier allHostsValid = (_, _) -> true;
    setDefaultHostnameVerifier(allHostsValid);
} catch (java.lang.Exception e) {
    throw new java.lang.IllegalStateException(\"Failed to configure trust-all SSL\", e);
}
return new org.springframework.web.client.RestTemplate();"
        "RestTemplate bypass SSL" nil "Spring")

       ("testPropertySource" "@org.springframework.test.context.TestPropertySource(properties = \"\"\"
        my.config.name=configname
        my.config.port=8080
        \"\"\")"
        "Spring @TestPropertySource example" nil "Spring")

       ("springBootTestRandomPort" "@org.springframework.boot.test.context.SpringBootTest(webEnvironment = org.springframework.boot.test.context.SpringBootTest.WebEnvironment.RANDOM_PORT)"
        "@SpringBootTest(webEnvironment = org.springframework.boot.test.context.SpringBootTest.WebEnvironment.RANDOM_PORT)" nil "Spring")

       ("springBootTestMock" "@org.springframework.boot.test.context.SpringBootTest(webEnvironment = org.springframework.boot.test.context.SpringBootTest.WebEnvironment.MOCK)"
        "@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.MOCK)" nil "Spring")

       ("invokeMethod" "org.springframework.test.util.ReflectionTestUtils.invokeMethod($1, \"${2:methodName}\", $0);"
        "Spring ReflectionTestUtils.invokeMethod" nil "Spring")

       ("setField" "org.springframework.test.util.ReflectionTestUtils.setField($1, \"${2:fieldName}\", $0);"
        "Spring ReflectionTestUtils.setField" nil "Spring")

       ;; ── Mockito ── argument matchers · mockStatic · mockConstruction
       ("spy" "org.mockito.Mockito.spy($1)$0"
        "Mockito.spy" nil "Mockito")

       ("mock" "org.mockito.Mockito.mock($0)
"
        "Mockito.mock" nil "Mockito")

       ("any" "org.mockito.Mockito.any()"
        "Mockito.any" nil "Mockito")

       ("anyString" "org.mockito.Mockito.anyString()"
        "Mockito.anyString" nil "Mockito")

       ("anyCollection" "org.mockito.Mockito.anyCollection()"
        "Mockito.anyCollection" nil "Mockito")

       ("anyByte" "org.mockito.Mockito.anyByte()"
        "Mockito.anyByte" nil "Mockito")

       ("anyChar" "org.mockito.Mockito.anyChar()"
        "Mockito.anyChar" nil "Mockito")

       ("anyDouble" "org.mockito.Mockito.anyDouble()"
        "Mockito.anyDouble" nil "Mockito")

       ("anyFloat" "org.mockito.Mockito.anyFloat()"
        "Mockito.anyFloat" nil "Mockito")

       ("anyInt" "org.mockito.Mockito.anyInt()"
        "Mockito.anyInt" nil "Mockito")

       ("anyList" "org.mockito.Mockito.anyList()"
        "Mockito.anyList" nil "Mockito")

       ("anyIterable" "org.mockito.Mockito.anyIterable()"
        "Mockito.anyIterable" nil "Mockito")

       ("anyLong" "org.mockito.Mockito.anyLong()"
        "Mockito.anyLong" nil "Mockito")

       ("anyMap" "org.mockito.Mockito.anyMap()"
        "Mockito.anyMap" nil "Mockito")

       ("anySet" "org.mockito.Mockito.anySet()"
        "Mockito.anySet" nil "Mockito")

       ("extendWithMockitoExtension" "@org.junit.jupiter.api.extension.ExtendWith(org.mockito.junit.jupiter.MockitoExtension.class)"
        "@ExtendWith(MockitoExtension.class)" nil "Mockito")

       ("mockStaticExample" "@org.junit.jupiter.api.Test
    @org.junit.jupiter.api.DisplayName(\"test mock files.exists\")
    void testMockFilesExists() {
        try (org.mockito.MockedStatic<java.nio.file.Files> filesMock = org.mockito.Mockito.mockStatic(java.nio.file.Files.class)) {
            java.nio.file.Path mockPath = java.nio.file.Path.of(\"/test/file.txt\");

            filesMock.when(() -> java.nio.file.Files.exists(mockPath))
                    .thenReturn(true);

            boolean exists = java.nio.file.Files.exists(mockPath);

            org.assertj.core.api.Assertions.assertThat(exists).isTrue();

            filesMock.verify(() -> java.nio.file.Files.exists(mockPath));
        }
    }"
        "Mockito.mockStatic Example" nil "Mockito")

       ("mockConstructionExample" "@org.junit.jupiter.api.Test
    @org.junit.jupiter.api.DisplayName(\"test mock construction\")
    void testMockConstruction() {
        try (org.mockito.MockedConstruction<ExampleClass> mocked = org.mockito.Mockito.mockConstruction(ExampleClass.class,
                (mock, _) -> {
                    org.mockito.Mockito.when(mock.isTrue()).thenReturn(false);
                })) {

            ExampleClass example = new ExampleClass();
            java.lang.Boolean result = example.isTrue();

            org.assertj.core.api.Assertions.assertThat(result).isFalse();
            org.assertj.core.api.Assertions.assertThat(mocked.constructed()).hasSize(1);
        }
    }

    private static class ExampleClass {
        public java.lang.Boolean isTrue() {
            return true;
        }
    }"
        "Mockito.MockConstruction Example" nil "Mockito")

       ("mockStatic" "try (org.mockito.MockedStatic<$1> $2 = org.mockito.Mockito.mockStatic($1.class)) {
    $2.when(() -> $1.$0);
}"
        "Mockito.mockStatic" nil "Mockito")

       ("mockConstruction" "try (org.mockito.MockedConstruction<$1> $2 = org.mockito.Mockito.mockConstruction($1.class,
                (mock, context) -> {
                    when(mock.$0).thenReturn();
                })) {
        }"
        "Mockito.mockConstruction" nil "Mockito")

       ;; ── WireMock ──
       ("wireMockRegisterExtension" "@org.junit.jupiter.api.extension.RegisterExtension
    static com.github.tomakehurst.wiremock.junit5.WireMockExtension wireMockServer = com.github.tomakehurst.wiremock.junit5.WireMockExtension.newInstance()
            .options(com.github.tomakehurst.wiremock.core.WireMockConfiguration.wireMockConfig()
                    .dynamicPort())
            .build();

    private final java.net.http.HttpClient httpClient = java.net.http.HttpClient.newHttpClient();

    @org.junit.jupiter.api.Test
    @org.junit.jupiter.api.DisplayName(\"test get endpoint\")
    void testGetEndpoint() throws java.lang.Exception {
        wireMockServer.stubFor(get(urlEqualTo(\"/api/users/1\"))
                .willReturn(aResponse()
                        .withStatus(200)
                        .withHeader(\"Content-Type\", \"application/json\")
                        .withBody(\"\"\"
                                {
  \"id\": 1,
  \"name\": \"John Doe\",
  \"email\": \"john@example.com\"
}

                                \"\"\")));

        var request = java.net.http.HttpRequest.newBuilder()
                .uri(java.net.URI.create(wireMockServer.baseUrl() + \"/api/users/1\"))
                .GET()
                .build();

        var response = httpClient.send(request, java.net.http.HttpResponse.BodyHandlers.ofString());

        assertThat(response.statusCode()).isEqualTo(200);
        assertThat(response.body()).contains(\"John Doe\");
        assertThat(response.body()).contains(\"john@example.com\");

        wireMockServer.verify(getRequestedFor(urlEqualTo(\"/api/users/1\")));
    }

    @org.junit.jupiter.api.Test
    @org.junit.jupiter.api.DisplayName(\"test post endpoint\")
    void testPostEndpoint() throws java.lang.Exception {
        wireMockServer.stubFor(post(urlEqualTo(\"/api/users\"))
                .withHeader(\"Content-Type\", equalTo(\"application/json\"))
                .withRequestBody(containing(\"Jane\"))
                .willReturn(aResponse()
                        .withStatus(201)
                        .withHeader(\"Content-Type\", \"application/json\")
                        .withBody(\"\"\"
                                {
  \"id\": 2,
  \"name\": \"Jane Smith\",
  \"message\": \"User created successfully\"
}

                                \"\"\")));

        var requestBody = \"\"\"
                {
                  \"name\": \"Jane Smith\",
                  \"email\": \"jane@example.com\"
                }
                \"\"\";

        var request = java.net.http.HttpRequest.newBuilder()
                .uri(java.net.URI.create(wireMockServer.baseUrl() + \"/api/users\"))
                .header(\"Content-Type\", \"application/json\")
                .POST(java.net.http.HttpRequest.BodyPublishers.ofString(requestBody))
                .build();

        var response = httpClient.send(request, java.net.http.HttpResponse.BodyHandlers.ofString());

        assertThat(response.statusCode()).isEqualTo(201);
        assertThat(response.body()).contains(\"Jane Smith\");
        assertThat(response.body()).contains(\"User created successfully\");

        wireMockServer.verify(postRequestedFor(urlEqualTo(\"/api/users\"))
                .withHeader(\"Content-Type\", equalTo(\"application/json\")));
    }"
        "WireMock @RegisterExtension example" nil "WireMock")))))

;; DAP-based debugging that pairs with eglot (no lsp-mode needed). To debug:
;; M-x dape, choose the `jdtls' config — it asks the running eglot jdtls
;; session to start a debug session, which only works once the java-debug
;; bundle below is loaded. Set breakpoints with `dape-breakpoint-toggle';
;; n / c step once a session stops.
(use-package dape
  :ensure t
  :commands (dape dape-breakpoint-toggle)
  :custom
  (dape-buffer-window-arrangement 'right)  ; debugger windows on the right
  (dape-inlay-hints t))                     ; show variable values inline when stopped

;; Optional, also on GNU ELPA — uncomment if wanted:
;; (use-package javaimp :ensure t) ; add/organize Maven/Gradle imports
;;                                 ; M-x javaimp-add-import / javaimp-organize-imports
;;; End GNU ELPA

;;; Debug adapter (java-debug) — makes `M-x dape' => `jdtls' actually work
;; eglot runs `jdtls' from PATH, but the Eclipse server only grows its debug
;; commands (resolveMainClass / startDebugSession / ...) once the java-debug
;; bundle is loaded through initializationOptions. init-el-extras.sh downloads
;; the jar from Maven Central; this hands it to jdtls. Until the jar exists
;; it's a harmless no-op (`:bundles []') and ordinary LSP still works.
(defvar my/java-debug-bundle-directory
  (expand-file-name "~/.local/share/java-debug/")
  "Directory holding the `com.microsoft.java.debug.plugin-*.jar' bundle.")

(defun my/java--jdtls-initialization-options (&optional _server)
  "jdtls initializationOptions that load the java-debug bundle(s)."
  (let ((jars (file-expand-wildcards
               (expand-file-name "com.microsoft.java.debug.plugin-*.jar"
                                 my/java-debug-bundle-directory))))
    `(:bundles ,(vconcat jars)
      :extendedClientCapabilities (:classFileContentsSupport t))))

(with-eval-after-load 'eglot
  ;; prepended, so it wins over eglot's bare ("jdtls") default for these modes
  (add-to-list 'eglot-server-programs
               '((java-mode java-ts-mode)
                 . ("jdtls" :initializationOptions
                    my/java--jdtls-initialization-options))))

(provide 'java)
;;; java.el ends here
