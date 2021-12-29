
ConVar gCVar_Gravity;
float gF_Gravity = 400.0;

/**
 * 判断当前比赛是否为低重力
 */
bool CheckRaceType_LowGravity()
{
	return GOKZ_Fun_Race_GetCurrentRaceType() == RaceType_LowGravity;
}

//////////////////
//	   事件	  //
//////////////////
void OnPluginStart_LowGravity()
{
	gCVar_Gravity = FindConVar("sv_gravity");
	for(int client = 1; client < MAXCLIENTS; client++)
	{
		if(IsValidClient(client))
		{
			SDKHook(client, SDKHook_PreThinkPost, SDKHook_OnClientPreThinkPost);
		}
	}
}

void OnClientPutInServer_LowGravity(int client)
{
	SDKHook(client, SDKHook_PreThinkPost, SDKHook_OnClientPreThinkPost);
}

void OnTimerEnd_LowGravity(int client, float time, int cp)
{
	if(!CheckRaceType_LowGravity())
	{
		return;
	}

	GOKZ_PrintToChatAll(true, "%s玩家 %s%N %s完成地图! %s[%s | %d TP]", gC_Colors[Color_Green], gC_Colors[Color_Purple], client, gC_Colors[Color_Green], gC_Colors[Color_Yellow], GOKZ_FormatTime(time), cp);
	GOKZ_Fun_Race_FinishRace(client);
}


//////////////////
//	   Hook	 //
//////////////////
public void SDKHook_OnClientPreThinkPost(int client)
{
	// 判断玩家状态、比赛项目
	if (!IsPlayerAlive(client) || !CheckRaceType_LowGravity() || !GOKZ_Fun_Race_IsRacer(client) || GOKZ_Fun_Race_IsRacerFinished(client) || !GOKZ_GetTimerRunning(client))
	{
		return;
	}

	gCVar_Gravity.FloatValue = gF_Gravity;

}