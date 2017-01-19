#undef REQUIRE_PLUGIN
#include <vip_core>
#define REQUIRE_PLUGIN
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#define MENU_TEXT 50
#define ARRAY_SIZE 96

/* 60% магии / 40% веры 
 *TODO:
 * 1. 50% Ограничение по vip r1ko
 * 2. ✓  Рандомный скин 
 * 3. ✓ Дефолтный скин для каждой команды
 */
public Plugin myinfo = {
	name = "Gloves", author = "Aircraft(diller110)",
	description = "Set in-game gloves",	version = "1.1", url = "thanks to Franc1sco franug"
};

char tag[16];
ArrayList alModels;
Menu ModelMenu, QualityMenu;
int		clr,
		limit_type,
		random,
		t_default_model,
		t_default_skin,
		ct_default_model,
		ct_default_skin,
		gloves[MAXPLAYERS +1] = {-1, ...},
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
	Format(tag, sizeof(tag), "[%s%s\x01]", clr, tag);
	
	ck_Glove_Type = RegClientCookie("AcGloveType8", "", CookieAccess_Private);
	ck_Glove_Skin = RegClientCookie("AcGloveSkin8", "", CookieAccess_Private);
	ck_Glove_Quality = RegClientCookie("AcGloveQuality8", "", CookieAccess_Private);
	
	CreateTimer(2.0, LateLoading);
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_team", Event_PlayerTeam);
	
	RegConsoleCmd("sm_gloves", Cmd_ModelsMenu);
	RegConsoleCmd("sm_glove", Cmd_ModelsMenu);
	RegConsoleCmd("sm_gl", Cmd_ModelsMenu);
}
public void OnPluginEnd() {
	for(int i = 1; i <= MaxClients; i++)
		if(gloves[i] != -1 && IsWearable(gloves[i])) {
			if(IsClientConnected(i) && IsPlayerAlive(i)) {
				SetEntPropEnt(i, Prop_Send, "m_hMyWearables", -1);
				//PrintToChat(i, "%s Ваши перчатки были удалены в связи с отключением плагина.", tag);
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
			//PrintToServer("%N %d %d %d", client, glove_Type[client], glove_Skin[client], glove_Quality[client]);
			SetGlove(client);
			PrintToChat(client, "%s Ваши перчатки восстановлены!", tag);
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
public Action LateLoading(Handle timer, int client) {
	for(int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && !IsFakeClient(i) && AreClientCookiesCached(i))
			OnClientCookiesCached(i);
	return Plugin_Stop;
}
public void LoadKV() {
	KeyValues kv = new KeyValues("Gloves");
	char confPath[256];
	BuildPath(Path_SM, confPath, sizeof(confPath), "/configs/ac_gloves.txt");
	if(kv.ImportFromFile(confPath)) {
		kv.Rewind();
		kv.GetString("tag", tag, sizeof(tag), "GL");
		clr = kv.GetNum("color", 11);
		if(clr < 1 || clr > 16) clr = 11;
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
					//PrintToServer("%d %s", t, buff);
					//alModels.Push(kv.GetNum("icon", 0));
					kv.GetString("icon", buff, 8);
					//alModels.Push(buff[0]);
					//PrintToChatAll("%s - %d", buff[0], buff[0]);
					alModels.PushString(buff);
					//PrintToChatAll("%s %s %s %s %s %s", 10MENU_TEXT4898, 8755426, 12097762, 8689890, 9279714, 10919138);
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
								//PrintToServer("%d %d", alModels.Get(num*OFF+5), buff2);
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
	PrintToServer("[GLOVES] %d models loaded!", GetModelsCount());
	delete kv;
}
public void CreateMenus() {
	ModelMenu = CreateMenu(ModelMenuHandler);
	ModelMenu.SetTitle("Выбор перчаток:");
	int count = GetModelsCount();
	char buff[8], buff2[MENU_TEXT], buff3[8];
	for (int i = 1; i <= count; i++) {
		IntToString(i, buff, sizeof(buff));
		GetModelName(i, buff2);
		GetModelIcon(i, buff3);
		//PrintToChatAll("123 %s %d", icon, icon);
		if(buff3[0]) {
	 		Format(buff2, sizeof(buff2), "%s %s", buff3, buff2);
		}
		ModelMenu.AddItem(buff, buff2);
	}
	ModelMenu.AddItem("_reset", "Стандартные");
	ModelMenu.AddItem("_quality", "Качество");
	ModelMenu.AddItem("_close", "Закрыть");
	ModelMenu.Pagination = MENU_NO_PAGINATION;
	ModelMenu.ExitButton = false;
	//ModelMenu.AddItem("123", "☁☘★☠☬☮☸♞⚒⚔⛏");
	
	QualityMenu = CreateMenu(QualityMenuHandler);
	QualityMenu.SetTitle("Выбор качества:");
	QualityMenu.AddItem("100", "Прямо с завода");
	QualityMenu.AddItem("75", "Поношенное");
	QualityMenu.AddItem("50", "После полевых испытаний");
	QualityMenu.AddItem("25", "Закаленное в боях");
	QualityMenu.AddItem("0", "Отработанное");
	QualityMenu.AddItem("", "", ITEMDRAW_SPACER);
	QualityMenu.AddItem("back", "Назад");
	QualityMenu.AddItem("close", "Закрыть");
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
			//int position = GetModelPos(model);
			int skins = GetSkinsCount(model);
			Menu SkinMenu = CreateMenu(SkinMenuHandler);
			Format(buff3, sizeof(buff3), "%s:", buff2);
			SkinMenu.SetTitle(buff3);
			if(random) {
				Format(buff, sizeof(buff), "_r:%d", model);
				SkinMenu.AddItem(buff, "Рандомный");
				SkinMenu.AddItem("", "", ITEMDRAW_SPACER);
			}
			for (int i = 1; i <= skins; i++) {
				Format(buff, sizeof(buff), "%d:%d", model, i);
				GetSkinName(model, i, buff2);
				SkinMenu.AddItem(buff, buff2);
			}
			SkinMenu.AddItem("_", "", ITEMDRAW_SPACER);
			SkinMenu.AddItem("_back", "Назад");
			SkinMenu.Pagination = MENU_NO_PAGINATION;
			SkinMenu.ExitButton = false;
			SkinMenu.Display(client, 40);
		}
		//GetModelName(StringToInt(buff), buff2);
		//PrintToChat(client, "Вы выбрали пункт %s - %s", buff, buff2);
	}	
}
public int SkinMenuHandler(Menu menu, MenuAction action, int client, int item) {
	if (action == MenuAction_Select) {
		char buff[16], buff2[MENU_TEXT]; //, buff3[MENU_TEXT];
		menu.GetItem(item, buff, sizeof(buff));
		if(buff[0] == '_') { // Управляющие пункты
			if(buff[1] == 'r') {
				char buffs[2][8];
				ExplodeString(buff, ":", buffs, 2, 8);
				int model = StringToInt(buffs[1]);
				GetModelName(model, buff2);
				//alModels.GetString(GetModelPos(model) + 1, buff2, sizeof(buff2));
				PrintToChat(client, "%s Рандомный скин для  %s%s \x01установлен.", tag, clr, buff2);
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
			//PrintToServer("%N %d %d %d", client, glove_Type[client], glove_Skin[client], glove_Quality[client]);
			SetGlove(client);
			menu.Display(client, 40);
			/*
			ReplyToCommand(client, "model %d skin %d", model, skin);
			ReplyToCommand(client, "modelpos %d skinpos %d", GetModelPos(model), GetSkinPos(model, skin));
			alModels.GetString(GetModelPos(model)+1, buff, sizeof(buff))
			ReplyToCommand(client, "Model: %s", buff);
			alModels.GetString(GetSkinPos(model, skin) + 1, buff, sizeof(buff));
			ReplyToCommand(client, "Skin: %s", buff);
			*/
		}
	} else if (action == MenuAction_End && client != MenuEnd_Selected)
		if(menu != INVALID_HANDLE) {
			delete menu;
		}
}
public int QualityMenuHandler(Menu menu, MenuAction action, int client, int item) {
	if (action == MenuAction_Select) {
		switch(item){
			case 0: {
				SaveGlove(client, _, _, 100);
				SetGlove(client);
			}
			case 1: {
				SaveGlove(client, _, _, 75);
				SetGlove(client);
			}
			case 2: {
				SaveGlove(client, _, _, 50);
				SetGlove(client);
			}
			case 3: {
				SaveGlove(client, _, _, 25);
				SetGlove(client);
			}
			case 4: {
				SaveGlove(client, _, _, 0);
				SetGlove(client);
			}
			case 6: {
				ModelMenu.Display(client, 40);
			}
		}
		if(item<5) {
			QualityMenu.Display(client, 20);
		}
	}
}
public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!IsFakeClient(client) && GetEntProp(client, Prop_Send, "m_bIsControllingBot") != 1) {
		int wear = GetEntPropEnt(client, Prop_Send, "m_hMyWearables");
		if(wear != -1 && IsWearable(wear)) {
			SetEntPropEnt(client, Prop_Send, "m_hMyWearables", -1);
		}
	}
}
public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!IsFakeClient(client) && GetEntProp(client, Prop_Send, "m_bIsControllingBot") != 1) {
		int wear = GetEntPropEnt(client, Prop_Send, "m_hMyWearables");
		if(wear == -1) {
			CreateTimer(0.0, FakeTimer, client-100);
		}
	}
}
public Action Event_PlayerTeam(Event event,char[] name,  bool dontBroadcast) { 
	int client = GetClientOfUserId(event.GetInt("userid"));
	if((event.GetInt("oldteam") == 0) && IsClientConnected(client)) {
		CreateTimer(0.2, Timer_FirstSpawn, client+100);
	}
	return Plugin_Changed;
}
public Action Timer_FirstSpawn(Handle timer, int client) {
	if(client>100) {
		CreateTimer(2.0, Timer_FirstSpawn, client-100);
	} else {
		if(IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client) && AreClientCookiesCached(client)) {
			SetGlove(client);
		}
	}
	return Plugin_Stop;
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
public Action Cmd_GL1(int client, int args) {
	ReplyToCommand(client, "Getting random skin...");
	int model = GetRandomModel();
	int skin = GetRandomSkin(model);
	ReplyToCommand(client, "model %d skin %d", model, skin);
	ReplyToCommand(client, "modelpos %d skinpos %d", GetModelPos(model), GetSkinPos(model, skin));
	char buff[48];
	alModels.GetString(GetModelPos(model)+1, buff, sizeof(buff))
	PrintToServer("Model: %s", buff);
	alModels.GetString(GetSkinPos(model, skin) + 1, buff, sizeof(buff));
	ReplyToCommand(client, "Skin: %s", buff);
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
					PrintToChat(client, "%s У вас %sнету доступа\x01 к этим перчаткам!", tag, clr);
			} else {
				char buff2[MENU_TEXT], buff3[MENU_TEXT]
				IntToString(skin, buff, sizeof(buff));
				SetClientCookie(client, ck_Glove_Skin, buff);
				glove_Skin[client] = skin;
				if(quality == -1 && glove_Quality[client] == -1)
					glove_Quality[client] = 100;
				alModels.GetString(GetModelPos(model)+1, buff2, sizeof(buff2))
				alModels.GetString(GetSkinPos(model, skin) + 1, buff3, sizeof(buff3));
				if(inform) PrintToChat(client, "%s Перчатки %s%s | %s \x01установлены.", tag, clr, buff2, buff3);
			}
			//PrintToChat(client, "%s Выбранные вами перчатки %sсохранены\x01 в базу.", tag, clr);
		}
	}
	if(quality != -1) {
		glove_Quality[client] = quality;
		IntToString(quality, buff, sizeof(buff));
		SetClientCookie(client, ck_Glove_Quality, buff);
		PrintToChat(client, "%s Выбранное вами качество(%s%d%%\x01) сохранено.", tag, clr, quality);
	}
}
stock void SetGlove(int client, int model = -1, int skin = -1, int wear = -1) {
	//PrintToServer("SetGlove %d %d %d %d", client, model, skin, wear);
	if (!IsClientConnected(client) || !IsClientInGame(client) || IsFakeClient(client))
		return;
	if((model == -1 || skin == -1)) {
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
		if (current == gloves[client])gloves[client] = -1;
		//PrintToChat(client, "%s Прошлые перчатки были удалены!", tag);
	}
	if(gloves[client] != -1 && IsWearable(gloves[client])) {
		AcceptEntityInput(gloves[client], "Kill");
		gloves[client] = -1;
	}
	int item = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", -1); 
	if(model != -1) {
		int ent = GivePlayerItem(client, "wearable_item");
		if (ent != -1 && IsValidEdict(ent)) {
			gloves[client] = ent;
			SetEntityRenderMode(ent, RENDER_NONE); // prevent arms appearing
			SetEntPropEnt(client, Prop_Send, "m_hMyWearables", ent);
			SetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex", GetModelIndex(model));
			SetEntPropFloat(ent, Prop_Send, "m_flFallbackWear", 1.0-wear*0.01);
			SetEntProp(ent, Prop_Send,  "m_nFallbackPaintKit", GetSkinIndex(model, skin));
			//PrintToChat(client, "%d %d", GetModelIndex(model), GetSkinIndex(model, skin));
			char buff[ARRAY_SIZE];
			GetModelPath(model, buff);
			SetEntityModel(ent, buff);
			ChangeEdictState(ent);
		} else {	
			PrintToChat(client, "%s Ошибка при установке перчаток!", tag);
			LogError("[GLOVES] Failed to give wearable_item to %N", client);
		}
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
	else if(VIP_IsClientVIP(client)) return true;
	return false;
}
stock void ResetGlove(int client, bool inform = true) {
	char buff2[MENU_TEXT], buff3[MENU_TEXT];
	glove_Type[client] = -1;
	glove_Skin[client] = -1;
	glove_Quality[client] = -1;
	SetClientCookie(client, ck_Glove_Type, "-1");
	SetClientCookie(client, ck_Glove_Skin, "-1");
	SetClientCookie(client, ck_Glove_Quality, "-1");
	SetEntPropEnt(client, Prop_Send, "m_hMyWearables", -1);
	SetGlove(client);
	int team = GetClientTeam(client);
	if(team == 2) {
		GetModelName(t_default_model, buff2);
		GetSkinName(t_default_model, t_default_skin, buff3);
		if(inform) PrintToChat(client, "%s Перчатки сброшены на стандартные %s%s | %s", tag, clr, buff2, buff3);
	} else if(team == 3) {
		GetModelName(ct_default_model, buff2);
		GetSkinName(ct_default_model, ct_default_skin, buff3);
		if(inform) PrintToChat(client, "%s Перчатки сброшены на стандартные %s%s | %s", tag, clr, buff2, buff3);
	} else {
		if(inform) PrintToChat(client, "%s Перчатки сброшены.", tag);
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
stock void GetModelPath(int model, char buffer[ARRAY_SIZE]) {
	alModels.GetString(GetModelPos(model) + 3, buffer, sizeof(buffer));
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
// Built-in wrapper