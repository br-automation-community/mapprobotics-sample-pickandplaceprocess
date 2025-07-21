// Reads the current auto-create condition parameters for Tracking Path 1 from the configuration.
ACTION ReadgTrackingPath_1_param: 
	
	ProcessParam_AutCrtCond1TrkPath1.Execute := TRUE;
	ProcessParam_AutCrtCond1TrkPath1.Component := ADR(gTrackingPath_1);
	ProcessParam_AutCrtCond1TrkPath1.AdvancedParameters.Name := 'Condition 1';
	ProcessParam_AutCrtCond1TrkPath1.DataAddress := ADR(AutoCreateConditionParTrkPath1);
	ProcessParam_AutCrtCond1TrkPath1.DataType := mcCFG_TRK_PATH_AUT_CRT_COND;
	ProcessParam_AutCrtCond1TrkPath1.Mode := mcPPM_READ;
				
END_ACTION

// Reads the current auto-create condition parameters for Tracking Path 2 from the configuration.
ACTION ReadgTrackingPath_2_param: 
	
	ProcessParam_AutCrtCond1TrkPath2.Execute := TRUE;
	ProcessParam_AutCrtCond1TrkPath2.Component := ADR(gTrackingPath_2);
	ProcessParam_AutCrtCond1TrkPath2.AdvancedParameters.Name := 'Condition 1';
	ProcessParam_AutCrtCond1TrkPath2.DataAddress := ADR(AutoCreateConditionParTrkPath2);
	ProcessParam_AutCrtCond1TrkPath2.DataType := mcCFG_TRK_PATH_AUT_CRT_COND;
	ProcessParam_AutCrtCond1TrkPath2.Mode := mcPPM_READ;
	
END_ACTION

// Checks if the distance parameter for Tracking Path 1 needs updating.
// If so, updates the value and writes it back to the controller.
ACTION AdjustTrackingPath_1_distance: 
	
	IF AutoCreateConditionParTrkPath1.Condition.DistanceBased.Distance <> Cmd.Settings.Conveyor1.AutoFrameCreation.Space THEN
		AutoCreateConditionParTrkPath1.Condition.DistanceBased.Distance := Cmd.Settings.Conveyor1.AutoFrameCreation.Space;
		ProcessParam_AutCrtCond1TrkPath1.Execute := TRUE;
		ProcessParam_AutCrtCond1TrkPath1.Component := ADR(gTrackingPath_1);
		ProcessParam_AutCrtCond1TrkPath1.AdvancedParameters.Name := 'Condition 1';
		ProcessParam_AutCrtCond1TrkPath1.DataAddress := ADR(AutoCreateConditionParTrkPath1);
		ProcessParam_AutCrtCond1TrkPath1.DataType := mcCFG_TRK_PATH_AUT_CRT_COND;
		ProcessParam_AutCrtCond1TrkPath1.Mode := mcPPM_WRITE;
		ProcessParam_AutCrtCond1TrkPath1();
		ProcessParam_AutCrtCond1TrkPath1.Execute := FALSE;	
	END_IF
	
END_ACTION

// Checks if the distance parameter for Tracking Path 2 needs updating.
// If so, updates the value and writes it back to the controller.
ACTION AdjustTrackingPath_2_distance: 
	
	IF AutoCreateConditionParTrkPath2.Condition.DistanceBased.Distance <> Cmd.Settings.Conveyor2.AutoFrameCreation.Space THEN
		AutoCreateConditionParTrkPath2.Condition.DistanceBased.Distance := Cmd.Settings.Conveyor2.AutoFrameCreation.Space;
		ProcessParam_AutCrtCond1TrkPath2.Execute := TRUE;
		ProcessParam_AutCrtCond1TrkPath2.Component := ADR(gTrackingPath_2);
		ProcessParam_AutCrtCond1TrkPath2.AdvancedParameters.Name := 'Condition 1';
		ProcessParam_AutCrtCond1TrkPath2.DataAddress := ADR(AutoCreateConditionParTrkPath2);
		ProcessParam_AutCrtCond1TrkPath2.DataType := mcCFG_TRK_PATH_AUT_CRT_COND;
		ProcessParam_AutCrtCond1TrkPath2.Mode := mcPPM_WRITE;
		ProcessParam_AutCrtCond1TrkPath2();
		ProcessParam_AutCrtCond1TrkPath2.Execute := FALSE;	
	END_IF
	
END_ACTION

// Writes the updated frame position parameters for Tracking Path 1 to the controller.
ACTION UpdateTrackingPath_1_FramePos:
		
	ProcessParam_AutCrtCond1TrkPath1.Execute := TRUE;
	ProcessParam_AutCrtCond1TrkPath1.Component := ADR(gTrackingPath_1);
	ProcessParam_AutCrtCond1TrkPath1.AdvancedParameters.Name := 'Condition 1';
	ProcessParam_AutCrtCond1TrkPath1.DataAddress := ADR(AutoCreateConditionParTrkPath1);
	ProcessParam_AutCrtCond1TrkPath1.DataType := mcCFG_TRK_PATH_AUT_CRT_COND;
	ProcessParam_AutCrtCond1TrkPath1.Mode := mcPPM_WRITE;
	ProcessParam_AutCrtCond1TrkPath1();
	ProcessParam_AutCrtCond1TrkPath1.Execute := FALSE;	
				
END_ACTION

// Checks if the orientation angle (Angle3) for Tracking Path 1 needs updating.
// If so, updates the value and writes the new frame position to the controller.
ACTION AdjustTrackingPath_1_Angle3:
	
	IF AutoCreateConditionParTrkPath1.Condition.DistanceBased.Position.Orientation.Angle3 <> Cmd.Settings.Conveyor1.ContainerOrientation THEN
		AutoCreateConditionParTrkPath1.Condition.DistanceBased.Position.Orientation.Angle3 := Cmd.Settings.Conveyor1.ContainerOrientation ; 
		UpdateTrackingPath_1_FramePos;
	END_IF
	
END_ACTION


// During cleaning, only automatic frame creation for conveyor 2 is disabled.
// This ensures objects are placed at origin after cleaning.
// Stopping frame creation on conveyor 1 would require checking that all objects are back,
// which is application-specific and not implemented here.

ACTION CleaningProcess:
	// Ensure the system is in RUN state to avoid interfering with automatic frame creation,
	// which must wait until the conveyor homing process is completed.
	IF Cmd.Info.State = RUN THEN

		// If the cleaning machine is active, disable automatic frame creation of tracking path 2
		IF Cmd.CleanUpMode THEN
			Cmd.Settings.Conveyor2.AutoFrameCreation.Enable := FALSE;
			// Otherwise, if automatic frame creation is currently disabled, enable it
		ELSIF Cmd.Settings.Conveyor2.AutoFrameCreation.Enable = FALSE THEN
			Cmd.Settings.Conveyor2.AutoFrameCreation.Enable := TRUE;
		END_IF

	END_IF
END_ACTION