#undef REQUIRE_PLUGIN
#include <vip_core>
#define REQUIRE_PLUGIN
#pragma newdecls required
#include <sdktools>
#include <clientprefs>
#define MENU_TEXT 50
#define ARRAY_SIZE 96
#define MENUACTIONS MenuAction_Display|MenuAction_DisplayItem|MenuAction_DrawItem
/* 60% магии / 40% веры 
 *TODO:
 * 1. 50% Ограничение по vip r1ko
 * 2. ✓ Рандомный скин 
 * 3. ✓ Дефолтный скин для каждой команды
 * 4. ✓ Перевод
 */
public Plugin myinfo = {
	name = "AC Gloves", author = "Aircraft(diller110)",
	description = "Set in-game gloves",	version = "1.3", url = "thanks to Franc1sco && Pheonix"
};

char tag1[16];
ArrayList alModels;
Menu ModelMenu, QualityMenu;
int		clr,
		limit_type,
		random,
		t_default_model,
		t_default_skin,
		ct_default_model,
		ct_default_skin,
		gloves[MAXPLAYERS + 1] = {-1, ...},
		glove_Type[MAXPLAYERS + 1] = { -1, ...},
		glove_Skin[MAXPLAYERS + 1] = { -1, ...},
		glove_Quality[MAXPLAYERS + 1] =  { -1, ... };
bool 	vip_loaded = false;
Handle	ck_Glove_Type = INVALID_HANDLE,
		ck_Glove_Skin = INVALID_HANDLE,
		ck_Glove_Quality = INVALID_HANDLE;
