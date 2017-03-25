#include <dynamic>
#include <sdktools>
#include <clientprefs>
#undef REQUIRE_PLUGIN
#include <vip_core>
#define REQUIRE_PLUGIN

public void PrintDebug(const char[] msg, any ...) {
	int len = strlen(msg) + 255;
	char[] formatted = new char[len];
	VFormat(formatted, len, msg, 2);
	PrintToServer("[GLOVES] DEBUG: %s", formatted);
}

/* Для быстрого доступа, получать строку через буфер не вариант*/
stock char Tag[16] = "[\x11GL\x01]";
stock int Clr;
/**
 * Главный объект хранящий параметры поведения объектов GloveStorage, GloveHandler
 */
methodmap GloveGlobal < Dynamic {
	/**
	 * Type - data storage type:
	 * 0 - cookies
	*/
	public GloveGlobal(int type = 0) {
		Dynamic gg1 = Dynamic();
		if(gg1.IsValid) {
			gg1.SetBool("VipLoaded", LibraryExists("vip_core"));
			if(type == 0) {
				gg1.SetHandle("ModelCookieCT", RegClientCookie("AcGloveModelCT", "", CookieAccess_Private));
				gg1.SetHandle("SkinCookieCT", RegClientCookie("AcGloveSkinCT", "", CookieAccess_Private));
				gg1.SetHandle("ModelCookieT", RegClientCookie("AcGloveModelT", "", CookieAccess_Private));
				gg1.SetHandle("SkinCookieT", RegClientCookie("AcGloveSkinT", "", CookieAccess_Private));
				gg1.SetHandle("QualityCookie", RegClientCookie("AcGloveQuality", "", CookieAccess_Private));
			}
			return view_as<GloveGlobal>(gg1);
		}
		return view_as<GloveGlobal>(INVALID_DYNAMIC_OBJECT);
	}
	/**
     * bool TeamDivided <get/set>
	 * Учитывать команды при выдаче перчаток или нет
	*/
	property bool TeamDivided {
		public get() {
			return this.GetBool("TeamDivided", true);
		}
		public set(bool val) {
			this.SetBool("TeamDivided", val);
		}
	}
	property bool VipLoaded {
		public get() {
			return this.GetBool("VipLoaded", false);
		}
		public set(bool val) {
			this.SetBool("VipLoaded", val);
		}
	}
	property bool SkipCustomArms {
		public get() {
			return this.GetBool("SkipCustomArms", false);
		}
		public set(bool val) {
			this.SetBool("SkipCustomArms", val);
		}
	}
	property bool ThirdPerson {
		public get() {
			return this.GetBool("ThirdPerson", true);
		}
		public set(bool val) {
			this.SetBool("ThirdPerson", val);
		}
	}
	property bool Random {
		public get() {
			return this.GetBool("Random", true);
		}
		public set(bool val) {
			this.SetBool("Random", val);
		}
	}
	property bool AnyDefaults {
		public get() {
			return this.GetBool("AnyDefaults", false);
		}
		public set(bool val) {
			this.SetBool("AnyDefaults", val);
		}
	}
	property bool VipDefaults {
		public get() {
			return this.GetBool("VipDefaults", false);
		}
		public set(bool val) {
			this.SetBool("VipDefaults", val);
		}
	}
	property int Color {
		public get() {
			return this.GetInt("Color", 1);
		}
		public set(int val) {
			if (val < 1 || val > 16) val = 11;
			this.SetInt("Color", val);
		}
	}
	property bool SetGloveDelay {
		public get() {
			return this.GetBool("SetGloveDelay", false);
		}
		public set(bool val) {
			this.SetBool("SetGloveDelay", val);
		}
	}
	property Handle ModelCookieCT {
		public get() {
			return this.GetHandle("ModelCookieCT");
		}
	}
	property Handle SkinCookieCT {
		public get() {
			return this.GetHandle("SkinCookieCT");
		}
	}
	property Handle ModelCookieT {
		public get() {
			return this.GetHandle("ModelCookieT");
		}
	}
	property Handle SkinCookieT {
		public get() {
			return this.GetHandle("SkinCookieT");
		}
	}
	property Handle QualityCookie {
		public get() {
			return this.GetHandle("QualityCookie");
		}
	}
	public Handle ModelCookie(int team = -1) {
		if(team != -1) {
			if(team == 2) {
				return this.ModelCookieT;
			} else {
				return this.ModelCookieCT;
			}
		} else {
			if(!this.TeamDivided) {
				return this.ModelCookieCT;
			} else {
				switch(team) {
					case 2: {
						return this.ModelCookieT;
					}
					default: {
						return this.ModelCookieCT;
					}
				}
			}
		}
		return this.ModelCookieCT;
	}
	public Handle SkinCookie(int team = -1) {
		if(team != -1) {
			if(team == 2) {
				return this.SkinCookieT;
			} else {
				return this.SkinCookieCT;
			}
		} else {
			if(!this.TeamDivided) {
				return this.SkinCookieCT;
			} else {
				switch(team) {
					case 2: {
						return this.SkinCookieT;
					}
					default: {
						return this.SkinCookieCT;
					}
				}
			}
		}
		return this.SkinCookieCT;
	}
	public bool LoadFromFile(char[] path) {
		bool success = false;
		KeyValues kv = new KeyValues("Gloves");
		if(kv.ImportFromFile(path)) {
			kv.Rewind();
			this.TeamDivided = view_as<bool>(kv.GetNum("team_divided", 1));
			this.SkipCustomArms = view_as<bool>(kv.GetNum("skip_custom_arms", 0));
			this.ThirdPerson = view_as<bool>(kv.GetNum("show_thirdperson", 1));
			this.SetGloveDelay = view_as<bool>(kv.GetNum("set_glove_delay", 0));
			this.Random = view_as<bool>(kv.GetNum("random", 1));
			char tag1[16];
			kv.GetString("tag", tag1, sizeof(tag1), "GL");
			int clr = kv.GetNum("color", 11);
			if(clr < 1 || clr > 16) clr = 11;
			this.Color = Clr = clr;
			Format(tag1, sizeof(tag1), "[%s%s\x01]", clr, tag1);
			this.SetString("Tag", tag1);
			Format(Tag, sizeof(Tag), tag1);
			success = true;
		}
		delete kv;
		return success;
	}
}
stock GloveGlobal gg;
/**
 * Объект хранящий возможные модели и скины
 */
