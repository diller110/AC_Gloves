#undef REQUIRE_PLUGIN
#include <vip_core>
#define REQUIRE_PLUGIN
#pragma newdecls required
#include <gloves_oop>
#include <sdktools>
#include <clientprefs>

#define MENU_TEXT 50
#define MENUACTIONS MenuAction_Display|MenuAction_DisplayItem|MenuAction_DrawItem

public Plugin myinfo = {
	name = "AC Gloves", author = "Aircraft(diller110)",
	description = "Set in-game gloves",	version = "1.6", url = "thanks to Franc1sco && Pheonix"
};


GloveHolder gh[MAXPLAYERS + 1];
Menu ModelMenu, QualityMenu;
bool vip_loaded = false;

public void OnPluginStart() {
	char path[256];
	BuildPath(Path_SM, path, sizeof(path), "/configs/ac_gloves.txt");
		
	gg = GloveGlobal();
	gs = GloveStorage();
	
	gg.LoadFromFile(path);
	gs.LoadFromFile(path);
	gs.LoadDefaults(path);
	
	CreateMenus();
	LoadTranslations("ac_gloves.phrases.txt");

	for(int i = 1; i <= MaxClients; i++)
		if(IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && AreClientCookiesCached(i))
			OnClientCookiesCached(i);
			
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);
	
	RegConsoleCmd("sm_gloves", Cmd_ModelsMenu);
	RegConsoleCmd("sm_glove", Cmd_ModelsMenu);
	RegConsoleCmd("sm_gl", Cmd_ModelsMenu);
}

