
ACTION CameraInitialization: 
	CameraPV.Param.GainLevel := 1;
	CameraPV.Param.SetFocus := 56000;
	CameraPV.Param.ExposureTime := 2000;
	CameraPV.Param.FlashColor := 99;
	CameraPV.Param.FlashSegment := 15;
	CameraPV.Input.EnableVF := TRUE;
	CameraPV.Input.NumSearchMax := MaxObjectDetectable;
END_ACTION


ACTION GetFramesInfoInitialization:
	TrackingPathGetFramesPos_Fb.TrackingPath := ADR(gTrackingPath_1);
	TrackingPathGetFramesPar.GetMode := mcTRKPATH_GET_MOD_ALL_FRAMES;
	TrackingPathGetFramesPar.InfoMode := mcTRKPATH_INFO_MOD_ALL;
	TrackingPathGetFramesPar.NumberOfFrames := 16;
	TrackingPathGetFramesPar.DataAddress := ADR(FramesInfo);
	TrackingPathGetFramesPos_Fb.Parameters := TrackingPathGetFramesPar;
END_ACTION
