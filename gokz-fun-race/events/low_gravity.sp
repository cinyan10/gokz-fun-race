
ConVar gCVar_Gravity;
float gF_Gravity = 300.0;

/**
 * 判断当前比赛是否为低重力
 */
bool CheckRaceType_LowGravity()
{
	return GOKZ_Fun_Race_GetCurrentRaceStatus() == RaceStatus_Running && GOKZ_Fun_Race_GetCurrentRaceType() == RaceType_LowGravity;
}

// -------- [ 事件 ] --------
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


// -------- [ 钩子 ] --------
public void SDKHook_OnClientPreThinkPost(int client)
{
	// 判断玩家状态、比赛项目
	if (!IsPlayerAlive(client) || !CheckRaceType_LowGravity() || !GOKZ_Fun_Race_IsRacer(client) || GOKZ_Fun_Race_IsRacerFinished(client) || !GOKZ_GetTimerRunning(client))
	{
		return;
	}

	gCVar_Gravity.FloatValue = gF_Gravity;

}