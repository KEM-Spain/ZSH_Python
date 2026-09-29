# -*- coding: utf-8 -*-
import sys
import os
import logging
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
from playwright.sync_api import sync_playwright

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(name)s: %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler('/tmp/rutracker_proxy.log', mode='a')
    ]
)
logger = logging.getLogger("rutracker_proxy")

PROXY_PORT = 8989
USER_DATA_DIR = "/home/kmiller/.cache/playwright_rutracker_clean"

class TorrentProxyHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        parsed_url = urlparse(self.path)
        if parsed_url.path == '/dl.php':
            qs = parse_qs(parsed_url.query)
            t_id = qs.get('t', [None])[0]
            
            if t_id:
                logger.info(f"Intercepted download request for topic ID: {t_id}")
                target_url = f"https://rutracker.org/forum/dl.php?t={t_id}"
                
                try:
                    logger.info(f"Launching persistent browser context for topic {t_id}...")
                    with sync_playwright() as p:
                        browser_context = p.chromium.launch_persistent_context(
                            user_data_dir=USER_DATA_DIR,
                            executable_path="/usr/bin/google-chrome",
                            headless=False,
                            args=["--disable-blink-features=AutomationControlled"]
                        )
                        page = browser_context.new_page()
                        
                        logger.info(f"Navigating to {target_url} and waiting for download event...")
                        with page.expect_download() as download_info:
                            try:
                                page.goto(target_url, timeout=60000)
                            except Exception as nav_ex:
                                logger.debug(f"Navigation exception (normal for downloads): {nav_ex}")
                        
                        download = download_info.value
                        
                        # Wait for the download to finish completely and get path safely
                        path = download.path()
                        if not path or not os.path.exists(path):
                            raise Exception("Download path is invalid or file does not exist.")
                            
                        logger.info(f"Download completed for topic {t_id}, temp path: {path}")
                        
                        # Read the downloaded .torrent file bytes
                        with open(path, "rb") as f:
                            body = f.read()
                            
                        # Give it a tiny beat before closing to prevent abrupt window drops
                        page.wait_for_timeout(1000)
                        browser_context.close()
                        
                        logger.info(f"Browser closed, streaming {len(body)} bytes to client...")
                        
                        self.send_response(200)
                        self.send_header('Content-Type', 'application/x-bittorrent')
                        self.send_header('Content-Length', str(len(body)))
                        self.end_headers()
                        self.wfile.write(body)
                        logger.info(f"Successfully streamed torrent for topic {t_id}")
                        return
                        
                except Exception as e:
                    logger.error(f"Proxy download exception for topic {t_id}: {e}")
            
            self.send_response(500)
            self.end_headers()
            self.wfile.write(b"Proxy Error: Failed to fetch torrent.")
        else:
            self.send_response(404)
            self.end_headers()

def run_server():
    server = HTTPServer(('127.0.0.1', PROXY_PORT), TorrentProxyHandler)
    logger.info(f"Persistent RuTracker torrent proxy running on port {PROXY_PORT}...")
    server.serve_forever()

if __name__ == "__main__":
    run_server()