methodmap GloveStorage < Dynamic {
	public GloveStorage() {
		Dynamic gs1 = Dynamic();
		return view_as<GloveStorage>(gs1);
	}
	property Dynamic Defaults {
		public get() {
			return this.GetDynamic("Defaults");
		}
		public set(Dynamic val) {
			this.SetDynamic("Defaults", val);
		}
	}
	
	public int ModelsCount() {
		if(this.Defaults != INVALID_DYNAMIC_OBJECT) {
			return this.MemberCount-1;
		}
		return this.MemberCount;
	}
	public bool AddModel(int model, char[] name, char[] icon) {
		if(model>0) {
			char buff[8];
			IntToString(model, buff, sizeof(buff));
			Dynamic mdl = Dynamic();
			mdl.SetString("Name", name);
			mdl.SetString("Icon", icon);
			this.SetDynamic(buff, mdl);
			if(this.GetDynamic(buff) == INVALID_DYNAMIC_OBJECT) {
				return true;
			}
		}
		return false;
	}
	public bool CheckModel(int model) {
		if(model > 0) {
			char buff[8];
			IntToString(model, buff, sizeof(buff));
			Dynamic mdl = this.GetDynamic(buff);
			if(mdl.IsValid) {
				return true;
			}
		}
		return false;
	}
	public void ModelName(int model, char[] str, int maxlen) {
		if(model > 0) {
			char buff[8];
			IntToString(model, buff, sizeof(buff));
			Dynamic mdl = this.GetDynamic(buff);
			if(mdl.IsValid) {
				mdl.GetString("Name", str, maxlen);
			}
		}
	}
	public void ModelIcon(int model, char[] str, int maxlen) {
		if(model > 0) {
			char buff[8];
			IntToString(model, buff, sizeof(buff));
			Dynamic mdl = this.GetDynamic(buff);
			if(mdl.IsValid) {
				mdl.GetString("Icon", str, maxlen);
			}
		}
	}
	public int RandomModel() {
		int ind = GetRandomInt(0, this.ModelsCount()-1);
		char buff[10];
		if(this.GetMemberNameByIndex(ind, buff, sizeof(buff))){
			return StringToInt(buff);
		}
		return -1;
	}
	
	public int SkinsCount(int model) {
		if(model > 0) {
			char buff[10];
			IntToString(model, buff, sizeof(buff));
			Dynamic mdl = this.GetDynamic(buff);
			if(mdl.IsValid) {
				return mdl.MemberCount - 2;
			}
		}
		return 0;
	}
	public bool AddSkin(int model, int skin, char[] name, int limit) {
		if(model > 0 && skin > 0) {
			char buff[10], buff2[10];
			IntToString(model, buff, sizeof(buff));
			IntToString(skin, buff2, sizeof(buff2));
			Dynamic mdl = this.GetDynamic(buff);
			if(mdl.IsValid) {
				Dynamic skn = Dynamic();
				skn.SetString("Name", name);
				skn.SetInt("Limit", limit);
				mdl.SetDynamic(buff2, skn);
				if(mdl.GetDynamic(buff2) == INVALID_DYNAMIC_OBJECT) {
					return true;
				}
			}
		}
		return false;
	}
	public bool CheckSkin(int model, int skin) {
		if(model > 0 && skin > 0) {
			char buff[10], buff2[10];
			IntToString(model, buff, sizeof(buff));
			IntToString(skin, buff2, sizeof(buff2));
			Dynamic mdl = this.GetDynamic(buff);
			if(mdl.IsValid) {
				Dynamic skn = mdl.GetDynamic(buff2);
				if(skn.IsValid) {
					return true;
				}
			}
		}
		return false;
	}
	public void SkinName(int model, int skin, char[] str, int maxlen) {
		if(model > 0 && skin > 0) {
			char buff[10], buff2[10];
			IntToString(model, buff, sizeof(buff));
			IntToString(skin, buff2, sizeof(buff2));
			Dynamic mdl = this.GetDynamic(buff);
			if(mdl.IsValid) {
				Dynamic skn = mdl.GetDynamic(buff2);
				if(skn.IsValid) {
					skn.GetString("Name", str, maxlen);
				} else PrintToServer("[Gloves] Cannot find model skin: %d %d.", model, skin);
			} else PrintToServer("[Gloves] Cannot find model: %d.", model);
		}
	}
	public int SkinLimit(int model, int skin) {
		if(model > 0 && skin > 0) {
			char buff[10], buff2[10];
			IntToString(model, buff, sizeof(buff));
			IntToString(skin, buff2, sizeof(buff2));
			Dynamic mdl = this.GetDynamic(buff);
			if(mdl.IsValid) {
				Dynamic skn = mdl.GetDynamic(buff2);
				if(skn.IsValid) {
					return skn.GetInt("Limit");
				} else PrintToServer("[Gloves] Cannot find model skin: %d %d.", model, skin);
			} else PrintToServer("[Gloves] Cannot find model: %d.", model);
		}
		return 0;
	}
	public int RandomSkin(int model) {
		if(model > 0) {
			char buff[10];
			IntToString(model, buff, sizeof(buff));
			Dynamic mdl = this.GetDynamic(buff);
			if(mdl.IsValid) {
				int ind = GetRandomInt(2, mdl.MemberCount - 1);
				if(mdl.GetMemberNameByIndex(ind, buff, sizeof(buff))) {
					return StringToInt(buff);
				}
			}
		}
		return -1;
	}
	public int GetDefaultModel(char[] group = "", int team = -1) {
		Dynamic gd = INVALID_DYNAMIC_OBJECT;
		if(StrEqual(group, "") || StrEqual(group, "Any")) {
			gd = this.Defaults.GetDynamic("Any");
		} else {
			gd = this.Defaults.GetDynamic(group);
			if(!gd.IsValid) {
				gd = this.GetDynamic("Any");
			}
		}
		if(gd.IsValid) {
			if(gg.TeamDivided) {
				if(team == -1) {
					return gd.GetInt("CTModel", -3);
				} else {
					if(team == 2) {
						return gd.GetInt("TModel", -3);
					} else {
						return gd.GetInt("CTModel", -3);
					}
				}
			} else {
				return gd.GetInt("CTModel", -3);
			}
		}
		return -3; // Ничего не нашли, значит не ставить ничего.
	}
	public int GetDefaultSkin(char[] group = "", int team = -1) {
		Dynamic gd = INVALID_DYNAMIC_OBJECT;
		if(StrEqual(group, "") || StrEqual(group, "Any")) {
			gd = this.Defaults.GetDynamic("Any");
		} else {
			gd = this.Defaults.GetDynamic(group);
			if(!gd.IsValid) {
				gd = this.Defaults.GetDynamic("Any");
			}
		}
		if(gd.IsValid) {
			if(gg.TeamDivided) {
				if(team == -1) {
					return gd.GetInt("CTSkin", -3);
				} else {
					if(team == 2) {
						return gd.GetInt("TSkin", -3);
					} else {
						return gd.GetInt("CTSkin", -3);
					}
				}
			} else {
				return gd.GetInt("CTSkin", -3);
			}
		}
		return -3; // Ничего не нашли, значит не ставить ничего.
	}
	
	public bool LoadFromFile(char[] path) {
		bool success = false;
		KeyValues kv = new KeyValues("Gloves");
		if(kv.ImportFromFile(path)) {
			kv.Rewind();
			if(kv.JumpToKey("Models", false)) {
				if(kv.GotoFirstSubKey(true)) {
					char buff[3][96];
					do {
						kv.GetSectionName(buff[0], sizeof(buff[]));
						kv.GetString("name", buff[1], sizeof(buff[]));
						kv.GetString("icon", buff[2], sizeof(buff[]));
						this.AddModel(StringToInt(buff[0]), buff[1], buff[2]);
						
						if(kv.JumpToKey("skins", false)) {
							if(kv.GotoFirstSubKey(true)) {
								do {
									kv.GetSectionName(buff[1], sizeof(buff[]));
									kv.GetString("name", buff[2], sizeof(buff[]));
									int limit = kv.GetNum("limit", -1);
									if (limit < -1 || limit > 99) limit = -1;
									this.AddSkin(StringToInt(buff[0]), StringToInt(buff[1]), buff[2], limit);
									if (!success)success = true;
								} while (kv.GotoNextKey(true));
								kv.GoBack();
							}
							kv.GoBack();
						}
					} while (kv.GotoNextKey(true));
				} else SetFailState("[GLOVES] No models found.");
			} else SetFailState("[GLOVES] Models settings not found.");
		} else SetFailState("[GLOVES] Settings not found.");
		delete kv;
		return success;
	}
	public bool LoadDefaults(char[] path) {
		bool success = false;
		Dynamic df = Dynamic();
		KeyValues kv = new KeyValues("Gloves");
		if(kv.ImportFromFile(path)) {
			kv.Rewind();
			if(kv.JumpToKey("Defaults", false)) {
				int temp = -1, temp2 = -1;
				char buff[16];
				if(kv.GotoFirstSubKey(true)) {
					do {
						Dynamic vp = Dynamic();
						kv.GetSectionName(buff, sizeof(buff));
						if (StrEqual(buff, "Any"))gg.AnyDefaults = true;
						else gg.VipDefaults = true;
						
						temp = kv.GetNum("t_model", -1);
						if(this.CheckModel(temp)) {
							vp.SetInt("TModel", temp);
							temp2 = kv.GetNum("t_skin", -1);
							if(this.CheckSkin(temp, temp2)) {
								vp.SetInt("TSkin", temp2);
							} else {
								PrintToServer("[GLOVES] ERROR: Default T skin for group %s not found in storage!", buff);
								vp.SetInt("TSkin", -2);
							}
						} else {
							PrintToServer("[GLOVES] ERROR: Default T model for group %s not found in storage!", buff);
							vp.SetInt("TModel", temp);
						}
						temp = kv.GetNum("ct_model", -1);
						if(this.CheckModel(temp)) {
							vp.SetInt("CTModel", temp);
							temp2 = kv.GetNum("ct_skin", -1);
							if(this.CheckSkin(temp, temp2)) {
								vp.SetInt("CTSkin", temp2);
							} else {
								PrintToServer("[GLOVES] ERROR: Default CT skin for group %s not found in storage!", buff);
								vp.SetInt("CTSkin", -2);
							}
						} else {
							PrintToServer("[GLOVES] ERROR: Default CT model for group %s not found in storage!", buff);
							vp.SetInt("CTModel", temp);
						}
						
						df.SetDynamic(buff, vp);
						if (!success)success = true;
					} while (kv.GotoNextKey(true));
				}
			}
		}
		delete kv;
		this.Defaults = df;
		return success;
	}
}
stock GloveStorage gs;
/**
 * Объект хранящий данные игрока
 */
