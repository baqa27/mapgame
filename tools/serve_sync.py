#!/usr/bin/env python3
import http.server
import pathlib
import sys

script_dir = pathlib.Path(__file__).parent.resolve()
sync_file = script_dir / "sync_to_studio.lua"

class SyncHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass

    def do_GET(self):
        if self.path == "/sync":
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            content = sync_file.read_text(encoding="utf-8")
            self.wfile.write(content.encode("utf-8"))
            sys.exit(0)
        else:
            self.send_response(404)
            self.end_headers()

def run():
    server_address = ('', 8124)
    httpd = http.server.HTTPServer(server_address, SyncHandler)
    print("Sync server started on port 8124...")
    try:
        httpd.serve_forever()
    except SystemExit:
        print("Sync file successfully served.")

if __name__ == "__main__":
    run()
