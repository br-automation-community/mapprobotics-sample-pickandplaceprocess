(**
 * Buffer Initialization
 * 
 * This program initializes the buffer register with a predefined grid of objects.
 * Creates tracking frames for objects positioned in a structured layout that will serve
 * as the initial inventory for the pick-and-place operations.
 * 
 * Grid Layout: Objects are arranged in a rectangular grid pattern with alternating colors
 * Pattern: Red and black objects alternate (even indices = red, odd indices = black)
 * Purpose: Provides initial objects for Robot 1 to pick from buffer and place on conveyor 2
 *)

PROGRAM _INIT
	
	// Creation of initial objects on buffer register

	FOR j := 0 TO CONV_SLOTS_MAX_IND DO
		// X-position: Column calculation - distributes objects across columns
		TrkFrmsToCreateOnBufferRegister[j].Translation.X := GRID / 2 + GRID * (j / ROWS); 
		// Y-position: Row calculation - cycles through rows (0, 1, 2, ... ROWS-1)
		TrkFrmsToCreateOnBufferRegister[j].Translation.Y := GRID / 2 + GRID * (j MOD ROWS);
		// Z-position: Object height above the buffer surface
		TrkFrmsToCreateOnBufferRegister[j].Translation.Z := OBJECT_HEIGHT_mm;
		
		// Alternate between red and black objects for demonstration/testing purposes
		IF (j MOD 2 = 0) THEN
			// Even indices: Red objects
			TrkFrmsToCreateOnBufferRegister[j].Attribute := HasRedObj;
			TrkFrmsToCreateOnBufferRegister[j].UserDataAddress := ADR(UserDataSingleItemObjectRed);
		ELSE
			// Odd indices: Black objects
			TrkFrmsToCreateOnBufferRegister[j].Attribute := HasBlackObj;
			TrkFrmsToCreateOnBufferRegister[j].UserDataAddress := ADR(UserDataSingleItemObjectBlack);
		END_IF;
	END_FOR;
	
	MC_BR_TrackingFrameCreate_0.Parameters.DataAddress := ADR(TrkFrmsToCreateOnBufferRegister);
	MC_BR_TrackingFrameCreate_0.Parameters.NumberOfFrames := CONV_SLOTS;
	MC_BR_TrackingFrameCreate_0.TrackingPath := ADR(gTrackingPath_3);
	
	MC_BR_TrackingFrameCreate_0.Execute := TRUE;
	MC_BR_TrackingFrameCreate_0();
            	
END_PROGRAM

PROGRAM _EXIT
	MC_BR_TrackingFrameCreate_0();
	MC_BR_TrackingFrameCreate_0.Execute := FALSE;
END_PROGRAM

