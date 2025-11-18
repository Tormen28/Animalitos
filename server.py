#!/usr/bin/env python3
"""
Servidor simple para Flutter Web SPA
Redirige todas las rutas al index.html para soporte SPA
"""

import http.server
import socketserver
import os
from urllib.parse import urlparse, parse_qs
import json

class FlutterWebHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        # Para cualquier ruta que no sea un archivo estático, servir index.html
        parsed_path = urlparse(self.path)
        path = parsed_path.path

        # Si es una ruta de API o archivo estático, servir normalmente
        if (path.startswith('/assets/') or
            path.startswith('/packages/') or
            path.endswith('.js') or
            path.endswith('.json') or
            path.endswith('.png') or
            path.endswith('.jpg') or
            path.endswith('.ico') or
            path.endswith('.svg') or
            path.endswith('.ttf') or
            path.endswith('.woff') or
            path.endswith('.woff2')):
            super().do_GET()
        else:
            # Para cualquier otra ruta (SPA routes), servir index.html
            self.path = '/index.html'
            super().do_GET()

    def end_headers(self):
        # Agregar headers CORS para desarrollo
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        super().end_headers()

if __name__ == '__main__':
    # Cambiar al directorio build/web
    web_dir = os.path.join(os.getcwd(), 'build', 'web')
    if os.path.exists(web_dir):
        os.chdir(web_dir)
        print(f"Sirviendo archivos desde: {web_dir}")
    else:
        print(f"ERROR: Directorio {web_dir} no encontrado. Ejecuta 'flutter build web' primero.")
        exit(1)

    port = 8082
    with socketserver.TCPServer(("", port), FlutterWebHandler) as httpd:
        print(f"Servidor Flutter Web ejecutandose en: http://localhost:{port}")
        print("Presiona Ctrl+C para detener")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nServidor detenido")
            httpd.shutdown()