public void OnPluginStart() {
	alModels = new ArrayList(ARRAY_SIZE);
	LoadKV();
	CreateMenus();
	
	//ck_Glove_Type = RegClientCookie("AcGloveType7", "", CookieAccess_Private);
	ck_Glove_Type = RegClientCookie("AcGloveType7", "", CookieAccess_Public);
	ck_Glove_Skin = RegClientCookie("AcGloveSkin7", "", CookieAccess_Private);
	ck_Glove_Quality = RegClientCookie("AcGloveQuality7", "", CookieAccess_Private);
	
	for(int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && !IsFakeClient(i) && AreClientCookiesCached(i))
			OnClientCookiesCached(i);
			
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	
	RegConsoleCmd("sm_gloves", Cmd_ModelsMenu);
	RegConsoleCmd("sm_glove", Cmd_ModelsMenu);
	RegConsoleCmd("sm_gl", Cmd_ModelsMenu);
}
public void OnPluginEnd() {
	for(int i = 1; i <= MaxClients; i++)
		if(gloves[i] != -1 && IsWearable(gloves[i])) {
			if(IsClientConnected(i) && IsPlayerAlive(i)) {
				SetEntPropEnt(i, Prop_Send, "m_hMyWearables", -1);
				//PrintToChat(i, "%s Ваши перчатки были удалены в связи с отключением плагина.", tag1);
			}
			AcceptEntityInput(gloves[i], "Kill");
		}
}
public void OnAllPluginsLoaded() {
	vip_loaded = LibraryExists("vip_core");
}
public void OnLibraryRemoved(const char[] name) {
	if (StrEqual(name, "vip_core")) {
		vip_loaded = false;
	}
}
public void OnLibraryAdded(const char[] name) {
	if (StrEqual(name, "vip_core"))	{
		vip_loaded = true;
	}
}
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	MarkNativeAsOptional("VIP_IsClientVIP");
	return APLRes_Success;
}
public void OnClientCookiesCached(int client) {
	char buff[12];
	GetClientCookie(client, ck_Glove_Type, buff, sizeof(buff));
	int type = StringToInt(buff);
	GetClientCookie(client, ck_Glove_Skin, buff, sizeof(buff));
	int skin = StringToInt(buff);
	GetClientCookie(client, ck_Glove_Quality, buff, sizeof(buff));
	int quality = StringToInt(buff);
	
	if(skin == 0 || skin == -1){
		glove_Type[client] = -1;
		glove_Skin[client] = -1;
		glove_Quality[client] = -1;
	} else {
		glove_Type[client] = type;
		glove_Skin[client] = skin;
		if(quality<0 || quality >100) glove_Quality[client] = 100; 
		else glove_Quality[client] = quality;
		if(IsClientInGame(client) && IsPlayerAlive(client)) {
			SetGlove(client);
			//PrintToChat(client, "%s Ваши перчатки восстановлены!", tag1);
			PrintToChat(client, "%s %t", tag1, "Restored");
		}
	}
}
public void OnClientDisconnect(int client) {
	if(IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client)) {
		int wear = GetEntPropEnt(client, Prop_Send, "m_hMyWearables");
		if(wear != -1 && IsWearable(wear)) {
			AcceptEntityInput(wear, "Kill");
			if (wear == gloves[client])gloves[client] = -1;
		}
	}
	if(gloves[client] != -1 && IsWearable(gloves[client])) {
		AcceptEntityInput(gloves[client], "Kill");
	}
	gloves[client] = -1
	glove_Type[client] = -1;
	glove_Skin[client] = -1;
	glove_Quality[client] = -1;
}
public void LoadKV() {
	KeyValues kv = new KeyValues("Gloves");
	char confPath[256];
	BuildPath(Path_SM, confPath, sizeof(confPath), "/configs/ac_gloves.txt");
	if(kv.ImportFromFile(confPath)) {
		kv.Rewind();
		kv.GetString("tag", tag1, sizeof(tag1), "GL");
		clr = kv.GetNum("color", 11);
		if(clr < 1 || clr > 16) clr = 11;
		Format(tag1, sizeof(tag1), "[%s%s\x01]", clr, tag1);
		limit_type = kv.GetNum("limit_type", 1);
		if(limit_type < 1 || limit_type > 2 )limit_type = 1;
		random = kv.GetNum("random", 1);
		t_default_model = kv.GetNum("t_default_model", -1);
		t_default_skin = kv.GetNum("t_default_skin", -1);
		ct_default_model = kv.GetNum("ct_default_model", -1);
		ct_default_skin = kv.GetNum("ct_default_skin", -1);
		if(kv.JumpToKey("Models", false)) {
			alModels.Push(0);
			if(kv.GotoFirstSubKey(true)){
				char buff[96];
				do {
					int num = GetModelsCount()+1;
					alModels.Set(0, num);
					kv.GetSectionName(buff, sizeof(buff));
					alModels.Push(StringToInt(buff));
					kv.GetString("name", buff, sizeof(buff));
					alModels.PushString(buff);
					kv.GetString("icon", buff, 8);
					alModels.PushString(buff);
					kv.GetString("model", buff, sizeof(buff));
					alModels.PushString(buff);
					alModels.Push(0);
					if(kv.JumpToKey("skins", false)) {
						if(kv.GotoFirstSubKey(true)) {
							char buff2[96];
							do {
								alModels.Set(GetModelPos(num)+4, alModels.Get(GetModelPos(num)+4)+1);
								kv.GetSectionName(buff2, sizeof(buff2));
								alModels.Push(StringToInt(buff2));
								kv.GetString("name", buff2, sizeof(buff2));
								alModels.PushString(buff2);
								alModels.Push(kv.GetNum("limit", 0));
							} while (kv.GotoNextKey(true));
							kv.GoBack();
						} else {
							SetFailState("Failed to load config file: No skins found for %d's model!", alModels.Get(GetModelPos(num)+1));
						}
						kv.GoBack();
					} else {
						SetFailState("Failed to load config file: No skins setting for %d's model!", alModels.Get(GetModelPos(num)+1));
					}
				} while (kv.GotoNextKey(true));
			} else {
				SetFailState("Failed to load config file: No models found!");
			}
		} else {
			SetFailState("Failed to load config file: No models setting!");
		}
	} else {
		SetFailState("Failed to load config file!");
	}
	/* Translation load */
	LoadTranslations("ac_gloves.phrases.txt");
	PrintToServer("[GLOVES] %d models loaded!", GetModelsCount());
	delete kv;
	
}
public void CreateMenus() {
	char buff[8], buff2[MENU_TEXT], buff3[8];
	ModelMenu = CreateMenu(ModelMenuHandler);
	Format(buff2, sizeof(buff2), "%T", "Menu_Title", LANG_SERVER);
	ModelMenu.SetTitle(buff2);
	int count = GetModelsCount();
	for (int i = 1; i <= count; i++) {
		IntToString(i, buff, sizeof(buff));
		GetModelName(i, buff2);
		GetModelIcon(i, buff3);
		if(buff3[0]) {
	 		Format(buff2, sizeof(buff2), "%s %s%s", buff3, buff2, (i==count)?"\n ":"");
		}
		ModelMenu.AddItem(buff, buff2);
	}
	Format(buff2, sizeof(buff2), "%T", "Menu_Standart", LANG_SERVER);
	ModelMenu.AddItem("_reset", buff2);
	Format(buff2, sizeof(buff2), "%T", "Menu_Quality", LANG_SERVER);
	ModelMenu.AddItem("_quality", buff2);
	Format(buff2, sizeof(buff2), "%T", "Menu_Close", LANG_SERVER);
	ModelMenu.AddItem("_close", buff2);
	ModelMenu.Pagination = MENU_NO_PAGINATION;
	ModelMenu.ExitButton = false;
	
	QualityMenu = CreateMenu(QualityMenuHandler);
	Format(buff2, sizeof(buff2), "%T", "Menu_QualityTitle", LANG_SERVER);
	QualityMenu.SetTitle(buff2);
	Format(buff2, sizeof(buff2), "%T", "Menu_Quality100", LANG_SERVER);
	QualityMenu.AddItem("100", buff2);
	Format(buff2, sizeof(buff2), "%T", "Menu_Quality75", LANG_SERVER);
	QualityMenu.AddItem("75", buff2);
	Format(buff2, sizeof(buff2), "%T", "Menu_Quality50", LANG_SERVER);
	QualityMenu.AddItem("50", buff2);
	Format(buff2, sizeof(buff2), "%T", "Menu_Quality25", LANG_SERVER);
	QualityMenu.AddItem("25", buff2);
	Format(buff2, sizeof(buff2), "%T", "Menu_Quality0", LANG_SERVER);
	QualityMenu.AddItem("0", buff2);
	//QualityMenu.AddItem("", "123\n123", ITEMDRAW_IGNORE       );
	Format(buff2, sizeof(buff2), "%T", "Menu_Back", LANG_SERVER);
	QualityMenu.AddItem("back", buff2);
	Format(buff2, sizeof(buff2), "%T", "Menu_Close", LANG_SERVER);
	QualityMenu.AddItem("close", buff2);
	QualityMenu.Pagination = MENU_NO_PAGINATION;
	QualityMenu.ExitButton = false;
}
public int ModelMenuHandler(Menu menu, MenuAction action, int client, int item) {
	if (action == MenuAction_Select) {
		char buff[8], buff2[MENU_TEXT], buff3[MENU_TEXT];
		menu.GetItem(item, buff, sizeof(buff));
		if(buff[0] == '_') { // Управляющие пункты
			if(buff[1] == 'r') {
				ResetGlove(client);
				menu.Display(client, 40);
			} else if(buff[1] == 'q'){
				QualityMenu.Display(client, 20);
			} else {
				// Закроется само
			}
		} else { // Выбраны перчатки
			int model = StringToInt(buff);
			GetModelName(model, buff2);
			int skins = GetSkinsCount(model);
			Menu SkinMenu = CreateMenu(SkinMenuHandler, MENUACTIONS);
			Format(buff3, sizeof(buff3), "%s:", buff2);
			SkinMenu.SetTitle(buff3);
			if(random) {
				Format(buff, sizeof(buff), "_r:%d", model);
				Format(buff2, sizeof(buff2), "%T", "Menu_Random", LANG_SERVER);
				SkinMenu.AddItem(buff, buff2);
			}
			for (int i = 1; i <= skins; i++) {
				Format(buff, sizeof(buff), "%d:%d", model, i);
				GetSkinName(model, i, buff2);
				if(i==skins) Format(buff2, sizeof(buff2), "%s\n ", buff2);
				SkinMenu.AddItem(buff, buff2);
			}
			Format(buff2, sizeof(buff2), "%T", "Menu_Back", LANG_SERVER);
			SkinMenu.AddItem("_back", buff2);
			SkinMenu.Pagination = MENU_NO_PAGINATION;
			SkinMenu.ExitButton = false;
			SkinMenu.Display(client, 40);
		}
	}	
}
public int SkinMenuHandler(Menu menu, MenuAction action, int client, int item) {
	switch(action) {
		case MenuAction_Select: {
			char buff[16], buff2[MENU_TEXT]; //, buff3[MENU_TEXT];
			menu.GetItem(item, buff, sizeof(buff));
			if(buff[0] == '_') { // Управляющие пункты
				if(buff[1] == 'r') {
					char buffs[2][8];
					ExplodeString(buff, ":", buffs, 2, 8);
					int model = StringToInt(buffs[1]);
					GetModelName(model, buff2);
					//PrintToChat(client, "%s Рандомный скин для  %s%s \x01установлен.", tag1, clr, buff2);
					PrintToChat(client, "%s %t", tag1, "RandomSet", clr, buff2, 1);
					SaveGlove(client, model, -2);
					SetGlove(client);
					menu.Display(client, 40);
				} else if(buff[1] == 'b') {
					ModelMenu.Display(client, 40);
				} else {
					if(menu != INVALID_HANDLE) {
						delete menu;
					}
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
			char buff[16];
			menu.GetItem(item, buff, sizeof(buff));
			if(buff[0] != '_') {
				char buffs[2][8];
				ExplodeString(buff, ":", buffs, 2, 8);
				int model = StringToInt(buffs[0]);
				int skin = StringToInt(buffs[1]);
				if(!GloveAccess(client, model, skin))
					return ITEMDRAW_DISABLED;
			}
		}
		case MenuAction_DisplayItem: {
			char buff[16];
			menu.GetItem(item, buff, sizeof(buff));
			if(buff[0] != '_') {
				char buffs[2][8];
				ExplodeString(buff, ":", buffs, 2, 8);
				int model = StringToInt(buffs[0]);
				int skin = StringToInt(buffs[1]);
				if(GetSkinLimit(model, skin)) {
					char title[MENU_TEXT];
					menu.GetItem(item, buff, sizeof(buff), _, title, sizeof(title));
					//PrintToChatAll("%d %d %s for vip", model, skin, title);
					Format(title, sizeof(title), "%s (VIP)", title);
					return RedrawMenuItem(title);
				}
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
			} else ModelMenu.Display(client, 40);
		}
		case MenuAction_DrawItem: { // Заготовка для ограничения по качеству
			// PrintToChatAll("Drawitem");
		}
	}
	return 0;
}
public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	/*
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!IsFakeClient(client) && GetEntProp(client, Prop_Send, "m_bIsControllingBot") != 1) {
		int wear = GetEntPropEnt(client, Prop_Send, "m_hMyWearables");
		if(wear != -1 && IsWearable(wear)) {
			PrintToChat(client, "removed");
			//SetEntPropEnt(client, Prop_Send, "m_hMyWearables", -1);
		}
	}
	*/
}
public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!IsFakeClient(client) && GetEntProp(client, Prop_Send, "m_bIsControllingBot") != 1) {
		int wear = GetEntPropEnt(client, Prop_Send, "m_hMyWearables");
		if(wear == -1) {
			//PrintToChat(client, "Gloves don't exist");
			CreateTimer(0.0, FakeTimer, client-100);
		} else {
			//PrintToChat(client, "Gloves exist");
		}
	}
}
public Action FakeTimer(Handle timer, int client) {
	if(client < 0) CreateTimer(0.0, FakeTimer, client+100);
	else SetGlove(client);
	return Plugin_Stop;
}
public Action Cmd_ModelsMenu(int client, int args) {
	if(args == 0) {
		ModelMenu.Display(client, 40);
	} else {
		if(args >= 2) {
			char buff[10];
			GetCmdArg(1, buff, sizeof(buff));
			int type = StringToInt(buff);
			GetCmdArg(2, buff, sizeof(buff));
			int skin = StringToInt(buff);
			SetGlove(client, type, skin)
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}
stock void SaveGlove(int client, int model = -1, int skin = -1, int quality = -1, bool inform = false) {
	//PrintToServer("SaveGlove %d %d %d %d %d", client, model, skin, quality, inform);
	if (!IsClientConnected(client) && !IsClientInGame(client))return;
	char buff[8];
	if(model != -1) {
		IntToString(model, buff, sizeof(buff));
		SetClientCookie(client, ck_Glove_Type, buff);
		glove_Type[client] = model;
		if(skin != -1 && skin != -2) {
			if(vip_loaded && !GloveAccess(client, model, skin)) {
					ResetGlove(client, false);
					//PrintToChat(client, "%s У вас %sнету доступа\x01 к этим перчаткам!", tag1, clr);
					PrintToChat(client, "%s %t", tag1, "NoAccess", clr, 1);
			} else {
				char buff2[MENU_TEXT], buff3[MENU_TEXT]
				IntToString(skin, buff, sizeof(buff));
				SetClientCookie(client, ck_Glove_Skin, buff);
				glove_Skin[client] = skin;
				if(quality == -1 && glove_Quality[client] == -1)
					glove_Quality[client] = 100;
				alModels.GetString(GetModelPos(model)+1, buff2, sizeof(buff2))
				alModels.GetString(GetSkinPos(model, skin) + 1, buff3, sizeof(buff3));
				//if(inform) PrintToChat(client, "%s Перчатки %s%s | %s \x01установлены.", tag1, clr, buff2, buff3);
				if(inform) PrintToChat(client, "%s %t", tag1, "GloveSave", clr, buff2, buff3, 1);
			}
			//PrintToChat(client, "%s Выбранные вами перчатки %sсохранены\x01 в базу.", tag1, clr);
		}
	}
	if(quality != -1) {
		glove_Quality[client] = quality;
		IntToString(quality, buff, sizeof(buff));
		SetClientCookie(client, ck_Glove_Quality, buff);
		//PrintToChat(client, "%s Выбранное вами качество(%s%d%%\x01) сохранено.", tag1, clr, quality);
		PrintToChat(client, "%s %t", tag1, "QualitySave", clr, quality, 1);
	}
}
stock void SetGlove(int client, int model = -1, int skin = -1, int wear = -1) {
	//PrintToServer("SetGlove %d %d %d %d", client, model, skin, wear);
	if (!IsClientConnected(client) || !IsClientInGame(client) || IsFakeClient(client))
		return;
	if(model == -1 || skin == -1) {
		if(glove_Type[client] != -1 && glove_Skin[client] != -1) {
			model = glove_Type[client];
			skin = glove_Skin[client];
		} else {	
			switch(GetClientTeam(client)){
				case 2: {
					model = t_default_model;
					skin = t_default_skin;
				}
				case 3: {
					model = ct_default_model;
					skin = ct_default_skin;
				}
			}
		}// clear = true;
	}
	if(skin == -2) {
		skin = GetRandomSkin(model);
	}
	if(wear == -1) {
		if(glove_Quality[client] != -1)	wear = glove_Quality[client];
		else wear = 100;
	}
	int current = GetEntPropEnt(client, Prop_Send, "m_hMyWearables");
	if(current != -1 && IsWearable(current)) {
		AcceptEntityInput(current, "Kill");
		SetEntPropEnt(client, Prop_Send, "m_hMyWearables", -1);
		if (current == gloves[client]) gloves[client] = -1;
		//PrintToChat(client, "%s Прошлые перчатки были удалены!", tag1);
	}
	if(gloves[client] != -1 && IsWearable(gloves[client])) {
		AcceptEntityInput(gloves[client], "Kill");
		gloves[client] = -1;
	}
	int item = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", -1); 
	if(model != -1 && model != -3) {
		int ent = CreateEntityByName("wearable_item");
		if(ent != -1 && IsValidEdict(ent)) {
			gloves[client] = ent;
			SetEntPropEnt(client, Prop_Send, "m_hMyWearables", ent);
			SetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex", GetModelIndex(model));
			SetEntProp(ent, Prop_Send,  "m_nFallbackPaintKit", GetSkinIndex(model, skin));
			SetEntPropFloat(ent, Prop_Send, "m_flFallbackWear", 1.0-wear*0.01);
			SetEntProp(ent, Prop_Send, "m_iItemIDLow", 2048);
			SetEntProp(ent, Prop_Send, "m_bInitialized", 1);
			SetEntPropEnt(ent, Prop_Data, "m_hParent", client);
			SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
			SetEntPropEnt(ent, Prop_Data, "m_hMoveParent", client);
			DispatchSpawn(ent);
			SetEntProp(client, Prop_Send, "m_nBody", 1);
			//ChangeEdictState(ent);
		}
	} else {
		SetEntProp(client, Prop_Send, "m_nBody", 0);
	}
	DataPack ph = new DataPack();
	WritePackCell(ph, EntIndexToEntRef(client));
	if(IsValidEntity(item))	WritePackCell(ph, EntIndexToEntRef(item));
	else WritePackCell(ph, -1);
	CreateTimer(0.0, AddItemTimer, ph, TIMER_FLAG_NO_MAPCHANGE);  
}
public Action AddItemTimer(Handle timer, DataPack ph) {
    int client, item;
    ResetPack(ph);
    client = EntRefToEntIndex(ReadPackCell(ph));
    item = EntRefToEntIndex(ReadPackCell(ph));
    if (client != INVALID_ENT_REFERENCE && item != INVALID_ENT_REFERENCE) {
        SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", item);
    }    
    return Plugin_Stop;
}
stock bool IsWearable(int ent) {
	if(!IsValidEdict(ent)) return false;
	char weaponclass[32]; GetEdictClassname(ent, weaponclass, sizeof(weaponclass));
	if(StrContains(weaponclass, "wearable", false) == -1) return false;
	return true;
}
stock bool GloveAccess(int client, int model, int skin) {
	if (GetSkinLimit(model, skin) == 0) return true;
	else if(vip_loaded && VIP_IsClientVIP(client)) return true;
	return false;
}
stock void ResetGlove(int client, bool inform = true) {
	char buff2[MENU_TEXT], buff3[MENU_TEXT];
	glove_Type[client] = -3;
	glove_Skin[client] = -1;
	glove_Quality[client] = -1;
	SetClientCookie(client, ck_Glove_Type, "-3");
	SetClientCookie(client, ck_Glove_Skin, "-1");
	SetClientCookie(client, ck_Glove_Quality, "-1");
	SetEntPropEnt(client, Prop_Send, "m_hMyWearables", -1);
	SetGlove(client);
	int team = GetClientTeam(client);
	if(team == 2) {
		if(t_default_model != -3) {
			GetModelName(t_default_model, buff2);
			GetSkinName(t_default_model, t_default_skin, buff3);
			//if(inform) PrintToChat(client, "%s Перчатки сброшены на стандартные %s%s | %s", tag1, clr, buff2, buff3);
			if(inform) PrintToChat(client, "%s %t", tag1, "ResetTeam", clr, buff2, buff3, 1);
		} else {
			if(inform) PrintToChat(client, "%s %t", tag1, "Reset");
		}
	} else if(team == 3) {
		if(ct_default_model != -3) {
			GetModelName(ct_default_model, buff2);
			GetSkinName(ct_default_model, ct_default_skin, buff3);
			//if(inform) PrintToChat(client, "%s Перчатки сброшены на стандартные %s%s | %s", tag1, clr, buff2, buff3);
			if(inform) PrintToChat(client, "%s %t", tag1, "ResetTeam", clr, buff2, buff3, 1);
		} else {
			if(inform) PrintToChat(client, "%s %t", tag1, "Reset");
		}
	} else {
		//if(inform) PrintToChat(client, "%s Перчатки сброшены.", tag1);
		if(inform) PrintToChat(client, "%s %t", tag1, "Reset");
	}
}
// ArrayList wrapper
stock int GetModelPos(int model) {
	if(model<=GetModelsCount()) {
		int temp = 1;
		int position = 1;
		while(model != temp++) {
			int skins = alModels.Get(position + 4);
			position += skins*3+5;
		}
		return position;
	}
	return -1;
}
stock int GetSkinPos(int model, int skin) {
	int position = GetModelPos(model);
	if(skin<=alModels.Get(position + 4)) {
		return position+5+((skin>1)?(skin-1)*3:0);
	}
	return -1;
}
stock int GetRandomModel() {
	return GetRandomInt(1, GetModelsCount());
}
stock int GetRandomSkin(int model) {
	return GetRandomInt(1, alModels.Get(GetModelPos(model)+4));
}
stock int GetModelsCount(){
	return alModels.Get(0);
}
stock int GetSkinsCount(int model) {
	return alModels.Get(GetModelPos(model) + 4);
}
stock int GetModelIndex(int model) {
	return alModels.Get(GetModelPos(model));
}
stock void GetModelName(int model, char buffer[MENU_TEXT]) {
	alModels.GetString(GetModelPos(model) + 1, buffer, sizeof(buffer));
}
stock void GetModelIcon(int model, char buffer[8]) {
	alModels.GetString(GetModelPos(model) + 2, buffer, sizeof(buffer));
}
stock int GetSkinIndex(int model, int skin) {
	return alModels.Get(GetSkinPos(model, skin));
}
stock void GetSkinName(int model, int skin, char buffer[MENU_TEXT]) {
	alModels.GetString(GetSkinPos(model, skin) + 1, buffer, sizeof(buffer));
}
stock int GetSkinLimit(int model, int skin) {
	return alModels.Get(GetSkinPos(model, skin) + 2);
}
// TEMP
stock void DebugWearable(int ent) {
	char buff[128];
	if(GetEntityClassname(ent, buff, sizeof(buff)))
		WriteFileLine(file, "[GL] Entity %d GetEntityClassname: %s", ent, buff);
	if(GetEntityNetClass(ent, buff, sizeof(buff)))
		WriteFileLine(file, "[GL] Entity %d GetEntityNetClass: %s", ent, buff);
	GetPropSend2(ent, 1, "m_cellbits");
	GetPropSend2(ent, 1, "m_cellX");
	GetPropSend2(ent, 1, "m_cellY");
	GetPropSend2(ent, 1, "m_cellZ");
	GetPropSend2(ent, 3, "m_vecOrigin");
	GetPropSend2(ent, 1, "m_nModelIndex");
	GetPropSend2(ent, 3, "m_vecMins");
	GetPropSend2(ent, 3, "m_vecMaxs");
	GetPropSend2(ent, 1, "m_nSolidType");
	GetPropSend2(ent, 1, "m_usSolidFlags");
	GetPropSend2(ent, 1, "m_nSurroundType");
	GetPropSend2(ent, 1, "m_triggerBloat");
	GetPropSend2(ent, 3, "m_vecSpecifiedSurroundingMins");
	GetPropSend2(ent, 3, "m_vecSpecifiedSurroundingMaxs");
	GetPropSend2(ent, 1, "m_nRenderFX");
	GetPropSend2(ent, 1, "m_nRenderMode");
	GetPropSend2(ent, 1, "m_fEffects");
	GetPropSend2(ent, 1, "m_clrRender");
	GetPropSend2(ent, 1, "m_iTeamNum");
	GetPropSend2(ent, 1, "m_iPendingTeamNum");
	GetPropSend2(ent, 1, "m_CollisionGroup");
	GetPropSend2(ent, 2, "m_flElasticity");
	GetPropSend2(ent, 2, "m_flShadowCastDistance");
	GetPropSend2(ent, 5, "m_hOwnerEntity");
	GetPropSend2(ent, 5, "m_hEffectEntity");
	GetPropSend2(ent, 5, "moveparent");
	GetPropSend2(ent, 1, "m_iParentAttachment");
	GetPropSend2(ent, 4, "m_iName");
	GetPropSend2(ent, 1, "movetype");
	GetPropSend2(ent, 1, "movecollide");
	GetPropSend2(ent, 3, "m_angRotation");
	GetPropSend2(ent, 1, "m_iTextureFrameIndex");
	GetPropSend2(ent, 1, "m_bSimulatedEveryTick");
	GetPropSend2(ent, 1, "m_bAnimatedEveryTick");
	GetPropSend2(ent, 1, "m_bAlternateSorting");
	GetPropSend2(ent, 1, "m_bSpotted");
	GetPropSend2(ent, 1, "m_bIsAutoaimTarget");
	GetPropSend2(ent, 2, "m_fadeMinDist");
	GetPropSend2(ent, 2, "m_fadeMaxDist");
	GetPropSend2(ent, 2, "m_flFadeScale");
	GetPropSend2(ent, 1, "m_nMinCPULevel");
	GetPropSend2(ent, 1, "m_nMaxCPULevel");
	GetPropSend2(ent, 1, "m_nMinGPULevel");
	GetPropSend2(ent, 1, "m_nMaxGPULevel");
	GetPropSend2(ent, 2, "m_flUseLookAtAngle");
	GetPropSend2(ent, 2, "m_flLastMadeNoiseTime");
	GetPropSend2(ent, 1, "m_nForceBone");
	GetPropSend2(ent, 3, "m_vecForce");
	GetPropSend2(ent, 1, "m_nSkin");
	GetPropSend2(ent, 1, "m_nBody");
	GetPropSend2(ent, 1, "m_nHitboxSet");
	GetPropSend2(ent, 2, "m_flModelScale");
	GetPropSend2(ent, 1, "m_nSequence");
	GetPropSend2(ent, 2, "m_flPlaybackRate");
	GetPropSend2(ent, 1, "m_bClientSideAnimation");
	GetPropSend2(ent, 1, "m_bClientSideFrameReset");
	GetPropSend2(ent, 1, "m_bClientSideRagdoll");
	GetPropSend2(ent, 1, "m_nNewSequenceParity");
	GetPropSend2(ent, 1, "m_nResetEventsParity");
	GetPropSend2(ent, 1, "m_nMuzzleFlashParity");
	GetPropSend2(ent, 1, "m_hLightingOrigin");
	GetPropSend2(ent, 2, "m_flFrozen");
	GetPropSend2(ent, 1, "m_ScaleType");
	GetPropSend2(ent, 1, "m_bSuppressAnimSounds");
	GetPropSend2(ent, 1, "m_blinktoggle");
	GetPropSend2(ent, 3, "m_viewtarget");
	GetPropSend2(ent, 1, "m_hOuter");
	GetPropSend2(ent, 1, "m_ProviderType");
	GetPropSend2(ent, 1, "m_iReapplyProvisionParity");
	GetPropSend2(ent, 1, "m_iItemDefinitionIndex");
	GetPropSend2(ent, 1, "m_iEntityLevel");
	GetPropSend2(ent, 1, "m_iItemIDHigh");
	GetPropSend2(ent, 1, "m_iItemIDLow");
	GetPropSend2(ent, 1, "m_iAccountID");
	GetPropSend2(ent, 1, "m_iEntityQuality");
	GetPropSend2(ent, 1, "m_bInitialized");
	GetPropSend2(ent, 4, "m_szCustomName");
	GetPropSend2(ent, 1, "m_OriginalOwnerXuidLow");
	GetPropSend2(ent, 1, "m_OriginalOwnerXuidHigh");
	GetPropSend2(ent, 1, "m_nFallbackPaintKit");
	GetPropSend2(ent, 1, "m_nFallbackSeed");
	GetPropSend2(ent, 2, "m_flFallbackWear");
	GetPropSend2(ent, 1, "m_nFallbackStatTrak");
}
stock void GetPropSend2(int ent, int type, char[] key) {
	//if (!IsWearable(ent))return;
	switch(type) {
		case 1: {
			PrintToServer("[GL] %d int '%s': %d", ent, key, GetEntProp(ent, Prop_Send, key));
		}
		case 2: {
			PrintToServer("[GL] %d float '%s': %.4f", ent, key, GetEntPropFloat(ent, Prop_Send, key));
		}
		case 3: {
			float vec[3];
			GetEntPropVector(ent, Prop_Send, key, vec);
			PrintToServer("[GL] %d vec '%s': %.2f %.2f %.2f", ent, key, vec[0], vec[1], vec[2]);
		}
		case 4: {
			char buff2[48];
			GetEntPropString(ent, Prop_Send, key, buff2, sizeof(buff2));
			PrintToServer("[GL] %d str '%s': %s", ent, key, buff2);
		}
		case 5: {
			char buff2[48];
			int ent2 = GetEntPropEnt(ent, Prop_Send, key);
			if(IsValidEntity(ent2)) {
				GetEntityNetClass(ent2, buff2, sizeof(buff2));
			} else {
				ent2 = EntRefToEntIndex(ent2);
				if(IsValidEntity(ent2)){
					GetEntityNetClass(ent2, buff2, sizeof(buff2));
				} else {
					ent2 = GetEntProp(ent, Prop_Send, key);
					strcopy(buff2, sizeof(buff2), "Falied to get Ent");
				}
			}
			PrintToServer("[GL] %d ent '%s': %d - %s", ent, key, ent2, buff2);
		}
	}
}