public void OnPluginEnd() {
	for(int i = 1; i <= MaxClients; i++) {
		if(gh[i].IsValid){
			gh[i].Glove = -1;
			gh[i].Dispose();
		}
	}
	if(gs.IsValid) gs.Dispose();
	if(gg.IsValid) gg.Dispose();
}
public void OnAllPluginsLoaded() {
	vip_loaded = LibraryExists("vip_core");
}
public void OnLibraryRemoved(const char[] name) {
	if (StrEqual(name, "vip_core")) vip_loaded = false;
}
public void OnLibraryAdded(const char[] name) {
	if (StrEqual(name, "vip_core")) vip_loaded = true;
}
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	MarkNativeAsOptional("VIP_IsClientVIP");
	return APLRes_Success;
}
public void OnClientCookiesCached(int client) {
	gh[client] = GloveHolder(client, (vip_loaded)?VIP_IsClientVIP(client):true);
	if (!gh[client].IsValid)return;
	gh[client].LoadFromCookie();
	
 	if(IsClientInGame(client) && IsPlayerAlive(client)) {
		if(gh[client].SetGlove()) {
			PrintToChat(client, "%s %t", Tag, "Restored"); //PrintToChat(client, "%s Ваши перчатки восстановлены!", tag1);
		}
	}
}
public void OnClientDisconnect(int client) {
	gh[client].Glove = -1; // Удаляем сами перчатки
	gh[client].Dispose(); // Отчищаем данные игрока
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
	ModelMenu.AddItem("_reset", "Reset");
	ModelMenu.AddItem("_quality", "Quality");
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
}
public int ModelMenuHandler(Menu menu, MenuAction action, int client, int item) {
	switch(action) {
		case MenuAction_Select: {
			char buff[12], buff2[MENU_TEXT]; //, buff3[MENU_TEXT];
			menu.GetItem(item, buff, sizeof(buff));
			if(buff[0] == '_') { // Управляющие пункты
				switch(buff[1]) {
					case 'r': {
						gh[client].ResetGlove();
						menu.Display(client, 40);
					}
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
				if(gg.Random) {
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
				//PrintToChat(client, "%s %s", buff, display);
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
				if(StringToInt(buff) == gh[client].GloveModel()) {
					Format(display, sizeof(display), ">> %s <<", display);
					return RedrawMenuItem(display);
				}
			}
		}
		case MenuAction_DrawItem: {
			static char buff[3];
			menu.GetItem(item, buff, sizeof(buff));
			if(gg.TeamDivided) {
				if(GetClientTeam(client) < 2) {
					if (buff[0] != '_')return ITEMDRAW_RAWLINE;
					if (buff[1] == 'r')return ITEMDRAW_RAWLINE;
				}
			}
		}
		case MenuAction_Display: {
			static char title[128], buff[64];
			if(gg.TeamDivided) {
				int team = GetClientTeam(client);
				if(team<2) {
					Format(buff, sizeof(buff), "%T", "Menu_Title", client);
					Format(title, sizeof(title), "%T", "Menu_NoTeamTitle", client);
					Format(title, sizeof(title), "%s%s", buff, title);
					ReplaceString(title, sizeof(title), "\\n", "\n");
				} else {
			 		switch(team) {
			 			case 2: {
			 				Format(title, MENU_TEXT, "%T", "Menu_Title_T", client);
			 			}
			 			case 3: {
			 				Format(title, MENU_TEXT, "%T", "Menu_Title_CT", client);
			 			}
			 		}
		 		}
		 	} else {
		 		Format(title, MENU_TEXT, "%T", "Menu_Title", client);
		 	}
		 	menu.SetTitle(title);
		}
	}
	return 0;
}
public int SkinMenuHandler(Menu menu, MenuAction action, int client, int item) {
	switch(action) {
		case MenuAction_Select: {
			char buff[16]; //, buff2[MENU_TEXT]; //, buff3[MENU_TEXT];
			menu.GetItem(item, buff, sizeof(buff));
			if(gg.TeamDivided && (buff[1] != 'q' || buff[1] != 'c')) {
				if(GetClientTeam(client) < 2 ) { // Если игрок в спектрах
					//PrintToChat(client, "%s Чтобы выбирать перчатки, нужно находится в команде Т или КТ!", tag1);
					PrintToChat(client, "%s %t", Tag, "Menu_NoTeamWarning");
					ModelMenu.Display(client, 20);
					delete menu;
					return 0;
				}
			}
			if(buff[0] == '_') { // Управляющие пункты
				if(buff[1] == 'r') {
					//char buffs[2][8];
					//ExplodeString(buff, ":", buffs, 2, 8);
					//int model = StringToInt(buffs[1]);
					SaveGlove(client, StringToInt(buff[3]), -2);
					SetGlove(client);
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
				int model = StringToInt(buffs[0]);
				int skin = StringToInt(buffs[1]);
				SaveGlove(client, model, skin, _, true);
				SetGlove(client);
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
				int model = StringToInt(buffs[0]);
				int skin = StringToInt(buffs[1]);
				if(!GloveAccess(client, model, skin))
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
					//PrintToChatAll("%d %d %s for vip", model, skin, title);
					if (title[strlen(title) - 2] == '\n') { // Убираем пробел в последнем пункте
						title[strlen(title) - 2] = '\0';
						Format(title, sizeof(title), "%s (VIP)\n ", title);
					} else Format(title, sizeof(title), "%s (VIP)", title);
					//return RedrawMenuItem(title);
				} else if(limit > 0 && limit != 100) {
					if (title[strlen(title) - 2] == '\n') { // Убираем пробел в последнем пункте
						title[strlen(title) - 2] = '\0';
						Format(title, sizeof(title), "%s (%d%%)\n ", title, limit);
					} else Format(title, sizeof(title), "%s (%d%%)", title, limit);
					//return RedrawMenuItem(title);
				}
				if(model == gh[client].GloveModel() && skin == gh[client].GloveSkin()) {
					if (title[strlen(title) - 2] == '\n') { // Убираем пробел в последнем пункте
						title[strlen(title) - 2] = '\0';
						Format(title, sizeof(title), ">> %s <<\n ", title, limit);
					} else Format(title, sizeof(title), ">>  %s <<", title, limit);
					
				}
				return RedrawMenuItem(title);
			} else {
				switch(buff[1]){
						case 'r':{
							Format(title, 24, "%T", "Menu_Random", client);
						}
						case 'b':{
							Format(title, 24, "%T", "Menu_Back", client);
						}
						case 'c':{
							Format(title, 24, "%T", "Menu_Close", client);
						}
				}
				return RedrawMenuItem(title);
			}
		}
		case MenuAction_Display: {
			static char title[MENU_TEXT];
			if(gg.TeamDivided) {
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
				SaveGlove(client, _, _, 100-25*item);
				SetGlove(client);
				QualityMenu.Display(client, 20);
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
				//PrintToChat(client, "%s %s", buff, display);
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
						Format(display, sizeof(display), "%T", "Menu_Quality0", client);
						if(num==gh[client].GloveQuality) Format(display, sizeof(display), ">> %s <<", display);
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
			Format(title, MENU_TEXT, "%T:", "Menu_QualityTitle", client);
		 	menu.SetTitle(title);
		}
	}
	return 0;
}
public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!IsFakeClient(client) && GetEntProp(client, Prop_Send, "m_bIsControllingBot") != 1) {
		if(gg.SkipCustomArms) {
			static char buff[2];
			GetEntPropString(client, Prop_Send, "m_szArmsModel", buff, sizeof(buff));
			if(buff[0])	return;
		}
		int wear = GetEntPropEnt(client, Prop_Send, "m_hMyWearables");
		if(wear == -1) {
			SetGlove(client);
			//CreateTimer(0.0, FakeTimer, client-100);
		} else {
			if(gg.ThirdPerson) SetEntProp(client, Prop_Send, "m_nBody", 1);
		}
	}
}
public Action FakeTimer(Handle timer, int client) {
	if(client < 0) CreateTimer(0.0, FakeTimer, client+100);
	else SetGlove(client);
	return Plugin_Stop;
}
public Action Cmd_ModelsMenu(int client, int args) {
	ModelMenu.Display(client, 40);
	return Plugin_Handled;
}
stock void SaveGlove(int client, int model = -1, int skin = -1, int quality = -1, bool inform = false) {
	//PrintToServer("SaveGlove %d %d %d %d %d", client, model, skin, quality, inform);
	if (!IsClientConnected(client) && !IsClientInGame(client)) return;
	int team = 0;
	if(gg.TeamDivided) {
		team = GetClientTeam(client);
		if (team < 2 && quality == -1)return;
		team -= 2;
	}
	char buff[8], buff2[MENU_TEXT];
	if(model > 0 && model<=gs.ModelsCount()) {
		IntToString(model, buff, sizeof(buff));
		SetClientCookie(client, gg.ModelCookie(team), buff);
		gh[client].GloveModel(-1, model);
		if(skin != -1 && skin != -2) {
			int limit = GloveAccess(client, model, skin);
			if(limit == 0) {
					gh[client].ResetGlove(false);
					//PrintToChat(client, "%s У вас %sнету доступа\x01 к этим перчаткам!", tag1, clr);
					PrintToChat(client, "%s %t", Tag, "NoAccess", Clr, 1);
			} else {
				char buff3[MENU_TEXT];
				IntToString(skin, buff, sizeof(buff));
				SetClientCookie(client, gg.SkinCookie(team), buff);
				gh[client].GloveSkin(-1, skin);
				if(quality == -1 && gh[client].GloveQuality == -1)
					gh[client].GloveQuality = 100;
				//GetModelName(model, buff2);
				gs.ModelName(model, buff2, sizeof(buff2));
				gs.SkinName(model, skin, buff3, sizeof(buff3));
				//if(inform) PrintToChat(client, "%s Перчатки %s%s | %s \x01установлены.", tag1, clr, buff2, buff3);
				if(inform) PrintToChat(client, "%s %t", Tag, "GloveSave", Clr, buff2, buff3, 1);
				if(limit > 0 && limit != 100) {
					//PrintToChat(client, "%s Качество будет %sограничено%s до %s%d%%%s с этими перчатками.", tag1, clr, 1, clr, limit, 1);
					PrintToChat(client, "%s %t", Tag, "LimitQuality", Clr, 1, Clr, limit, 1);
				}
			}
			//PrintToChat(client, "%s Выбранные вами перчатки %sсохранены\x01 в базу.", tag1, clr);
		} else if(skin == -2){
			gs.ModelName(model, buff2, sizeof(buff2));
			//PrintToChat(client, "%s Рандомный скин для  %s%s \x01установлен.", tag1, clr, buff2);
			PrintToChat(client, "%s %t", Tag, "RandomSet", Clr, buff2, 1);
			IntToString(skin, buff, sizeof(buff));
			SetClientCookie(client, gg.SkinCookie(team), buff);
			gh[client].GloveSkin(-1, skin);
		} else {
			PrintToServer("[GLOVES] Invalid data save! Parameters: %d %d %d %d %d", client, model, skin, quality, inform);
		}
	}
	if(quality != -1) {
		gh[client].GloveQuality = quality;
		IntToString(quality, buff, sizeof(buff));
		SetClientCookie(client, gg.QualityCookie, buff);
		//PrintToChat(client, "%s Выбранное вами качество(%s%d%%\x01) сохранено.", tag1, clr, quality);
		PrintToChat(client, "%s %t", Tag, "QualitySave", Clr, quality, 1);
		if(skin > 0) {
			int limit = GloveAccess(client, gh[client].GloveModel(), gh[client].GloveSkin());
			if(limit == 0) {
				//PrintToChat(client, "%s Выбранное качество не доступно с этими перчатками.", tag1);
				PrintToChat(client, "%s %t", Tag, "RestrictQuality");
			} else if(limit > 0) {
				if(quality>limit) {
					//PrintToChat(client, "%s Выбранное будет %sограничено%s до %s%d%%%s с этими перчатками.", tag1, clr, 1, clr, limit, 1);
					PrintToChat(client, "%s %t", Tag, "LimitQuality2", Clr, 1, Clr, limit, 1);
				}
			}
		}
	}
}
stock void SetGlove(int client, int model = -1, int skin = -1, int wear = -1) {
	int team = 0;
	if (!IsClientConnected(client) || !IsClientInGame(client) || IsFakeClient(client))
		return;
	if(gg.TeamDivided) {
		team = GetClientTeam(client);
		if (team < 2)return;
		team -= 2;
	}
	if(model != -3) {
		if((model == -1 || skin == -1)) {
			if(gh[client].GloveModel() != -1 && gh[client].GloveSkin() != -1) {
				model = gh[client].GloveModel();
				skin = gh[client].GloveSkin();
			} else {
					switch(GetClientTeam(client)){
						case 2: {
							model = gs.DefaultModelT;
							skin = gs.DefaultSkinT;
						}
						case 3: {
							model = gs.DefaultModelCT;
							skin = gs.DefaultSkinCT;
						}
					}
			}
		}
		if(model != -3) {
			int limit = (skin<1)?100:GloveAccess(client, model, skin);
			if(skin == -2) {
				static int tries = 0;
				do {
					skin = gs.RandomSkin(model);
					limit = GloveAccess(client, model, skin);
				} while (tries++ < 10 && (limit == 0));
				if(tries > 9 && limit == 0) {
					//PrintToChat(client, "%s Ошибка! У вас %sнет доступа%s к этим перчаткам.", tag1, clr, 1);
					PrintToChat(client, "%s %t", Tag, "NoAccess", Clr, 1);
					gh[client].ResetGlove();
					SetGlove(client);
					return;
				}
				tries = 0;
			}
			if(wear == -1) {
				if(gh[client].GloveQuality != -1)	wear = gh[client].GloveQuality;
				else wear = 100;
				
				if(limit == 0) {
					//PrintToChat(client, "%s Ошибка! У вас %sнет доступа%s к этим перчаткам.", tag1, clr, 1);
					PrintToChat(client, "%s %t", Tag, "NoAccess", Clr, 1);
					gh[client].ResetGlove();
					SetGlove(client);
					return;
				} else if(limit > 0 && wear > limit) {
					wear = limit;
				}
			}
		}
	}
	gh[client].Glove = -1; // Удаляет перчатки сам

	if(model > 0 && skin > 0) {
		int ent = CreateEntityByName("wearable_item");
		if(ent != -1 && IsWearable(ent)) {
			gh[client].Glove = ent;
			SetEntPropEnt(client, Prop_Send, "m_hMyWearables", ent);
			SetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex", model);
			SetEntProp(ent, Prop_Send,  "m_nFallbackPaintKit", skin);
			SetEntPropFloat(ent, Prop_Send, "m_flFallbackWear", 1.0-wear*0.01); // Качество, больше = хуже
			SetEntProp(ent, Prop_Send, "m_iItemIDLow", 2048); // Что-то важное, вроде может быть любым значением кроме 0
			SetEntProp(ent, Prop_Send, "m_bInitialized", 1); // Убирает "[Wearables (server)(230)] Failed to set model for wearable!"
			SetEntPropEnt(ent, Prop_Data, "m_hParent", client); // Прикрепление к игроку, без этого работать не будет
			SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client); // Прикрепление к игроку, без этого работать не будет
			if(gg.ThirdPerson) {
				SetEntPropEnt(ent, Prop_Data, "m_hMoveParent", client); // Устанавливает для 3 лица
				SetEntProp(client, Prop_Send, "m_nBody", 1); // Убирает стандартные перчатки в 3 лице
			}
			DispatchSpawn(ent);
		}
	} else {
		SetEntProp(client, Prop_Send, "m_nBody", 0);
	}
	int item = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");		
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", -1); 		
	DataPack ph = new DataPack();		
	WritePackCell(ph, EntIndexToEntRef(client));		
	if(IsValidEntity(item))	WritePackCell(ph, EntIndexToEntRef(item));		
	else WritePackCell(ph, -1);		
	CreateTimer(0.0, AddItemTimer, ph, TIMER_FLAG_NO_MAPCHANGE); 
}

stock bool IsWearable(int ent) {
	static char weaponclass[32];
	if(!IsValidEdict(ent)) return false;
	if (!GetEdictClassname(ent, weaponclass, sizeof(weaponclass))) return false;
	if(StrContains(weaponclass, "wearable", false) == -1) return false;
	return true;
}
stock int GloveAccess(int client, int model, int skin) {
	if (model < 0)ThrowError("Wrong model index %d, check code!", model);
	if (skin < 0)ThrowError("Wrong skin index %d, check code!", skin);
	if (model == gs.DefaultModelT && skin == gs.DefaultSkinT)return 100;
	if (model == gs.DefaultModelCT && skin == gs.DefaultSkinCT)return 100;
	int limit = gs.SkinLimit(model, skin);
	if (limit == -1) return 100;
	else if(vip_loaded && VIP_IsClientVIP(client)) return -1; // Игрок вип
	else return limit;
}

