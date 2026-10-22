import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

WORLD = {
    "today": {
        "date": {"season": "Summer", "day": 15, "year": 2},
        "weather": "Sunny",
        "festival": None,
        "birthdays": [],
    },
    "farmName": "Fazenda Teste",
    "currentMusicTrack": "",
}

PLAYER = {
    "name": "Bruno",
    "displayName": "Bruno",
    "farmName": "Fazenda Teste",
    "money": 12345,
    "stamina": 270.0,
    "maxStamina": 270,
    "health": 100,
    "maxHealth": 100,
    "location": "Farm",
    "relationships": [
        {"npc": {"name": "Abigail", "type": "Villager"}, "hearts": 10, "isMarried": False},
        {"npc": {"name": "Penny", "type": "Villager"}, "hearts": 14, "isMarried": True},
    ],
}

INVENTORY = [
    {"name": "Pufferfish", "displayName": "Baiacu", "qualifiedItemId": "(O)128", "stackSize": 1},
    {"name": "Quartz", "displayName": "Quartzo", "qualifiedItemId": "(O)80", "stackSize": 5},
    {"name": "Fried Egg", "displayName": "Ovo frito", "qualifiedItemId": "(O)194", "stackSize": 1},
    {"name": "Hoe", "displayName": "Enxada", "qualifiedItemId": "(T)Hoe", "stackSize": 1},
    {"name": "Parsnip", "displayName": "Pastinaca", "qualifiedItemId": "(O)24", "stackSize": 3},
]

MODS = [{"name": "Stardew Web API", "version": "0.7.0", "uniqueID": "zunderscore.StardewWebApi"}]


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        print("HTTP", self.path)

    def do_GET(self):
        path = self.path.split("?")[0]
        if path == "/api/v1/mods":
            self.reply(MODS)
        elif path == "/api/v1/world":
            self.reply(WORLD)
        elif path == "/api/v1/players/main":
            self.reply(PLAYER)
        elif path == "/api/v1/players/main/inventory":
            self.reply(INVENTORY)
        else:
            self.reply({"error": "not found"}, 404)

    def reply(self, body, status=200):
        data = json.dumps(body).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)


if __name__ == "__main__":
    server = ThreadingHTTPServer(("0.0.0.0", 7882), Handler)
    print("mock API em 0.0.0.0:7882", flush=True)
    server.serve_forever()
