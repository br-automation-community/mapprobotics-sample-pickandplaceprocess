(**
 * Vision Manager Main Program
 * This program manages the complete vision pipeline for a pick-and-place system, including:
 * - Axis-based image acquisition synchronized to conveyor motion
 * - Camera configuration and readiness checks
 * - Detection filtering (Derive position and color of the physical objects from the detected shapes)
 * - Pixel-to-millimeter coordinate transformation
 * - TrackingFrame creation and submission to the TrackingPath
 *
 * System Flow:

 * 0. WAITING_FOR_SYSTEM_READY: Verify camera/module OK and machine homed; initialize camera; enable acquisition
 * 1. NEXT_CAPTURE_PENDING: Detect a new completed acquisition; request current frames for de-duplication checks
 * 2. WAITING_VF: Wait for the vision function to finish image processing
 * 3. DETECTED_OBJECT_FRAME_CREATION: Filter detections, transform to mm, reject near-existing frames, stage frames, submit batch
 * 4. RESETTING_FB: Reset function blocks and buffers; return to NEXT_CAPTURE_PENDING
 *
 * Purpose & Scope:
 * This demonstration module shows how to integrate camera acquisition, detection filtering,
 * and tracking frame creation into a conveyor-based workflow, ensuring only valid,
 * de-duplicated detections are promoted TO TrackingFrames.
 *
 * Note: This is a demonstration/training example and does not implement production-grade
 * safety protocols, error handling, or machine lifecycle management (power-up, homing,
 * shutdown procedures) that would be required for a real industrial application.
 *)

PROGRAM _INIT
	
	MC_ReadActualPosition_Mot1(Axis := ADR(conveyer1Ax), Enable := TRUE);
	MC_BR_DetectedObjFramesCreat.TrackingPath := ADR(gTrackingPath_1);
	
	GetFramesInfoInitialization;	

	ViBaseAxisBasedAcquisition_Fb.Enable := FALSE;
	ViBaseAxisBasedAcquisition_Fb.MpLink := ADR(gCamera);
	ViBaseAxisBasedAcquisition_Fb.AcquisitionParameters.Period := 70; // it will take a picture every 80mm
	
	gVision.Param.MachineReadyAndHomed := FALSE;
	
END_PROGRAM