methodmap GloveHolder < Dynamic {
	public GloveHolder() {
		/*if(!IsClientConnected(client) || IsFakeClient(client)){
			return view_as<GloveHolder>(INVALID_DYNAMIC_OBJECT);
		}*/
		Dynamic gh1 = Dynamic();
		/*Забиваем дефолтными значениями*/
		/*Клиент-держатель перчаток*/
		//gh1.SetInt("Client", client);
		gh1.SetInt("Client", -1);
		/*Наличие привилегий у держателя*/
		//gh1.SetBool("Vip", vip);
		gh1.SetBool("Vip", true);
		gh1.SetInt("Glove", -1);
		gh1.SetInt("ModelCT", -3);
		gh1.SetInt("ModelT", -3);
		gh1.SetInt("SkinCT", -3);
		gh1.SetInt("SkinT", -3);
		gh1.SetInt("Quality", 100);
		return view_as<GloveHolder>(gh1);
	}
	property int Client	{
		public get() {
			return this.GetInt("Client", -1);
		}
		public set(int val) {
			PrintDebug("Rewrite GloveHolder's Client parametr from %d to %d", this.GetInt("Client", -1), val);
			this.SetInt("Client", val);
		}
	}
	property bool Vip {
		public get() {
			return this.GetBool("Vip");
		}
		public set(bool val) {
			this.SetBool("Vip", val);
		}
	}
	/**
	 * Параметр перчаток, принимает и выдает только существующие энтити, иначе -1
		get
			-1 - нет перчаток
			>1 - индекс существующих перчаток (гарантировано)
		set 
			-1 - удалить перчатки, если существуют
			>1 - установить перчатки, с проверкой на существование
	*/
	property int GloveEntity {
		public get() {
			if(CheckGlove(this.GetInt("Glove"))) {
				return this.GetInt("Glove");
			} else {
				return -1;
			}
		}
		public set(int val)	{
			if(val < 1) { // Удаление перчаток
				if (!this.IsValid)return;
				int client = this.Client;
				int glove = this.GetInt("Glove"); // Почему то до этого места геттер еще не доступен
		
				if(client>0 &&IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client)) {
					int wear = GetEntPropEnt(client, Prop_Send, "m_hMyWearables");
					if(wear != -1 && CheckGlove(wear)) {
						AcceptEntityInput(wear, "Kill");
						if(wear == glove) glove = -1;
					}
				}
				if(glove != -1 && CheckGlove(glove)) {
					AcceptEntityInput(glove, "Kill");
				}
				this.SetInt("Glove", -1);
			} else { // Установка перчаток
				if(CheckGlove(val)) {
					this.SetInt("Glove", val);
				}
			}
		}
	}
	
	property int GloveModelCT {
		public get() {
			return this.GetInt("ModelCT");
		}
		public set(int val) {
			this.SetInt("ModelCT", val);
			char buff[10];
			IntToString(val, buff, sizeof(buff));
			SetClientCookie(this.Client, gg.ModelCookieCT, buff);
		}
	}
	property int GloveModelT {
		public get() {
			return this.GetInt("ModelT");
		}
		public set(int val) {
			this.SetInt("ModelT", val);
			char buff[10];
			IntToString(val, buff, sizeof(buff));
			SetClientCookie(this.Client, gg.ModelCookieT, buff);
		}
	}
	/* Вернет индекс модели перчаток, в зависимости от команды
		-3 - Без перчаток
		-2 - Рандомная модель, с учётом вип статуса
		-1 - Дефолтная модель, с учётом вип статуса
		>0 - Индекс перчаток
	*/
	public int GetGloveModel(int team = -1) {
		if(team != -1) {
			if(team == 2) {
				return this.GloveModelT;
			} else {
				return this.GloveModelCT;
			}
		} else {
			if(gg.TeamDivided) {
				switch(GetClientTeam(this.Client)) {
					case 2: {
						return this.GloveModelT;
					}
					default: {
						return this.GloveModelCT;
					}
				}
			} else {
				return this.GloveModelCT;
			}
		}
		return -1;
	}
	public void SetGloveModel(int val, int team = -1) {
		if (val < -3)val = -3;
		if(team != -1) {
			if(team == 2) {
				this.GloveModelT = val;
			} else {
				this.GloveModelCT = val;
			}
		} else {
			if(gg.TeamDivided) {
				switch(GetClientTeam(this.Client)) {
					case 2: {
						this.GloveModelT = val;
					}
					default: {
						this.GloveModelCT = val;
					}
				}
			} else {
				this.GloveModelCT = val;
			}
		}
	}
	
	property int GloveSkinCT {
		public get() {
			return this.GetInt("SkinCT");
		}
		public set(int val) {
			this.SetInt("SkinCT", val);
			char buff[10];
			IntToString(val, buff, sizeof(buff));
			SetClientCookie(this.Client, gg.SkinCookieCT, buff);
		}
	}
	property int GloveSkinT	{
		public get() {
			return this.GetInt("SkinT");
		}
		public set(int val) {
			this.SetInt("SkinT", val);
			char buff[10];
			IntToString(val, buff, sizeof(buff));
			SetClientCookie(this.Client, gg.SkinCookieT, buff);
		}
	}
	public int GetGloveSkin(int team = -1) {
		if(team != -1) {
			if(team == 2) {
				return this.GloveSkinT;
			} else {
				return this.GloveSkinCT;
			}
		} else {
			if(gg.TeamDivided) {
				switch(GetClientTeam(this.Client)) {
					case 2: {
						return this.GloveSkinT;
					}
					default: {
						return this.GloveSkinCT;
					}
				}
			} else {
				return this.GloveSkinCT;
			}
		}
		return -1;
	}
	public void SetGloveSkin(int val, int team = -1) {
		if (val < -3)val = -3;
		if(team != -1) {
			if(team == 2) {
				this.GloveModelT = val;
			} else {
				this.GloveSkinCT = val;
			}
		} else {
			if(gg.TeamDivided) {
				switch(GetClientTeam(this.Client)) {
					case 2: {
						this.GloveSkinT = val;
					}
					default: {
						this.GloveSkinCT = val;
					}
				}
			} else {
				this.GloveSkinCT = val;
			}
		}
	}
	
	property int GloveQuality {
		public get() {
			return this.GetInt("Quality");
		}
		public set(int val) {
			this.SetInt("Quality", val);
			char buff[10];
			IntToString(val, buff, sizeof(buff));
			SetClientCookie(this.Client, gg.QualityCookie, buff);
		}
	}
	public void DumpHolder(int client = -1) {
		if (client == -1)client = this.Client;
		PrintToChat(client, "[GLOVES] GloveHolder[%d] -> GloveModelCT: %d GloveModelT: %d GloveSkinCT: %d GloveSkinT: %d Quality: %d", this.Client, this.GloveModelCT, this.GloveModelT, this.GloveSkinCT, this.GloveSkinT, this.GloveQuality);
		
		char buff[12];
		int type[2], skin[2], quality;
		
		GetClientCookie(this.Client, gg.ModelCookieCT, buff, sizeof(buff));
		type[0] = StringToInt(buff);
		GetClientCookie(this.Client, gg.SkinCookieCT, buff, sizeof(buff));
		skin[0] = StringToInt(buff);
		GetClientCookie(this.Client, gg.QualityCookie, buff, sizeof(buff));
		quality = StringToInt(buff);
			
		if(gg.TeamDivided) {
			GetClientCookie(this.Client, gg.ModelCookieT, buff, sizeof(buff));
			type[1] = StringToInt(buff);
			GetClientCookie(this.Client, gg.SkinCookieT, buff, sizeof(buff));
			skin[1] = StringToInt(buff);
		 }
		PrintToChat(client, "[GLOVES] GloveHolder[%d] -> CookieModelCT: %d CookieModelT: %d CookieSkinCT: %d CookieSkinT: %d Quality: %d", this.Client, type[0], type[1], skin[0], skin[1], quality);
	}
	
	public void ResetGlove(bool nothing = false, bool inform = true, char[] forcegroup = "") {
		int team = GetClientTeam(this.Client);
		if(nothing) {
			this.SetGloveModel(-3);
			this.SetGloveSkin(-3);
		} else {
			if(StrEqual(forcegroup, "")) {
				this.SetGloveModel(-1);
				this.SetGloveSkin(-1);
			} else {
				this.SetGloveModel(gs.GetDefaultModel(forcegroup, team));
				this.SetGloveSkin(gs.GetDefaultSkin(forcegroup, team));
			}
		}
		this.GloveQuality = 100;
		
		if(inform) {
			if(!nothing && team > 1) {
				char buff2[50], buff3[50];
				int tempmodel = -3;
				int tempskin = -3;
				char group[16] = "";
				if(gg.VipLoaded && VIP_IsClientVIP(this.Client)) {
					VIP_GetClientVIPGroup(this.Client, group, sizeof(group));
				}
				if(StrEqual(forcegroup, "")) {
					tempmodel = gs.GetDefaultModel(group, team);
					tempskin = gs.GetDefaultSkin(group, team);
				} else {
					tempmodel = gs.GetDefaultModel(forcegroup, team);
					tempskin = gs.GetDefaultSkin(forcegroup, team);
				}
			
				if(tempmodel != -3) {
					gs.ModelName(tempmodel, buff2, sizeof(buff2));
					gs.SkinName(tempmodel, tempskin, buff3, sizeof(buff3));
					PrintToChat(this.Client, "%s %t", Tag, "ResetTeam", Clr, buff2, buff3, 1);
				} else {
					PrintToChat(this.Client, "%s %t", Tag, "Reset");
				}
			} else {
				PrintToChat(this.Client, "%s %t", Tag, "Reset");
			}
		}
	}
	public bool SaveGlove(int model = -10, int skin = -10, int quality = -10, bool inform = false) {
		if(!IsClientConnected(this.Client) && !IsClientInGame(this.Client)) return;
		
		if(gs.CheckModel(model)) {
			char buff2[50];			
			this.SetGloveModel(model);
			if(gs.CheckSkin(model, skin)) {
				int limit = GloveAccess(this.Client, model, skin);
				if(limit == 0) {
					this.ResetGlove(_, false);
					PrintToChat(this.Client, "%s %t", Tag, "NoAccess", Clr, 1);
				} else {
					char buff3[50];
					this.SetGloveSkin(skin);
					if(quality == -1 && this.GloveQuality == -1)
						this.GloveQuality = 100;
					gs.ModelName(model, buff2, sizeof(buff2));
					gs.SkinName(model, skin, buff3, sizeof(buff3));
					if(inform) PrintToChat(this.Client, "%s %t", Tag, "GloveSave", Clr, buff2, buff3, 1);
					if(limit > 0 && limit != 100) {
						PrintToChat(this.Client, "%s %t", Tag, "LimitQuality", Clr, 1, Clr, limit, 1);
					}
					
				}
			} else if(skin == -2){
				gs.ModelName(model, buff2, sizeof(buff2));
				PrintToChat(this.Client, "%s %t", Tag, "RandomSet", Clr, buff2, 1);
				this.SetGloveSkin(skin);
			} else {
				PrintToServer("[GLOVES] Invalid data save! Parameters: %d %d %d %d %d", this.Client, model, skin, quality, inform);
			}
		}
		
		if(quality != -10) {
			this.GloveQuality = quality;
			PrintToChat(this.Client, "%s %t", Tag, "QualitySave", Clr, quality, 1);
			if(skin != -10) {
				int limit = GloveAccess(this.Client, this.GetGloveModel(), this.GetGloveSkin());
				if(limit == 0) {
					PrintToChat(this.Client, "%s %t", Tag, "RestrictQuality");
				} else if(limit > 0) {
					if(quality>limit) {
						PrintToChat(this.Client, "%s %t", Tag, "LimitQuality2", Clr, 1, Clr, limit, 1);
					}
				}
			}
		}
	}
	public bool SetGlove(int type = 0) {
		if (this.Client <= 1 || !IsClientConnected(this.Client) || !IsClientInGame(this.Client) || IsFakeClient(this.Client))
			return false;
		char group[16];
		if(gg.VipLoaded && this.Vip) {
			VIP_GetClientVIPGroup(this.Client, group, sizeof(group));
		}
		int model = this.GetGloveModel(), skin = this.GetGloveSkin(), quality = this.GloveQuality;
		//PrintDebug("SetGlove Pre -> model: %d skin: %d quality: %d team: %d group: %s", model, skin, quality, GetClientTeam(this.Client), group);
		if(model != -3) {
			if(model == -1) {
				model = gs.GetDefaultModel(group, GetClientTeam(this.Client));
			}
			if(skin == -1) {
				skin = gs.GetDefaultSkin(group, GetClientTeam(this.Client));
			}
			
			if(model != -3 || skin != -3) {
				int limit = (skin<1)?100:GloveAccess(this.Client, model, skin);
				if(skin == -2) {
					static int tries = 0;
					do {
						skin = gs.RandomSkin(model);
						limit = GloveAccess(this.Client, model, skin);
					} while (tries++ < 10 && (limit == 0));
					if(tries > 9 && limit == 0) {
						PrintToChat(this.Client, "%s %t", Tag, "NoAccess", Clr, 1);
						this.ResetGlove();
						SetGlove2(this);
						return false;
					}
					tries = 0;
				}
				if(quality == -1) {
					if(this.GloveQuality != -1)	quality = this.GloveQuality;
					else quality = 100;
					
					if(limit == 0) {
						PrintToChat(this.Client, "%s %t", Tag, "NoAccess", Clr, 1);
						this.ResetGlove();
						SetGlove2(this);
						return false;
					} else if(limit > 0 && quality > limit) {
						quality = limit;
					}
				}
			}
		}
		//PrintDebug("SetGlove Post -> model: %d skin: %d quality: %d team: %d group: %s", model, skin, quality, GetClientTeam(this.Client), group);
		this.GloveEntity = -1; // Удаляет прикрепленные перчатки, если есть
				
		if(model > 0 && skin > 0) {
			int ent = CreateEntityByName("wearable_item");
			if(ent != -1 && CheckGlove(ent)) {
				this.GloveEntity = ent;
				SetEntPropEnt(this.Client, Prop_Send, "m_hMyWearables", ent);
				SetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex", model);
				SetEntProp(ent, Prop_Send,  "m_nFallbackPaintKit", skin);
				SetEntPropFloat(ent, Prop_Send, "m_flFallbackWear", 1.0-quality*0.01); // Качество, больше = хуже
				SetEntProp(ent, Prop_Send, "m_iItemIDLow", 2048); // Что-то важное, вроде может быть любым значением кроме 0
				SetEntProp(ent, Prop_Send, "m_bInitialized", 1); // Убирает "[Wearables (server)(230)] Failed to set model for wearable!"
				SetEntPropEnt(ent, Prop_Data, "m_hParent", this.Client); // Прикрепление к игроку, без этого работать не будет
				SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", this.Client); // Прикрепление к игроку, без этого работать не будет
				if(gg.ThirdPerson) {
					SetEntPropEnt(ent, Prop_Data, "m_hMoveParent", this.Client); // Устанавливает для 3 лица
					SetEntProp(this.Client, Prop_Send, "m_nBody", 1); // Убирает стандартные перчатки в 3 лице
				}
				DispatchSpawn(ent);
			}
		} else {
			SetEntProp(this.Client, Prop_Send, "m_nBody", 0);
		}
		int item = GetEntPropEnt(this.Client, Prop_Send, "m_hActiveWeapon");		
		SetEntPropEnt(this.Client, Prop_Send, "m_hActiveWeapon", -1); 		
		DataPack ph = new DataPack();		
		WritePackCell(ph, EntIndexToEntRef(this.Client));		
		if(IsValidEntity(item))	WritePackCell(ph, EntIndexToEntRef(item));		
		else WritePackCell(ph, -1);		
		CreateTimer(0.0, AddItemTimer, ph, TIMER_FLAG_NO_MAPCHANGE); 
		
		return true;
	}
	public bool LoadFromCookie() {
		if (gg.IsValid) {
			char buff[12];
			int type[2], skin[2], quality;
		
			GetClientCookie(this.Client, gg.ModelCookieCT, buff, sizeof(buff));
			type[0] = StringToInt(buff);
			GetClientCookie(this.Client, gg.SkinCookieCT, buff, sizeof(buff));
			skin[0] = StringToInt(buff);
			GetClientCookie(this.Client, gg.QualityCookie, buff, sizeof(buff));
			quality = StringToInt(buff);
			
			if(quality<0 || quality >100) this.GloveQuality = 100;
			else this.GloveQuality = quality;
			
			if(skin[0] == 0) { // куки ни разу не устанавливались
				this.GloveModelCT = -1;
				this.GloveSkinCT = -1;
				this.GloveQuality = -1;
			} else {
				this.GloveModelCT = type[0];
				this.GloveSkinCT = skin[0];
		 	}
			
			if(gg.TeamDivided) {
				GetClientCookie(this.Client, gg.ModelCookieT, buff, sizeof(buff));
				type[1] = StringToInt(buff);
				GetClientCookie(this.Client, gg.SkinCookieT, buff, sizeof(buff));
				skin[1] = StringToInt(buff);
				if(skin[1] == 0) { // куки ни разу не устанавливались
					this.GloveModelT = -1;
					this.GloveSkinT = -1;
				} else {
					this.GloveModelT = type[1];
					this.GloveSkinT = skin[1];
				}
		 	}
		 	return true;
		}
		return false;
	}
	public void ClearData(int client = -1, bool vip = true) {
		this.SetInt("Client", client);
		this.SetBool("Vip", vip);
		this.SetInt("Glove", -1);
		this.SetInt("ModelCT", -3);
		this.SetInt("ModelT", -3);
		this.SetInt("SkinCT", -3);
		this.SetInt("SkinT", -3);
		this.SetInt("Quality", 100);
	}
}
stock void DumpDefaults(GloveStorage obj) {
	PrintToServer("[GLOVES] DumpDefaults started.");
	if(obj.IsValid) {
		Dynamic df = obj.Defaults;
		if(df.IsValid) {
			DumpDynamic(df, true, "DEFAULTS");
		} else {
			PrintToServer("[GLOVES] Not valid Defaults object.");
		}
	} else {
		PrintToServer("[GLOVES] Not valid GloveStorage object.");
	}
}
/**
 * Go through each Dynamic member, print member's type and value.
 * Dynamic obj - object to scan
 * bool traversal - scan dynamic-member
 */
