void RegisterCommands()
{
	RegConsoleCmd("sm_funrace", CommandFunRace, "Open fun race menu");
	RegConsoleCmd("sm_fr", CommandFunRace, "sm_funrace abbr");
	RegConsoleCmd("sm_bm", CommandFunRaceAccept, "Accept current fun race");
	RegConsoleCmd("sm_fq", CommandFunRaceSurrender, "Surrender in current Fun Race");
}

// 主指令
public Action CommandFunRace(int client, int args)
{
	// 仅OP可用
	if(IsValidClient(client) && GetUserAdmin(client) != INVALID_ADMIN_ID)
	{
		// 打开主菜单
		OpenFunRaceMenu(client);
	}
	return Plugin_Handled;
}

// 报名指令
public Action CommandFunRaceAccept(int client, int args)
{
	if(IsValidClient(client))
	{
		// 比赛状态是否为报名中
		if(GOKZ_Fun_Race_GetCurrentRaceStatus() == RaceStatus_Waiting)
		{
			// 如果已经参赛
			if(GOKZ_Fun_Race_IsRacer(client))
			{
				GOKZ_PrintToChat(client, true, "%s您已经是本项目的参赛者了.", gC_Colors[Color_Red]);
				GOKZ_PlayErrorSound(client);
			}
			else
			{
				// 否则报名
				GOKZ_Fun_Race_AddRacer(client);
				GOKZ_PrintToChat(client, true, "%s报名成功!", gC_Colors[Color_Green]);
			}
		}
		else
		{
			// 否则无法报名
			GOKZ_PrintToChat(client, true, "%s现在不能报名比赛", gC_Colors[Color_Red]);
			GOKZ_PlayErrorSound(client);
		}
	}
	return Plugin_Handled;
}

// 弃权指令
public Action CommandFunRaceSurrender(int client, int args)
{
	if(IsValidClient(client))
	{
		// 如果现在是比赛状态且是参赛者
		if(GOKZ_Fun_Race_GetCurrentRaceStatus() != RaceStatus_End && GOKZ_Fun_Race_IsRacer(client))
		{
			// 如果参赛者未完赛
			if(!GOKZ_Fun_Race_IsRacerFinished(client))
			{
				GOKZ_Fun_Race_SurrenderRace(client);
			}
			else
			{
				GOKZ_PrintToChat(client, true, "%s您已经完成了比赛", gC_Colors[Color_Green]);
			}
		}
		else
		{
			GOKZ_PrintToChat(client, true, "%s您不在比赛中", gC_Colors[Color_Red]);
			GOKZ_PlayErrorSound(client);
		}
	}
	return Plugin_Handled;
}