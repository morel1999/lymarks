"""Sert le build web sur le reseau local, pour ouvrir l'app sur un telephone.

    flutter build web
    python tool/serve_web.py

Puis ouvrir l'URL affichee depuis le navigateur du telephone, sur le meme
Wi-Fi. C'est un apercu web, pas l'app native : ni menu de partage, ni
notifications. Utile pour juger le rendu et les gestes avant d'avoir une
chaine de build mobile.

Serveur multi-thread a dessein : `python -m http.server` est mono-thread et
coupe les connexions (ERR_CONNECTION_RESET) sous les requetes paralleles que
Flutter emet au demarrage.

Le serveur ecoute sur toutes les interfaces : il est donc joignable par tout
appareil du reseau local. A arreter (Ctrl+C) une fois la verification faite.
"""

import socket
import sys
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8478
ROOT = Path(__file__).resolve().parent.parent / "build" / "web"


class Handler(SimpleHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def end_headers(self):
        # Un build rejoue est servi tel quel : pas de cache navigateur.
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


def lan_ip() -> str:
    """Adresse de cette machine vue du reseau local."""
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        sock.connect(("8.8.8.8", 80))  # aucun paquet envoye, juste le routage
        return sock.getsockname()[0]
    except OSError:
        return "127.0.0.1"
    finally:
        sock.close()


def main() -> int:
    if not (ROOT / "index.html").exists():
        print(f"Aucun build web dans {ROOT}.")
        print("Lancer d'abord : flutter build web")
        return 1

    server = ThreadingHTTPServer(
        ("0.0.0.0", PORT), partial(Handler, directory=str(ROOT))
    )
    server.daemon_threads = True
    print(f"Lymarks sur http://{lan_ip()}:{PORT}  (Ctrl+C pour arreter)")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nArrete.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