PROGRAM _CYCLIC
	
	ViBaseAxisBasedAcquisition_Fb();
	MC_BR_DetectedObjFramesCreat();
	TrackingPathGetFramesPos_Fb();
	
	CASE VisionState OF 
		
		WAITING_FOR_SYSTEM_READY:
			IF CameraPV.Status.CameraStatus = 0 AND CameraPV.Status.ModuleOk AND gVision.Param.MachineReadyAndHomed THEN
				ViBaseAxisBasedAcquisition_Fb.Enable := TRUE; // enable the acquisition, when the axis is home and ready
				CameraInitialization;
				gVision.Status.Configured := TRUE;
				VisionState := NEXT_CAPTURE_PENDING;
			END_IF;
			
		NEXT_CAPTURE_PENDING:
			IF LastAcquisitionCount <> CameraPV.Status.CompletedAcquisitionCount   THEN 
				MC_ReadActualPosition_Mot1();
				TrackingPathGetFramesPos_Fb.Execute := TRUE;
				VisionState := WAITING_VF;
			END_IF	
		
		WAITING_VF:
			IF NOT CameraPV.Status.ImageProcessingActive THEN
				VisionState := DETECTED_OBJECT_FRAME_CREATION;
			END_IF
				
		DETECTED_OBJECT_FRAME_CREATION:
			
			IF TrackingPathGetFramesPos_Fb.Done AND NOT CameraPV.Status.ImageProcessingActive THEN
				IF  CameraPV.Output.NumObjFound > 0  THEN
					TrackingPathGetFramesPos_Fb.Execute := FALSE;
					LastAcquisitionCount := CameraPV.Status.CompletedAcquisitionCount;
					NumbersNewFrame := 0;
					CameraOutputFiltering;
					
					FOR i := 0 TO (CameraOutputFiltered.NumObjFound-1)   DO
						
						// Affine transformation with translation term (pixel -> mm)
						// Matrix components:
						// X_mm = (X_pixel * a11) + (Y_pixel * a12) + X_Translation_mm
						// Y_mm = (X_pixel * a21) + (Y_pixel * a22) + Y_Translation_mm
						// 
						// From  matrix:
						// a11 = -0.17952376
						// a12 = -0.0015347
						// a21 =  0.00212256
						// a22 =  0.18369122
						// X_Translation_mm = 1102.51630312;
						// Y_Translation_mm = -89.82579615;
						
						CreateNewFrame := TRUE;
						
						Pos_mm[i].X :=((DINT_TO_LREAL(CameraOutputFiltered.Obj[i].Pos.X) * (-0.17952376))
						+ (DINT_TO_LREAL(CameraOutputFiltered.Obj[i].Pos.Y) * 0.00212256 ))/100 + 1102.51630312; 
						
						Pos_mm[i].Y := ((DINT_TO_LREAL(CameraOutputFiltered.Obj[i].Pos.X) * (-0.0015347))
						+ (DINT_TO_LREAL(CameraOutputFiltered.Obj[i].Pos.Y) * 0.18369122))/100  -89.82579615;
						
						// This loop prevents creating duplicate frames. It calculates the Euclidean distance between the newly detected object and all existing ones. 
						// IF any existing frame is closer than OBJECT_MIN_DIST, the new detection is rejected setting CreateNewFrame to FALSE
						FOR j := 0 TO TrackingPathGetFramesPos_Fb.TrackingFrameCount DO
							
							Distance := SQRT(
							brmpow(LREAL_TO_REAL(FramesInfo[j].CurrentPosition.X - Pos_mm[i].X), 2) + 
							brmpow(LREAL_TO_REAL(FramesInfo[j].CurrentPosition.Y - Pos_mm[i].Y), 2)
							);
							IF Distance < OBJECT_MIN_DIST THEN
								CreateNewFrame := FALSE;
								EXIT;
							END_IF
						END_FOR
						
						// assign all the necessary Position information to the array McTrkFramesDetectedObjArray
						IF CreateNewFrame THEN
							McTrkFramesDetectedObjArray[NumbersNewFrame].Translation.X := Pos_mm[i].X;
							McTrkFramesDetectedObjArray[NumbersNewFrame].Translation.Y := Pos_mm[i].Y;
							McTrkFramesDetectedObjArray[NumbersNewFrame].Translation.Z := OBJECT_HEIGHT_mm;
							McTrkFramesDetectedObjArray[NumbersNewFrame].Orientation.Angle3 := 180;
							
							IF CameraOutputFiltered.Obj[i].Model = 2 THEN
								McTrkFramesDetectedObjArray[NumbersNewFrame].Attribute := HasBlackObj;
								McTrkFramesDetectedObjArray[NumbersNewFrame].UserDataAddress := ADR(UserDataSingleItemObjectBlack);
							ELSE
								McTrkFramesDetectedObjArray[NumbersNewFrame].Attribute := HasRedObj;
								McTrkFramesDetectedObjArray[NumbersNewFrame].UserDataAddress := ADR(UserDataSingleItemObjectRed);
							END_IF
							
							McTrkFramesDetectedObjArray[NumbersNewFrame].LatchedPath.Position := MC_ReadActualPosition_Mot1.Position;
							NumbersNewFrame := NumbersNewFrame + 1;
						END_IF
					
					END_FOR;
					
					IF NumbersNewFrame > 0 THEN	
						MC_BR_DetectedObjFramesCreat.Parameters.DataAddress := ADR(McTrkFramesDetectedObjArray);
						MC_BR_DetectedObjFramesCreat.Parameters.NumberOfFrames := NumbersNewFrame;
						MC_BR_DetectedObjFramesCreat.Execute := TRUE;
					END_IF
					
					VisionState := RESETTING_VARIABLES;
						
				ELSE
					LastAcquisitionCount := CameraPV.Status.CompletedAcquisitionCount;
					TrackingPathGetFramesPos_Fb.Execute := FALSE;
					VisionState := NEXT_CAPTURE_PENDING;
				END_IF
			END_IF
			
		RESETTING_VARIABLES:	
			
			IF MC_BR_DetectedObjFramesCreat.Done OR  NumbersNewFrame = 0 THEN
				TrackingPathGetFramesPos_Fb.Execute := FALSE;
				brsmemset(ADR(McTrkFramesDetectedObjArray),0,SIZEOF(McTrkFramesDetectedObjArray));
				MC_BR_DetectedObjFramesCreat.Execute := FALSE;
				brsmemset(ADR(CameraOutputFiltered),0,SIZEOF(CameraOutputFiltered));
				VisionState := NEXT_CAPTURE_PENDING;
			END_IF
		
	END_CASE 
	
END_PROGRAM


PROGRAM _EXIT
	
	(* Cleanup and resource deallocation *)

	MC_ReadActualPosition_Mot1.Enable := FALSE;
	MC_ReadActualPosition_Mot1(); // Recall the FB
	
	ViBaseAxisBasedAcquisition_Fb.Enable := FALSE;
	ViBaseAxisBasedAcquisition_Fb();	

END_PROGRAM
	