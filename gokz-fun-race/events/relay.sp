


//////////////////
//		 函数		//
//////////////////

/**
 * 重置比赛状态
 * @param client 重置对象
 */
void ResetStatus_Relay(int client)
{

}

/**
 * 判断当前比赛是否为接力赛
 */
bool CheckRaceType_Relay()
{
	return GOKZ_Fun_Race_GetCurrentRaceType() == RaceType_Relay;
}

// -------- [ 事件 ] --------

void OnClientDisconnect_Relay(int client)
{
	ResetStatus_Relay(client);
}

void OnTimerStart_Relay(int client)
{
	// TODO
}

void OnTimerEnd_Relay(int client, float time)
{
	// TODO
}