
Menu gH_FunRaceChooseEventMenu;
Menu gH_FunRaceChooseCourseMenu;
Menu gH_FunRaceChooseModeMenu;

RaceType gI_RaceTypeChoose[MAXCLIENTS];
int gI_RaceCourseChoose[MAXCLIENTS];
int gI_RaceModeChoose[MAXCLIENTS];




// -------- [ 事件 ] --------
public void OnPluginStart_Menu()
{
	// 初始化比赛项目选择菜单
	gH_FunRaceChooseEventMenu = CreateMenu(FunRaceChooseEventMenuHandler);
	SetMenuTitle(gH_FunRaceChooseEventMenu, "==[ 项目选择 ]==");
	// 遍历比赛项目
	for(int index = 1; index < view_as<int>(RACETYPE_COUNT); index++)
	{
		AddMenuItem(gH_FunRaceChooseEventMenu, IntToStringEx(index), gC_RaceTypeName[index]);
	}


	gH_FunRaceChooseCourseMenu = CreateMenu(FunRaceChooseCourseMenuHandler);
	SetMenuTitle(gH_FunRaceChooseEventMenu, "==[ 关卡选择 ]==");
	// 关卡检测有点问题

	// int course = 0;
	// while(GOKZ_GetCourseRegistered(course))
	// {
	//	 char displayName[16] = "主关";
	//	 if(course > 0)
	//	 {
	//		 Format(displayName, sizeof(displayName), "奖励-%d", course);
	//	 }
	//	 AddMenuItem(gH_FunRaceChooseCourseMenu, IntToStringEx(course), displayName);
	//	 course++;
	// }

	gH_FunRaceChooseModeMenu = CreateMenu(FunRaceChooseModeMenuHandler);
	SetMenuTitle(gH_FunRaceChooseEventMenu, "==[ 模式选择 ]==");
	// 根据gokz.inc里是3个，应该不会出BUG
	for(int mode = 0; mode < 3; mode++)
	{
		AddMenuItem(gH_FunRaceChooseModeMenu, IntToStringEx(mode), gC_ModeNames[mode]);
	}

	// 初始化变量
	for(int client = 1; client < MAXCLIENTS; client++)
	{
		if(IsValidClient(client))
		{
			gI_RaceTypeChoose[client] = RaceType_SpaceOnly;
			gI_RaceCourseChoose[client] = 0;
			gI_RaceModeChoose[client] = 2;
		}
	}
}


/**
  * 打开主菜单
  */
void OpenFunRaceMenu(int client)
{
	// 判断当前比赛状态
	RaceStatus status = GOKZ_Fun_Race_GetCurrentRaceStatus();
	switch(status)
	{
		// 没有比赛
		case(RaceStatus_End):
		{
			OpenFunRaceSetupMenu(client);
		}
		// 正在等待玩家参与比赛
		case(RaceStatus_Waiting):
		{
			OpenFunRaceStartMenu(client);
		}
		// 比赛进行中
		case(RaceStatus_Running):
		{
			OpenFunRaceRunningMenu(client);
		}
	}
}

/**
  * 打开发起比赛菜单
  */
