
ACTION UseInternalPVs : 
	
	// Uses internal variables at least once to avoid unused variable warnings
	
	MotionProgramRob1;
	MotionProgramRob2;
	
	UserDataEmptyContainer;
	UserDataFullContainer;
	UserDataEmptyPosForContainer;
	
	repositoryAx;
	delta2Q1;
	delta2Q2;
	delta2Q3;
	delta2Qc;
	delta1Q1;
	delta1Q2;
	delta1Q3;
	delta1Qc;
	gPsm;
	Dummy_position;
	
END_ACTION

ACTION SimHome :

	MC_BR_GroupHome_0.AxesGroup := ADR(gAxesGroup_D4r1100R_1);
	MC_BR_GroupHome_1.AxesGroup := ADR(gAxesGroup_D4r1100R_2);
	MC_BR_GroupHome_0.Execute := TRUE;
	MC_BR_GroupHome_1.Execute := TRUE;
	FOR axIdx := 0 TO MAX_AXIS_IDX DO
		MC_BR_GroupHome_0.HomingMode[axIdx] := mcHOMING_DIRECT;
		MC_BR_GroupHome_0.Position[axIdx] := 0.0;
		MC_BR_GroupHome_1.HomingMode[axIdx] := mcHOMING_DIRECT;
		MC_BR_GroupHome_1.Position[axIdx] := 0.0;
	END_FOR;
	
	MC_BR_GroupHome_0();
	MC_BR_GroupHome_1();

END_ACTION

ACTION AgilityReductionInit: 
	
	// During commissioning OR testing, it is advisable TO reduce the robot’s speed settings. 
	// The provided code enables coordinated adjustment OF velocity, acceleration, AND jerk. 
	// Remember TO declare any necessary variables, as they have been omitted in the example.
	
	MC_BR_GroupSetOverride_0_R1.Type := mcOVERRIDE_VELOCITY; 
	MC_BR_GroupSetOverride_0_R1.Factor := Cmd.Settings.Robot1.AgilityReductionFactor;
	MC_BR_GroupSetOverride_0_R1.Enable := TRUE;
	      
	MC_BR_GroupSetOverride_1_R1.Type := mcOVERRIDE_ACCELERATION; 
	MC_BR_GroupSetOverride_1_R1.Factor := Cmd.Settings.Robot1.AgilityReductionFactor; 
	MC_BR_GroupSetOverride_1_R1.Enable := TRUE;
	      
	MC_BR_GroupSetOverride_2_R1.Type := mcOVERRIDE_JERK; 
	MC_BR_GroupSetOverride_2_R1.Factor := Cmd.Settings.Robot1.AgilityReductionFactor;
	MC_BR_GroupSetOverride_2_R1.Enable := TRUE;
		
	MC_BR_GroupSetOverride_0_R1(AxesGroup := ADR(gAxesGroup_D4r1100R_1)); 
	MC_BR_GroupSetOverride_1_R1(AxesGroup := ADR(gAxesGroup_D4r1100R_1));
	MC_BR_GroupSetOverride_2_R1(AxesGroup := ADR(gAxesGroup_D4r1100R_1));
	
		
	MC_BR_GroupSetOverride_0_R2.Type := mcOVERRIDE_VELOCITY; 
	MC_BR_GroupSetOverride_0_R2.Factor := Cmd.Settings.Robot2.AgilityReductionFactor;
	MC_BR_GroupSetOverride_0_R2.Enable := TRUE;
	      
	MC_BR_GroupSetOverride_1_R2.Type := mcOVERRIDE_ACCELERATION; 
	MC_BR_GroupSetOverride_1_R2.Factor := Cmd.Settings.Robot2.AgilityReductionFactor; 
	MC_BR_GroupSetOverride_1_R2.Enable := TRUE;
	      
	MC_BR_GroupSetOverride_2_R2.Type := mcOVERRIDE_JERK; 
	MC_BR_GroupSetOverride_2_R2.Factor := Cmd.Settings.Robot2.AgilityReductionFactor;
	MC_BR_GroupSetOverride_2_R2.Enable := TRUE;
		
	MC_BR_GroupSetOverride_0_R2(AxesGroup := ADR(gAxesGroup_D4r1100R_2)); 
	MC_BR_GroupSetOverride_1_R2(AxesGroup := ADR(gAxesGroup_D4r1100R_2));
	MC_BR_GroupSetOverride_2_R2(AxesGroup := ADR(gAxesGroup_D4r1100R_2));
		
END_ACTION

ACTION SpeedLimitReduction: 
	
	MC_BR_GroupSetOverride_0_R1.Type := mcOVERRIDE_VELOCITY; 
	MC_BR_GroupSetOverride_0_R1.Factor := Cmd.Settings.Robot1.SpeedLimitReductionFactor;
	MC_BR_GroupSetOverride_0_R1.Enable := TRUE;  	
	MC_BR_GroupSetOverride_0_R1(AxesGroup := ADR(gAxesGroup_D4r1100R_1)); 
		
	MC_BR_GroupSetOverride_0_R2.Type := mcOVERRIDE_VELOCITY; 
	MC_BR_GroupSetOverride_0_R2.Factor := Cmd.Settings.Robot2.SpeedLimitReductionFactor;
	MC_BR_GroupSetOverride_0_R2.Enable := TRUE;     	
	MC_BR_GroupSetOverride_0_R2(AxesGroup := ADR(gAxesGroup_D4r1100R_2)); 
		
END_ACTION

ACTION CameraIntegration :
	 // When mechanics is homed, allow vision to start/configure
	IF gMechanics.Status.Homed THEN
		gVision.Param.MachineReadyAndHomed := TRUE;
	END_IF
	// When vision is configured, notify mechanics that the camera is ready	
	IF gVision.Status.Configured THEN
		gMechanics.Param.CameraReady := TRUE;
	END_IF 
END_ACTION