stock void DumpDynamic(Dynamic obj, bool traversal = false, char[] prefix = "") {
	int count = obj.MemberCount;
	char membername[DYNAMIC_MEMBERNAME_MAXLEN];
	PrintToServer("> Dump Dynamic: %d", obj);
	PrintToServer("> obj.MemberCount=%d", obj.MemberCount);
	
	for (int i = 0; i < count; i++)
	{
		DynamicOffset memberoffset = obj.GetMemberOffsetByIndex(i);
		
		obj.GetMemberNameByIndex(i, membername, sizeof(membername));
		
		switch (obj.GetMemberType(memberoffset))
		{
			case DynamicType_Int:
			{
				int someint = obj.GetIntByOffset(memberoffset);
				PrintToServer("%s[%d] <int>obj.%s = %d", prefix, memberoffset, membername, someint);
			}
			case DynamicType_Bool:
			{
				bool somebool = obj.GetBoolByOffset(memberoffset);
				PrintToServer("%s[%d] <bool>obj.%s = %d", prefix, memberoffset, membername, somebool);
			}
			case DynamicType_Float:
			{
				float somefloat = obj.GetFloatByOffset(memberoffset);
				PrintToServer("%s[%d] <float>obj.%s = %f", prefix, memberoffset, membername, somefloat);
			}
			case DynamicType_String:
			{
				char somestring[64];
				obj.GetStringByOffset(memberoffset, somestring, sizeof(somestring));
				PrintToServer("%s[%d] <string>obj.%s = '%s'", prefix, memberoffset, membername, somestring);
			}
			case DynamicType_Object:
			{
				Dynamic anotherobj = obj.GetDynamicByOffset(memberoffset);
				PrintToServer("%s[%d] <dynamic>.<int>obj.%s.members = %d", prefix, memberoffset, membername, anotherobj.MemberCount);
				if(traversal) {
					char buff[16];
					Format(buff, sizeof(buff), "%s>>> ", buff);
					DumpDynamic(anotherobj, true, buff);
				}
			}
			case DynamicType_Handle:
			{
				Handle somehandle = obj.GetHandleByOffset(memberoffset);
				PrintToServer("%s[%d] <Handle>.obj.%s = %d", prefix,  memberoffset, membername, somehandle);
			}
			case DynamicType_Vector:
			{
				float somevec[3];
				obj.GetVectorByOffset(memberoffset, somevec);
				PrintToServer("%s[%d] <Vector>.obj.%s = {%f, %f, %f}", prefix,  memberoffset, membername, somevec[0], somevec[1], somevec[2]);
			}
		}
	}
}
stock void SetGlove2(GloveHolder gh2) {
	gh2.SetGlove();
}
stock Action AddItemTimer(Handle timer, DataPack ph) {
    int client, item;
    ResetPack(ph);
    client = EntRefToEntIndex(ReadPackCell(ph));
    item = EntRefToEntIndex(ReadPackCell(ph));
    if (client != INVALID_ENT_REFERENCE && item != INVALID_ENT_REFERENCE) {
        SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", item);
    }
    CloseHandle(ph);
    return Plugin_Stop;
}
stock bool CheckGlove(int ent)	{
	static char weaponclass[32];
	if(ent <= 0 || !IsValidEdict(ent)) return false;
	if (!GetEdictClassname(ent, weaponclass, sizeof(weaponclass))) return false;
	if(StrContains(weaponclass, "wearable", false) == -1) return false;
	return true;
}
stock int GloveAccess(int client, int model, int skin) {
	if (!gg.IsValid)return 0;
	if(gg.VipLoaded && VIP_IsClientVIP(client)) return -1; 
	int team = GetClientTeam(client);
	if (model == gs.GetDefaultModel("", team) && skin == gs.GetDefaultSkin("", team))return 100;
	int limit = gs.SkinLimit(model, skin);
	if (limit == -1) return 100;
	else return limit;
}