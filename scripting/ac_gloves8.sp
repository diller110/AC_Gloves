#undef REQUIRE_PLUGIN
#include <vip_core>
#define REQUIRE_PLUGIN
#pragma newdecls required
#include <gloves_oop.sp>

#define MENU_TEXT 50
#define MENUACTIONS MenuAction_Display|MenuAction_DisplayItem|MenuAction_DrawItem


public Plugin myinfo = {
	name = "AC Gloves", author = "Aircraft(diller110)",
	description = "Set in-game gloves",	version = "1.6 beta1", url = "thanks to Franc1sco && Pheonix"
};

GloveHolder gh[MAXPLAYERS + 1] = {view_as<GloveHolder>(INVALID_DYNAMIC_OBJECT), ...};
Menu ModelMenu, QualityMenu, DefaultMenu;
bool ready = false;

public void OnPluginStart() {
	LoadTranslations("ac_gloves.phrases.txt");
	
	StartLoading();

	RegConsoleCmd("sm_gloves", Cmd_ModelsMenu);
	RegConsoleCmd("sm_glove", Cmd_ModelsMenu);
	RegConsoleCmd("sm_gl", Cmd_ModelsMenu);
	
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
}
void StartLoading() {
	char path[256];
	BuildPath(Path_SM, path, sizeof(path), "/configs/ac_gloves.txt");
		
	gg = GloveGlobal();
	
	if(gg.IsValid) {
		gg.LoadFromFile(path);
		
		gs = GloveStorage();
		gs.LoadFromFile(path);
		gs.LoadDefaults(path);
		ready = true;
		CreateMenus();
		
		for(int i = 1; i <= MaxClients; i++)
			if(IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && AreClientCookiesCached(i))
				OnClientCookiesCached2(i);
	} else {
		LogError("[GLOVES] Failed to create GlovesGlobal's Dynamic object. (gg.IsValid == false)");
	}
}
public void OnPluginEnd() {
	if(ready) {
		for(int i = 0; i <= MAXPLAYERS; i++) {
			if(gh[i].IsValid) {
				gh[i].GloveEntity = -1;
				PrintDebug("Dispose GloveHolder[%d]", i);
				gh[i].Dispose();
				gh[i] = view_as<GloveHolder>(INVALID_DYNAMIC_OBJECT);
			}
		}
		if(gg.IsValid) {
			gg.Dispose();
			gg = view_as<GloveGlobal>(INVALID_DYNAMIC_OBJECT);
		}
		if(gs.IsValid) {
			gs.Dispose();
			gs = view_as<GloveStorage>(INVALID_DYNAMIC_OBJECT);
		}
	}
}
public void OnAllPluginsLoaded() {
	if(ready) gg.VipLoaded = LibraryExists("vip_core");
}
public void OnLibraryRemoved(const char[] name) {
	if (ready && StrEqual(name, "vip_core")) gg.VipLoaded = false;
}
public void OnLibraryAdded(const char[] name) {
	if (ready && StrEqual(name, "vip_core"))	gg.VipLoaded = true;
}
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	MarkNativeAsOptional("VIP_IsClientVIP");
	return APLRes_Success;
}
public Action Event_PlayerTeam(Event event,char[] name,  bool dontBroadcast) { 
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(ready && !gh[client].IsValid && (event.GetInt("oldteam") == 0) && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client) && AreClientCookiesCached(client)) {
		OnClientCookiesCached2(client);
	}
	return Plugin_Changed;
}
void OnClientCookiesCached2(int client, bool recreate = true) {
	if (!ready || !gg.IsValid) return;
	if (client < 1 && !IsClientConnected(client)) return;
	
	if(gh[client].IsValid) {
		gh[client].GloveEntity = -1;
		gh[client].Dispose();
	}
	gh[client] = GloveHolder(client, (gg.VipLoaded)?VIP_IsClientVIP(client):true);
	if (!gh[client].IsValid) {
		if(recreate && IsClientConnected(client) && !IsFakeClient(client)) {
			CreateTimer(3.0, Timer_ReCreateHolder, client);
		}
		LogError("[GLOVES] Failed to create GloveHolder for client: %d", client);
	} else {
		gh[client].LoadFromCookie();
	 	if(IsPlayerAlive(client)) {
			if(gh[client].SetGlove()) {
				PrintToChat(client, "%s %t", Tag, "Restored");
			}
		}
	}
}
public Action Timer_ReCreateHolder(Handle timer, int client) {
	if(!gh[client].IsValid && IsClientConnected(client) && IsClientInGame(client)) {
		OnClientCookiesCached2(client, false);
	}
	return Plugin_Handled;
}
public void OnClientDisconnect(int client) {
	if(ready && gh[client].IsValid) {
		gh[client].GloveEntity = -1;
		gh[client].Dispose();
	}
}
public void CreateMenus() {
	char buff[3][MENU_TEXT];
	
	ModelMenu = CreateMenu(ModelMenuHandler, MENUACTIONS);
	ModelMenu.SetTitle("Glove Menu:");
	int count = gs.ModelsCount();
	for (int i = 0; i < count; i++) {
		gs.GetMemberNameByIndex(i, buff[0], sizeof(buff[]));
		int ind = StringToInt(buff[0]);
		gs.ModelName(ind, buff[1], sizeof(buff[]));
		gs.ModelIcon(ind, buff[2], sizeof(buff[]));
		if(buff[1][0]) {
	 		Format(buff[2], sizeof(buff[]), "%s %s%s", buff[2], buff[1], (i==count-1)?"\n ":"");
		}
		ModelMenu.AddItem(buff[0], buff[2]);
	}
	ModelMenu.AddItem("_quality", "Quality");
	ModelMenu.AddItem("_reset", "Reset");
	ModelMenu.AddItem("_close", "Close");
	ModelMenu.Pagination = MENU_NO_PAGINATION;
	ModelMenu.ExitButton = false;
	
	QualityMenu = CreateMenu(QualityMenuHandler, MENUACTIONS);
	QualityMenu.SetTitle("Quality:");
	QualityMenu.AddItem("100", "100%");
	QualityMenu.AddItem("75", "75%");
	QualityMenu.AddItem("50", "50%");
	QualityMenu.AddItem("25", "25%");
	QualityMenu.AddItem("0", "0%");
	QualityMenu.AddItem("_back", "Back");
	QualityMenu.AddItem("_close", "Close");
	QualityMenu.Pagination = MENU_NO_PAGINATION;
	QualityMenu.ExitButton = false;
	
	DefaultMenu = CreateMenu(DefaultMenuHandler, MENUACTIONS);
	DefaultMenu.SetTitle("Default:");
	DefaultMenu.AddItem("any", "Default Any");
	DefaultMenu.AddItem("vip", "Default Vip");
	DefaultMenu.AddItem("none", "No gloves");
	DefaultMenu.AddItem("_back", "Back");
	DefaultMenu.AddItem("_close", "Close");
	DefaultMenu.Pagination = MENU_NO_PAGINATION;
	DefaultMenu.ExitButton = false;
}
public int ModelMenuHandler(Menu menu, MenuAction action, int client, int item) {
	switch(action) {
		case MenuAction_Select: {
			char buff[12], buff2[MENU_TEXT]; //, buff3[MENU_TEXT];
			menu.GetItem(item, buff, sizeof(buff));
			if(buff[0] == '_') { // Управляющие пункты
				switch(buff[1]) {
					case 'r': DefaultMenu.Display(client, 30);
					case 'q': QualityMenu.Display(client, 20);
					case 'c': {	}
				}
			} else { // Выбраны перчатки
				int model = StringToInt(buff);
				int skins = gs.SkinsCount(model)+2;
				Dynamic mdl = gs.GetDynamic(buff);
				Menu SkinMenu = CreateMenu(SkinMenuHandler, MENUACTIONS);
				
				gs.ModelName(model, buff2, sizeof(buff2));
				SkinMenu.SetTitle(buff2);
				if(gg.IsValid && gg.Random) {
					Format(buff2, sizeof(buff2), "_r:%d", model);
					SkinMenu.AddItem(buff2, "Menu Random");
				}
				for (int i = 2; i < skins; i++) {
					mdl.GetMemberNameByIndex(i, buff, sizeof(buff));
					int ind = StringToInt(buff);
					Format(buff, sizeof(buff), "%d:%d", model, ind);
					gs.SkinName(model, ind, buff2, sizeof(buff2));
					if(i==skins-1) Format(buff2, sizeof(buff2), "%s\n ", buff2);
					SkinMenu.AddItem(buff, buff2);
				}
				SkinMenu.AddItem("_back", "Back");
				SkinMenu.AddItem("_close", "Close");
				SkinMenu.Pagination = MENU_NO_PAGINATION;
				SkinMenu.ExitButton = false;
				SkinMenu.Display(client, 40);
			}
		}
		case MenuAction_DisplayItem: {
			static char buff[16], display[64];
			menu.GetItem(item, buff, sizeof(buff), _, display, sizeof(display));
			if(buff[0] == '_') {
				switch(buff[1]){
						case 'r':{
							Format(display, sizeof(display), "%T", "Menu_Standart", client);
						}
						case 'q':{
							Format(display, sizeof(display), "%T", "Menu_Quality", client);
						}
						case 'c':{
							Format(display, sizeof(display), "%T", "Menu_Close", client);
						}
				}
				return RedrawMenuItem(display);
			} else {
				if(StringToInt(buff) == gh[client].GetGloveModel()) {
					Format(display, sizeof(display), ">> %s <<", display);
					return RedrawMenuItem(display);
				}
			}
		}
		case MenuAction_DrawItem: {
			static char buff[3];
			menu.GetItem(item, buff, sizeof(buff));
			if(gg.IsValid && gg.TeamDivided) {
				if(GetClientTeam(client) < 2) {
					if (buff[0] != '_')return ITEMDRAW_RAWLINE;
					if (buff[1] == 'r')return ITEMDRAW_RAWLINE;
				}
			}
		}
		case MenuAction_Display: {
			static char title[128], buff[64];
			if(gg.IsValid && gg.TeamDivided) {
				int team = GetClientTeam(client);
				if(team<2) {
					Format(buff, sizeof(buff), "%T", "Menu_Title", client);
					Format(title, sizeof(title), "%T", "Menu_NoTeamTitle", client);
					Format(title, sizeof(title), "%s%s", buff, title);
					ReplaceString(title, sizeof(title), "\\n", "\n");
				} else {
			 		switch(team) {
			 			case 2: {
			 				Format(title, sizeof(title), "%T", "Menu_Title_T", client);
			 			}
			 			case 3: {
			 				Format(title, sizeof(title), "%T", "Menu_Title_CT", client);
			 			}
			 		}
		 		}
		 	} else {
		 		Format(title, sizeof(title), "%T", "Menu_Title", client);
		 	}
		 	menu.SetTitle(title);
		}
	}
	return 0;
}
public int SkinMenuHandler(Menu menu, MenuAction action, int client, int item) {
	switch(action) {
		case MenuAction_Select: {
			char buff[16];
			menu.GetItem(item, buff, sizeof(buff));
			if(gg.IsValid && gg.TeamDivided && (buff[1] != 'q' || buff[1] != 'c')) {
				if(GetClientTeam(client) < 2 ) { // Если игрок в спектрах
					PrintToChat(client, "%s %t", Tag, "Menu_NoTeamWarning");
					ModelMenu.Display(client, 20);
					delete menu;
					return 0;
				}
			}
			if(buff[0] == '_') { // Управляющие пункты
				if(buff[1] == 'r') {
					gh[client].SaveGlove(StringToInt(buff[3]), -2)
					gh[client].SetGlove();
					menu.Display(client, 40);
				} else if(buff[1] == 'b') {
					ModelMenu.Display(client, 40);
					delete menu;
				} else {
					delete menu;
				}
			} else { // Выбраны перчатки
				char buffs[2][8];
				ExplodeString(buff, ":", buffs, 2, 8);
				gh[client].SaveGlove(StringToInt(buffs[0]), StringToInt(buffs[1]), _, true);
				gh[client].SetGlove();
				menu.Display(client, 40);
			}
		}
		case MenuAction_End: {
			if(client != MenuEnd_Selected && menu != INVALID_HANDLE)
				delete menu;
		}
		case MenuAction_DrawItem: {
			static char buff[16];
			menu.GetItem(item, buff, sizeof(buff));
			if(buff[0] != '_') {
				static char buffs[2][8];
				ExplodeString(buff, ":", buffs, 2, 8);
				if(!GloveAccess(client, StringToInt(buffs[0]), StringToInt(buffs[1])))
					return ITEMDRAW_DISABLED;
			}
		}
		case MenuAction_DisplayItem: {
			char buff[16], title[MENU_TEXT]
			//menu.GetItem(item, buff, sizeof(buff));
			menu.GetItem(item, buff, sizeof(buff), _, title, sizeof(title));
			if(buff[0] != '_') {
				static char buffs[2][8];
				ExplodeString(buff, ":", buffs, 2, 8);
				int model = StringToInt(buffs[0]);
				int skin = StringToInt(buffs[1]);
				int limit = GloveAccess(client, model, skin);
				
				if(limit == 0) {
					if (title[strlen(title) - 2] == '\n') { // Убираем пробел в последнем пункте
						title[strlen(title) - 2] = '\0';
						Format(title, sizeof(title), "%s (VIP)\n ", title);
					} else Format(title, sizeof(title), "%s (VIP)", title);
				} else if(limit > 0 && limit != 100) {
					if (title[strlen(title) - 2] == '\n') { // Убираем пробел в последнем пункте
						title[strlen(title) - 2] = '\0';
						Format(title, sizeof(title), "%s (%d%%)\n ", title, limit);
					} else Format(title, sizeof(title), "%s (%d%%)", title, limit);
				}
				if(model == gh[client].GetGloveModel() && skin == gh[client].GetGloveSkin()) {
					if (title[strlen(title) - 2] == '\n') { // Убираем пробел в последнем пункте
						title[strlen(title) - 2] = '\0';
						Format(title, sizeof(title), ">> %s <<\n ", title, limit);
					} else Format(title, sizeof(title), ">>  %s <<", title, limit);
					
				}
				return RedrawMenuItem(title);
			} else {
				switch(buff[1]){
						case 'r':{
							if(gh[client].GetGloveSkin() == -2) {
								Format(title, sizeof(title), ">> %T <<\n ", "Menu_Random", client);
							} else Format(title, sizeof(title), "%T\n ", "Menu_Random", client);
						}
						case 'b':{
							Format(title, sizeof(title), "%T", "Menu_Back", client);
						}
						case 'c':{
							Format(title, sizeof(title), "%T", "Menu_Close", client);
						}
				}
				return RedrawMenuItem(title);
			}
		}
		case MenuAction_Display: {
			static char title[MENU_TEXT];
			if(gg.IsValid && gg.TeamDivided) {
				int team = GetClientTeam(client);
				menu.GetTitle(title, sizeof(title));
				if (title[strlen(title) - 1] == ')')return 0;
				if(team==2){
					Format(title, sizeof(title), "%s (T)", title);
				} else {
					Format(title, sizeof(title), "%s (CT)", title);
				}
				menu.SetTitle(title);
		 	}		 	
		}
	}
	return 0;
}
public int QualityMenuHandler(Menu menu, MenuAction action, int client, int item) {
	switch(action) {
		case MenuAction_Select: {
			if(item<5) {
				gh[client].SaveGlove(_, _, 100-25*item);
				gh[client].SetGlove();
				menu.Display(client, 20);
			} else {
				char buff[8];
				menu.GetItem(item, buff, sizeof(buff));
				if(buff[1] == 'b') { // Управляющие пункты
					ModelMenu.Display(client, 40);
				}
			}
		}
		case MenuAction_DisplayItem: {
			static char buff[16], display[64];
			menu.GetItem(item, buff, sizeof(buff), _, display, sizeof(display));
			if(buff[0] == '_') {
				switch(buff[1]){
						case 'b':{
							Format(display, sizeof(display), "%T", "Menu_Back", client);
						}
						case 'c':{
							Format(display, sizeof(display), "%T", "Menu_Close", client);
						}
				}
			} else {
				int num = StringToInt(buff);
				switch(num) {
					case 0: {	
						if(num==gh[client].GloveQuality) Format(display, sizeof(display), ">> %T <<\n ", "Menu_Quality0", client, display);
						else Format(display, sizeof(display), "%T\n ", "Menu_Quality0", client);
					}
					case 25: {
						Format(display, sizeof(display), "%T", "Menu_Quality25", client);
						if(num==gh[client].GloveQuality) Format(display, sizeof(display), ">> %s <<", display);
					}
					case 50: {
						Format(display, sizeof(display), "%T", "Menu_Quality50", client);
						if(num==gh[client].GloveQuality) Format(display, sizeof(display), ">> %s <<", display);
					}
					case 75: {
						Format(display, sizeof(display), "%T", "Menu_Quality75", client);
						if(num==gh[client].GloveQuality) Format(display, sizeof(display), ">> %s <<", display);
					}
					case 100: {
						Format(display, sizeof(display), "%T", "Menu_Quality100", client);
						if(num==gh[client].GloveQuality) Format(display, sizeof(display), ">> %s <<", display);
					}
				}
			}
			return RedrawMenuItem(display);
		}
		case MenuAction_Display: {
			char title[MENU_TEXT];
			Format(title, sizeof(title), "%T:", "Menu_QualityTitle", client);
		 	menu.SetTitle(title);
		}
	}
	return 0;
}
public int DefaultMenuHandler(Menu menu, MenuAction action, int client, int item) {
	if (!ready)return 0;
	switch(action) {
		case MenuAction_Select: {
			char buff[12];
			menu.GetItem(item, buff, sizeof(buff));
			if(buff[0] == '_') { // Управляющие пункты
				switch(buff[1]) {
					case 'b': ModelMenu.Display(client, 40);
					case 'c': {	}
				}
			} else {
				switch(buff[0]) {
					case 'a': {
						gh[client].ResetGlove(_, _, "Any");
					}
					case 'v': {
						gh[client].ResetGlove();
					}
					case 'n': {
						gh[client].ResetGlove(true);
					}
				}
				gh[client].SetGlove();
				menu.Display(client, 30);
			}
		}
		case MenuAction_DisplayItem: {
			static char buff[16], display[64];
			menu.GetItem(item, buff, sizeof(buff), _, display, sizeof(display));
			if(buff[0] == '_') {
				switch(buff[1]){
						case 'b':{
							Format(display, sizeof(display), "%T", "Menu_Back", client);
						}
						case 'c':{
							Format(display, sizeof(display), "%T", "Menu_Close", client);
						}
				}
			} else {
				switch(buff[0]) {
					case 'a': {
						Format(display, sizeof(display), "%T", "Default_Any", client);
					}
					case 'v': {
						Format(display, sizeof(display), "%T", "Default_Vip", client);
					}
					case 'n': {
						Format(display, sizeof(display), "%T\n ", "Default_None", client);
					}
				}
			}
			return RedrawMenuItem(display);
		}
		case MenuAction_DrawItem: {
			static char buff[3];
			menu.GetItem(item, buff, sizeof(buff));
			if(gg.IsValid) {
				if(gg.VipDefaults) {
					if(gg.VipLoaded && !gh[client].Vip) {
						if (buff[0] == 'v') return ITEMDRAW_DISABLED;
					}
				} else {
					if (buff[0] == 'v') return ITEMDRAW_RAWLINE;
				}
			}
		}
		case MenuAction_Display: {
			static char title[MENU_TEXT];
			Format(title, sizeof(title), "%T:", "Menu_Standart", client);
			menu.SetTitle(title);		 	
		}
	}
	return 0;
}
public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	if (!ready || !gg.IsValid) return;
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!IsFakeClient(client) && GetEntProp(client, Prop_Send, "m_bIsControllingBot") != 1) {
		if(gg.SkipCustomArms) {
			static char buff[2];
			GetEntPropString(client, Prop_Send, "m_szArmsModel", buff, sizeof(buff));
			if(buff[0])	return;
		}
		int wear = GetEntPropEnt(client, Prop_Send, "m_hMyWearables");
		if(wear == -1) {
			//if(gh[client].IsValid) gh[client].SetGlove();
			CreateTimer(0.0, FakeTimer, client-100);
		} else {
			if(gg.ThirdPerson) SetEntProp(client, Prop_Send, "m_nBody", 1);
		}
	}
}
public Action FakeTimer(Handle timer, int client) {
	if(client < 0) CreateTimer(0.0, FakeTimer, client+100);
	else if(gh[client].IsValid) gh[client].SetGlove();
	return Plugin_Stop;
}
public Action Cmd_ModelsMenu(int client, int args) {
	if(ready) {
		ModelMenu.Display(client, 40);
	} else ReplyToCommand(client, "Gloves not ready.");
	return Plugin_Handled;
}
