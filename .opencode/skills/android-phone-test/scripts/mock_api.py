import json
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

# Estado do jogo completo simulando o Stardew Valley
GAME_STATE = {
    "world": {
        "today": {
            "date": {
                "season": "Spring",
                "day": 12,
                "year": 1,
                "dayOfWeek": "Friday",
                "shortDayOfWeek": "Sex",
            },
            "weather": "Sunny",
            "festival": None,
            "birthdays": [
                {"name": "Abigail", "type": "Villager"}
            ],
        },
        "farmName": "Vale da Paz",
        "currentMusicTrack": "spring_day_ambient",
    },
    "player": {
        "name": "Bruno",
        "displayName": "Bruno",
        "farmName": "Vale da Paz",
        "money": 4850,
        "stamina": 220.0,
        "maxStamina": 270,
        "health": 95,
        "maxHealth": 100,
        "location": "Farm",
        "dailyLuck": 0.08,
        "dailyLuckFriendlyValue": "+8.0%",
        "dailyLuckDescription": "Os espíritos estão de muito bom humor hoje. Eles farão o seu melhor para abençoar a todos com boa sorte.",
        "clothing": {
            "hat": {"name": "Straw Hat", "displayName": "Chapéu de palha", "qualifiedItemId": "(H)0"},
            "shirt": {"name": "Shirt", "displayName": "Camisa de Trabalho", "qualifiedItemId": "(S)1000"},
            "pants": {"name": "Farmer Pants", "displayName": "Calça Jeans", "qualifiedItemId": "(P)1"},
            "boots": {"name": "Work Boots", "displayName": "Botas de Trabalho", "qualifiedItemId": "(B)504"},
            "leftRing": {"name": "Glow Ring", "displayName": "Anel de Brilho", "qualifiedItemId": "(R)517"},
            "rightRing": {"name": "Magnet Ring", "displayName": "Anel de Ímã", "qualifiedItemId": "(R)519"}
        },
        "skills": [
            {"id": 0, "name": "Cultivo", "level": 4, "professions": []},
            {"id": 1, "name": "Pesca", "level": 3, "professions": []},
            {"id": 2, "name": "Coleta", "level": 2, "professions": []},
            {"id": 3, "name": "Mineração", "level": 5, "professions": [{"id": 18, "name": "Mineiro", "description": "+1 minério por veio"}]},
            {"id": 4, "name": "Combate", "level": 2, "professions": []}
        ],
        "quests": [
            {
                "title": "Apresentações",
                "description": "Seria uma boa ideia se apresentar para os moradores da vila. Algumas pessoas podem ser tímidas, mas a maioria é bem simpática.",
                "hasReward": False,
                "rewardDescription": "Boas-vindas e amizade",
                "hasMoneyReward": False,
                "moneyReward": 0,
                "currentObjective": "Converse com 28 moradores (21/28)",
                "isTimedQuest": False,
                "daysLeft": None
            },
            {
                "title": "Colheita de Primavera",
                "description": "Pierre quer uma couve-flor fresca da estação para a sua família no jantar.",
                "hasReward": True,
                "rewardDescription": "350 ouros e 1 coração de amizade",
                "hasMoneyReward": True,
                "moneyReward": 350,
                "currentObjective": "Entregue 1 couve-flor fresca para o Pierre no armazém",
                "isTimedQuest": True,
                "daysLeft": 2
            },
            {
                "title": "Explorando as Minas",
                "description": "Marlon pediu para você descer até o nível 40 das minas para provar sua bravura na guilda.",
                "hasReward": True,
                "rewardDescription": "Espada de ferro e acesso à Guilda",
                "hasMoneyReward": False,
                "moneyReward": 0,
                "currentObjective": "Alcance o andar 40 das Minas locais (andar atual: 25)",
                "isTimedQuest": False,
                "daysLeft": None
            }
        ],
        "achievements": [
            {
                "id": 0,
                "name": "Primeiros Passos",
                "description": "Ganhe 15.000 ouros no total.",
                "hasPlayerUnlocked": True,
                "canPlayerSeeDetails": True,
                "showIfPrerequisiteMet": True,
                "hasPrerequisiteAchievement": False
            },
            {
                "id": 1,
                "name": "Cowboy",
                "description": "Ganhe 50.000 ouros no total.",
                "hasPlayerUnlocked": False,
                "canPlayerSeeDetails": True,
                "showIfPrerequisiteMet": True,
                "hasPrerequisiteAchievement": False
            },
            {
                "id": 2,
                "name": "Um Amigo Fiel",
                "description": "Atinja o nível máximo de amizade (10 corações) com alguém.",
                "hasPlayerUnlocked": False,
                "canPlayerSeeDetails": True,
                "showIfPrerequisiteMet": True,
                "hasPrerequisiteAchievement": False
            }
        ],
        "relationships": [
            {
                "npc": {"name": "Abigail", "type": "Villager"},
                "hearts": 6,
                "points": 1520,
                "hasBeenGivenGiftToday": False,
                "giftsGivenToday": 0,
                "giftsGivenThisWeek": 1,
                "isDating": True,
                "isMarried": False
            },
            {
                "npc": {"name": "Robin", "type": "Villager"},
                "hearts": 4,
                "points": 1050,
                "hasBeenGivenGiftToday": True,
                "giftsGivenToday": 1,
                "giftsGivenThisWeek": 2,
                "isDating": False,
                "isMarried": False
            },
            {
                "npc": {"name": "Penny", "type": "Villager"},
                "hearts": 8,
                "points": 2040,
                "hasBeenGivenGiftToday": False,
                "giftsGivenToday": 0,
                "giftsGivenThisWeek": 0,
                "isDating": False,
                "isMarried": False
            },
            {
                "npc": {"name": "Linus", "type": "Villager"},
                "hearts": 5,
                "points": 1300,
                "hasBeenGivenGiftToday": False,
                "giftsGivenToday": 0,
                "giftsGivenThisWeek": 1,
                "isDating": False,
                "isMarried": False
            }
        ]
    },
    "inventory": [
        {"name": "Parsnip", "displayName": "Pastinaca", "qualifiedItemId": "(O)24", "quality": 2, "stackSize": 12},
        {"name": "Cauliflower", "displayName": "Couve-flor", "qualifiedItemId": "(O)190", "quality": 1, "stackSize": 3},
        {"name": "Pufferfish", "displayName": "Baiacu", "qualifiedItemId": "(O)128", "quality": 1, "stackSize": 2},
        {"name": "Quartz", "displayName": "Quartzo", "qualifiedItemId": "(O)80", "quality": 0, "stackSize": 9},
        {"name": "Copper Ore", "displayName": "Minério de Cobre", "qualifiedItemId": "(O)378", "quality": 0, "stackSize": 28},
        {"name": "Wood", "displayName": "Madeira", "qualifiedItemId": "(O)388", "quality": 0, "stackSize": 184},
        {"name": "Stone", "displayName": "Pedra", "qualifiedItemId": "(O)390", "quality": 0, "stackSize": 96},
        {"name": "Copper Hoe", "displayName": "Enxada de Cobre", "qualifiedItemId": "(T)CopperHoe", "quality": 0, "stackSize": 1},
        {"name": "Copper Watering Can", "displayName": "Regador de Cobre", "qualifiedItemId": "(T)CopperWateringCan", "quality": 0, "stackSize": 1},
        {"name": "Copper Pickaxe", "displayName": "Picareta de Cobre", "qualifiedItemId": "(T)CopperPickaxe", "quality": 0, "stackSize": 1},
        {"name": "Axe", "displayName": "Machado", "qualifiedItemId": "(T)Axe", "quality": 0, "stackSize": 1},
        {"name": "Fiberglass Rod", "displayName": "Vara de Fibra de Vidro", "qualifiedItemId": "(T)FiberglassRod", "quality": 0, "stackSize": 1}
    ],
    "mods": [
        {"name": "Stardew Web API", "version": "0.7.0", "uniqueID": "zunderscore.StardewWebApi"}
    ]
}

