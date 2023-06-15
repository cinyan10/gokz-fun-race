enum struct Zone
{
	// struct不允许多维数组

	// 区域对角坐标原点
	float pointA[3];
	float pointB[3];
	// 区域边界
	float clampMin[3];
	float clampMax[3];

	// 边的绘制起点/终点
	// 从相互间隔两条边的4个顶点出发
	// 4 * 4 * 3 = 48
	float drawStartEnd[48];

	int GetDrawStartEndIndex(int startIndex, int endIndex, int dimension)
	{
		return startIndex * 12 + endIndex * 3 + dimension;
	}

	void SetPoint(bool isA, float point[3])
	{
		float offset[3]; // 区域左下角到右上角的偏移
		for(int i = 0; i < 3; i++)
		{
			if(isA)
			{
				this.pointA[i] = point[i];
			}
			else
			{
				this.pointB[i] = point[i];
			}
			// 更新区域边界
			this.clampMin[i] = this.pointA[i] < this.pointB[i] ? this.pointA[i] : this.pointB[i];
			this.clampMax[i] = this.pointA[i] > this.pointB[i] ? this.pointA[i] : this.pointB[i];
			offset[i] = this.clampMax[i] - this.clampMin[i];
		}

		for(int i = 0; i < 4; i++)
		{
			// 设置边起点
			for(int j = 0; j < 3; j++)
			{
				this.drawStartEnd[this.GetDrawStartEndIndex(i, 0, j)] = this.clampMin[j] + offset[j] * (gB_PointStartOffsets[i][j] ? 1 : 0);
				this.drawStartEnd[this.GetDrawStartEndIndex(i, 1, j)] = this.drawStartEnd[this.GetDrawStartEndIndex(i, 2, j)] = this.drawStartEnd[this.GetDrawStartEndIndex(i, 3, j)] = this.drawStartEnd[this.GetDrawStartEndIndex(i, 0, j)];
			}

			// 设置边终点
			for(int k = 0; k < 3; k++)
			{
				this.drawStartEnd[this.GetDrawStartEndIndex(i, k+1, k)] += offset[k] * (gB_PointStartOffsets[i][k] ? -1 : 1);
			}
		}
	}

	void SetPointA(float point[3])
	{
		this.SetPoint(true, point);
	}

	void SetPointB(float point[3])
	{
		this.SetPoint(false, point);
	}

	bool Contains(int client)
	{
		if(!IsValidClient(client))
		{
			return false;
		}

		if(!IsPlayerAlive(client))
		{
			return false;
		}

		float origin[3], min[3], max[3];
		// 获取玩家世界坐标
		GetClientAbsOrigin(client, origin);
		// 获取玩家碰撞箱边界
		GetClientMins(client, min);
		GetClientMaxs(client, max);

		for(int i = 0; i < 3; i++)
		{
			// 更新玩家碰撞箱为世界坐标
			min[i] += origin[i];
			max[i] += origin[i];
			// 若玩家碰撞箱不在区域内
			if(min[i] > this.clampMax[i] || max[i] < this.clampMin[i])
			{
				return false;
			}
		}

		return true;
	}

	void SendToPlayer(int client)
	{
		if(!IsValidClient(client))
		{
			return;
		}

		float start[3], end[3];
		for(int i = 0; i < 4; i++)
		{
			int drawStartIndex = this.GetDrawStartEndIndex(i, 0, 0);
			for(int j = 0; j < 3; j++)
			{
				start[j] = this.drawStartEnd[drawStartIndex + j];
			}
			for(int j = 1; j < 4; j++)
			{
				for(int k = 0; k < 3; k++)
				{
					end[k] = this.drawStartEnd[drawStartIndex + j * 3 + k];
				}
				TE_SetupBeamPoints(start, end, gI_BeamMaterialIndex, 0, 0, 0, BEAM_LIFETIME, BEAM_WIDTH, BEAM_WIDTH, 0, 0.0, COLOR_GREEN, 0);
				TE_SendToClient(client);
			}
		}
	}
}


void  OnMapStart_Zone()
{
	gI_BeamMaterialIndex = PrecacheModel("materials/sprites/laser.vmt", true);
}