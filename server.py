from http.server import HTTPServer, BaseHTTPRequestHandler

def read_file(path):
    with open(path, 'r', encoding="utf8") as file:
        return file.read().encode("utf8")

class S(BaseHTTPRequestHandler):
    def _set_headers(self):
        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()

    def do_GET(self):
        self._set_headers()
        self.wfile.write(read_file("./index.html"))

    def do_HEAD(self):
        self._set_headers()


def run(addr, port, server_class=HTTPServer):
    server_address = (addr, port)
    httpd = server_class(server_address, S)

    print(f"Starting httpd server on http://{addr}:{port}")
    httpd.serve_forever()


if __name__ == "__main__":
    run(addr="127.0.0.1", port=4850)
