(**
 * Derive position and color of the physical objects from the detected shapes:
 *
 * - model=2 detects only black objects, model=1 detects black and red objects
 * - Builds a filtered list of detections from the raw camera output. It first collects all BLACK objects (Model=2) into the filtered buffer. 
 * - Then it evaluates each RED candidate (Model=1) and checks its Euclidean distance in pixel space against every stored BLACK object. 
 * - If a RED is closer than the configured threshold (e.g., ˜100 px when using a 10000 threshold after SQRT), it is rejected to prevent counting the same physical object twice. 
 * - Valid RED detections (those not overlapping a BLACK) are appended after the BLACK entries, resulting in an ordered list: BLACK first, then non-overlapping RED.
*)	
ACTION CameraOutputFiltering: 
	
	CameraOutputFiltered.NumObjFound := 0;
	
	FOR i := 0 TO (CameraPV.Output.NumObjFound-1)   DO
		
		IF CameraPV.Output.Obj[i].Model = 2 THEN
			CameraOutputFiltered.Obj[CameraOutputFiltered.NumObjFound] := CameraPV.Output.Obj[i];
			CameraOutputFiltered.NumObjFound := CameraOutputFiltered.NumObjFound + 1;
		END_IF
		
	END_FOR
	
	NumBlackObj := CameraOutputFiltered.NumObjFound;
	
	FOR i := 0 TO (CameraPV.Output.NumObjFound-1)   DO
		
		IF CameraPV.Output.Obj[i].Model = 1 THEN
			RedObjectFound := TRUE;
			
			IF NumBlackObj > 0 THEN
				
				FOR j := 0 TO NumBlackObj-1 DO
					Distance_px := SQRT(
					brmpow(LREAL_TO_REAL(CameraPV.Output.Obj[i].Pos.X - CameraOutputFiltered.Obj[j].Pos.X ), 2) + 
					brmpow(LREAL_TO_REAL(CameraPV.Output.Obj[i].Pos.Y - CameraOutputFiltered.Obj[j].Pos.Y ), 2)
					);
					
					IF Distance_px < 10000 THEN
						RedObjectFound := FALSE;
						EXIT;
					END_IF
					
				END_FOR
				
			END_IF
			
			IF RedObjectFound THEN
				CameraOutputFiltered.Obj[CameraOutputFiltered.NumObjFound] := CameraPV.Output.Obj[i];
				CameraOutputFiltered.NumObjFound := CameraOutputFiltered.NumObjFound + 1;
			END_IF
			
		END_IF
	END_FOR
		
END_ACTION