void OpenFunRaceSetupMenu(int client)
{
	Menu menu = CreateMenu(FunRaceMainMenuHandler);
	SetMenuTitle(menu, "==[ 趣味比赛 ]==");
	AddMenuItem(menu, "setup", "发起比赛");

	// 获取比赛项目配置
	char displayName[128];
	Format(displayName, sizeof(displayName), "比赛项目 - %s", gC_RaceTypeName[gI_RaceTypeChoose[client]]);
	AddMenuItem(menu, "event", displayName);

	// 获取关卡配置
	char courseName[16] = "主关";
	if(gI_RaceCourseChoose[client] > 0)
	{
		Format(displayName, sizeof(displayName), "奖励-%d", gI_RaceCourseChoose[client]);
	}
	Format(displayName, sizeof(displayName), "比赛关卡 - %s", courseName);
	AddMenuItem(menu, "course", displayName, ITEMDRAW_DISABLED);

	// 获取模式配置
	Format(displayName, sizeof(displayName), "比赛模式 - %s", gC_ModeNames[gI_RaceModeChoose[client]]);
	AddMenuItem(menu, "mode", displayName);

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

/**
  * 打开开始比赛菜单
  */
void OpenFunRaceStartMenu(int client)
{
	Menu menu = CreateMenu(FunRaceStartMenuHandler);
	SetMenuTitle(menu, "==[ 趣味比赛 ]==");
	AddMenuItem(menu, "start", "开始比赛");
	AddMenuItem(menu, "cancel", "取消比赛");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

/**
  * 打开比赛控制菜单 
  */
void OpenFunRaceRunningMenu(int client)
{
	Menu menu = CreateMenu(FunRaceRunningMenuHandler);
	SetMenuTitle(menu, "==[ 趣味比赛 ]==");
	// 判断比赛暂停状态
	if(GOKZ_Fun_Race_IsRacePause())
	{
		AddMenuItem(menu, "resume", "恢复比赛");
	}
	else
	{
		AddMenuItem(menu, "pause", "暂停比赛");
	}
	
	AddMenuItem(menu, "end", "结束比赛");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}




// -------- [ 菜单 ] --------

// 选择比赛项目菜单
FunRaceChooseEventMenuHandler(Handle:menu, MenuAction:action, client, select)
{
	if(action == MenuAction_Select)
	{
		char info[16];
		GetMenuItem(menu, select, info, sizeof(info));
		gI_RaceTypeChoose[client] = view_as<RaceType>(StringToInt(info));
		OpenFunRaceMenu(client);
	}
}

// 选择比赛关卡菜单
FunRaceChooseCourseMenuHandler(Handle:menu, MenuAction:action, client, select)
{
	if(action == MenuAction_Select)
	{
		char info[16];
		GetMenuItem(menu, select, info, sizeof(info));
		gI_RaceCourseChoose[client] = StringToInt(info);
		OpenFunRaceMenu(client);
	}
}

// 选择比赛模式菜单
FunRaceChooseModeMenuHandler(Handle:menu, MenuAction:action, client, select)
{
	if(action == MenuAction_Select)
	{
		char info[16];
		GetMenuItem(menu, select, info, sizeof(info));
		gI_RaceModeChoose[client] = StringToInt(info);
		OpenFunRaceMenu(client);
	}
}

// 发起比赛菜单
FunRaceMainMenuHandler(Handle:menu, MenuAction:action, client, select)
{
	// 如果是选择了某个项目
	if(action == MenuAction_Select)
	{
		// 如果当前比赛状态与菜单功能不符合
		if(GOKZ_Fun_Race_GetCurrentRaceStatus() != RaceStatus_End)
		{
			// 则重新打开菜单
			GOKZ_PrintToChat(client, true, "比赛状态已改变!");
			GOKZ_PlayErrorSound(client);
		}
		else
		{
			// 否则获取选中条目的内容
			char info[16];
			GetMenuItem(menu, select, info, sizeof(info));
			// 如果选择发起比赛
			if(!strcmp(info, "setup"))
			{
				GOKZ_Fun_Race_SetupRace(client, gI_RaceTypeChoose[client], gI_RaceCourseChoose[client], gI_RaceModeChoose[client]);
				OpenFunRaceMenu(client);
			}
			else if(!strcmp(info, "event"))
			{
				DisplayMenu(gH_FunRaceChooseEventMenu, client, MENU_TIME_FOREVER);
			}
			else if(!strcmp(info, "course"))
			{
				DisplayMenu(gH_FunRaceChooseCourseMenu, client, MENU_TIME_FOREVER);
			}
			else if(!strcmp(info, "mode"))
			{
				DisplayMenu(gH_FunRaceChooseModeMenu, client, MENU_TIME_FOREVER);
			}
		}
	}
}

// 开始比赛菜单
FunRaceStartMenuHandler(Handle:menu, MenuAction:action, client, select)
{
	if(action == MenuAction_Select)
	{
		if(GOKZ_Fun_Race_GetCurrentRaceStatus() != RaceStatus_Waiting)
		{
			GOKZ_PrintToChat(client, true, "比赛状态已改变!");
			GOKZ_PlayErrorSound(client);
		}
		else
		{
			char info[16];
			GetMenuItem(menu, select, info, sizeof(info));
			if(!strcmp(info, "start"))
			{
				GOKZ_Fun_Race_StartRace(client);
			}
			else if(!strcmp(info, "cancel"))
			{
				GOKZ_Fun_Race_EndRace(client, "比赛取消");
				OpenFunRaceMenu(client);
			}
		}
	}
}

// 进行中比赛菜单
FunRaceRunningMenuHandler(Handle:menu, MenuAction:action, client, select)
{
	if(action == MenuAction_Select)
	{
		if(GOKZ_Fun_Race_GetCurrentRaceStatus() != RaceStatus_Running)
		{
			GOKZ_PrintToChat(client, true, "比赛状态已改变!");
			GOKZ_PlayErrorSound(client);
		}
		else
		{
			char info[16];
			GetMenuItem(menu, select, info, sizeof(info));
			if(!strcmp(info, "pause"))
			{
				if(!GOKZ_Fun_Race_IsRacePause())
				{
					GOKZ_Fun_Race_PauseRace(client);
				}
			}
			else if(!strcmp(info, "resume"))
			{
				if(GOKZ_Fun_Race_IsRacePause())
				{
					GOKZ_Fun_Race_ResumeRace(client);
				}
			}
			else if(!strcmp(info, "end"))
			{
				GOKZ_Fun_Race_EndRace(client, "强制结束比赛");
			}
		}
		OpenFunRaceMenu(client);
	}
}