LOCATIONS_CYCLE = ["Farm", "BusStop", "Town", "Beach", "Forest", "Mountain", "Mine"]
_location_idx = 0


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        print(f"[{time.strftime('%H:%M:%S')}] {self.command} {self.path}")

    def do_GET(self):
        global _location_idx
        path = self.path.split("?")[0]

        # Endpoints de controle para simular deslocamento pelo mapa ao vivo
        if path == "/control/next_location":
            _location_idx = (_location_idx + 1) % len(LOCATIONS_CYCLE)
            new_loc = LOCATIONS_CYCLE[_location_idx]
            GAME_STATE["player"]["location"] = new_loc
            self.reply({"status": "ok", "newLocation": new_loc})
            return
        elif path.startswith("/control/set_location/"):
            target = path.replace("/control/set_location/", "")
            GAME_STATE["player"]["location"] = target
            self.reply({"status": "ok", "location": target})
            return

        # Endpoints oficiais da Stardew Web API
        if path == "/api/v1/mods":
            self.reply(GAME_STATE["mods"])
        elif path == "/api/v1/world":
            self.reply(GAME_STATE["world"])
        elif path == "/api/v1/players/main":
            self.reply(GAME_STATE["player"])
        elif path == "/api/v1/players/main/inventory":
            self.reply(GAME_STATE["inventory"])
        elif path == "/api/v1/npcs":
            self.reply([
                {"name": "Abigail", "type": "Villager"},
                {"name": "Robin", "type": "Villager"},
                {"name": "Penny", "type": "Villager"},
                {"name": "Linus", "type": "Villager"},
                {"name": "Pierre", "type": "Villager"},
            ])
        elif path.startswith("/api/v1/ui/actions/showHudMessage"):
            print(">>> MENSAGEM HUD ENVIADA:", self.path)
            self.reply({"success": True})
        else:
            self.reply({"error": f"Endpoint '{path}' not found"}, 404)

    def do_POST(self):
        self.do_GET()

    def reply(self, body, status=200):
        data = json.dumps(body, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)


if __name__ == "__main__":
    server = ThreadingHTTPServer(("0.0.0.0", 7882), Handler)
    print("=========================================================")
    print(" Stardew Web API Mock ativo em http://0.0.0.0:7882")
    print(" Acesse pelo celular em: http://192.168.3.28:7882")
    print("=========================================================", flush=True)
    server.serve_forever()
