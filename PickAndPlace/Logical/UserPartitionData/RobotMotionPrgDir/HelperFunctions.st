#include 'SharedTypes.typ'
#pragma LOAD 'SharedConstants.var'

(*
 * Generates and returns an attribute value (bitmask) that represents the state of the TrackingFrame userData.
 * This function analyzes the position type and object states to create appropriate attribute flags.
 * 
 * @param userData: TrackingFrameUserDataType - The user data structure containing position and object information
 * @return UDINT - Bitmask representing the current state (empty positions, object types, etc.)
 *)
FUNCTION GetAttributeBasedOnUserData : UDINT
	VAR_INPUT
		userData : TrackingFrameUserDataType;
	END_VAR
	VAR
		attribute : UDINT;
		i : UINT;
	END_VAR
	attribute := 0;
	IF userData.PositionType = TrackingFramePositionTypeEnum#SingleItemPosition THEN
		IF userData.SingleItemPositionData.PositionFilled = FALSE THEN
			IF userData.SingleItemPositionData.ObjectType = ObjectTypeEnum#Red THEN
				attribute := attribute OR TrackingFrameAttributeBits#HasEmptyPosForRedObj;
			ELSE // userData.SingleItemPositionData.ObjectType = ObjectTypeEnum#Black
				attribute := attribute OR TrackingFrameAttributeBits#HasEmptyPosForBlackObj;
			END_IF	
		ELSE // userData.SingleItemPositionData.PositionFilled = TRUE
			IF userData.SingleItemPositionData.ObjectType = ObjectTypeEnum#Red THEN
				attribute := attribute OR TrackingFrameAttributeBits#HasRedObj;
			ELSE // userData.SingleItemPositionData.ObjectType = ObjectTypeEnum#Black
				attribute := attribute OR TrackingFrameAttributeBits#HasBlackObj;
			END_IF					
		END_IF			
	ELSIF userData.PositionType = TrackingFramePositionTypeEnum#ContainerPosition THEN
		IF userData.ContainerPositionData.PositionFilled = FALSE THEN
			attribute := attribute OR TrackingFrameAttributeBits#HasEmptyPosForContainer; 
		ELSE //userData.ContainerPositionData.PositionFilled = TRUE				
			FOR i := 0 TO MAX_CONTAINER_POS_INDEX DO
				IF userData.ContainerPositionData.ContainedPositions[i].PositionFilled THEN
					IF userData.ContainerPositionData.ContainedPositions[i].ObjectType = ObjectTypeEnum#Red THEN
						attribute := attribute OR TrackingFrameAttributeBits#HasRedObj;						
					ELSE // userData.ContainerPositionData.ContainedPositions[i].ObjectType = ObjectTypeEnum#Black
						attribute := attribute OR TrackingFrameAttributeBits#HasBlackObj;				
					END_IF
				ELSE // userData.ContainerPositionData.ContainedPositions[i].PositionFilled = FALSE
					IF userData.ContainerPositionData.ContainedPositions[i].ObjectType = ObjectTypeEnum#Red THEN
						attribute := attribute OR TrackingFrameAttributeBits#HasEmptyPosForRedObj;						
					ELSE // userData.ContainerPositionData.ContainedPositions[i].ObjectType = ObjectTypeEnum#Black
						attribute := attribute OR TrackingFrameAttributeBits#HasEmptyPosForBlackObj;				
					END_IF
				END_IF
			END_FOR;
		END_IF
	END_IF
	GetAttributeBasedOnUserData := attribute;	
END_FUNCTION
	
(*
 * Generates an attribute value (bitmask) and writes it directly to the specified TrackingFrame.
 * This is a convenience function that combines GetAttributeBasedOnUserData with TrackingFrameSetAttribute.
 * 
 * @param trackingFrameId: McTrkFrmIdentType - The ID of the tracking frame to update
 * @param userData: TrackingFrameUserDataType - The user data to analyze for attribute generation
 * @return UDINT - The generated attribute bitmask that was written to the tracking frame
 *)
FUNCTION SetAttributeBasedOnUserData : UDINT
	VAR_INPUT
		trackingFrameId : McTrkFrmIdentType;
		userData : TrackingFrameUserDataType;
	END_VAR	
	VAR
		attribute : UDINT;
	END_VAR
	attribute := GetAttributeBasedOnUserData(userData);
	TrackingFrameSetAttribute(trackingFrameId, attribute);
	SetAttributeBasedOnUserData := attribute;
END_FUNCTION

(*
 * Configures the pick operation in the MotionProgram based on selected TrackingFrame userData.
 * Updates synchronization positions, object type information, and marks the position as empty after picking.
 * 
 * @param MotionProgram: RobotMotionProgramType - IN_OUT: Motion program structure to update
 * @param objectTypeRed: BOOL - TRUE if red objects should be considered for picking
 * @param objectTypeBlack: BOOL - TRUE if black objects should be considered for picking  
 * @param objectTypeContainer: BOOL - TRUE to pick entire container, FALSE to pick individual contained item
 * @return BOOL - Success status of the operation
 *)
FUNCTION SetPickPositionBasedOnUserData : BOOL
	VAR_IN_OUT
		MotionProgram : RobotMotionProgramType;
	END_VAR
	VAR_INPUT
		objectTypeRed : BOOL;
		objectTypeBlack : BOOL;
		objectTypeContainer : BOOL; // TRUE the entire container will be picked, FALSE only a contained item will be picked
	END_VAR
	VAR
		i : UINT;
	END_VAR
	IF MotionProgram.Pick.TrackingFrame.UserData.PositionType = TrackingFramePositionTypeEnum#SingleItemPosition THEN
		MotionProgram.Pick.SynchPosUp := MotionProgram.Pick.TrackingFrame.UserData.SingleItemPositionData.SyncPosUp;
		MotionProgram.Pick.SynchPosDown := MotionProgram.Pick.TrackingFrame.UserData.SingleItemPositionData.SyncPosDown;	
		MotionProgram.PickedObject.Type := MotionProgram.Pick.TrackingFrame.UserData.SingleItemPositionData.ObjectType;
		MotionProgram.PickedObject.ContainerIndex := 0; // No container index for single item position
		MotionProgram.Pick.TrackingFrame.UserData.SingleItemPositionData.PositionFilled := FALSE;	
	ELSE // MotionProgram.Pick.TrackingFrame.UserData.PositionType = TrackingFramePositionTypeEnum#ContainerPosition
		IF objectTypeContainer THEN // Entire container will be picked
			MotionProgram.Pick.SynchPosUp := MotionProgram.Pick.TrackingFrame.UserData.ContainerPositionData.SyncPosUp;
			MotionProgram.Pick.SynchPosDown := MotionProgram.Pick.TrackingFrame.UserData.ContainerPositionData.SyncPosDown;
			MotionProgram.Pick.TrackingFrame.UserData.ContainerPositionData.PositionFilled := FALSE;
		ELSE // Only a contained item will be picked
			// Search through container positions to find the requested object type
			FOR i := 0 TO MAX_CONTAINER_POS_INDEX DO
				IF MotionProgram.Pick.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[i].PositionFilled THEN			
					IF objectTypeRed AND MotionProgram.Pick.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[i].ObjectType = ObjectTypeEnum#Red THEN
						MotionProgram.Pick.SynchPosUp := MotionProgram.Pick.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[i].SyncPosUp;
						MotionProgram.Pick.SynchPosDown := MotionProgram.Pick.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[i].SyncPosDown;
						MotionProgram.PickedObject.Type := MotionProgram.Pick.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[i].ObjectType;
						MotionProgram.PickedObject.ContainerIndex := i;
						MotionProgram.Pick.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[i].PositionFilled := FALSE;
						EXIT; // exit for loop
					ELSIF objectTypeBlack AND MotionProgram.Pick.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[i].ObjectType = ObjectTypeEnum#Black THEN
						MotionProgram.Pick.SynchPosUp := MotionProgram.Pick.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[i].SyncPosUp;
						MotionProgram.Pick.SynchPosDown := MotionProgram.Pick.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[i].SyncPosDown;
						MotionProgram.PickedObject.Type := MotionProgram.Pick.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[i].ObjectType;
						MotionProgram.PickedObject.ContainerIndex := i;
						MotionProgram.Pick.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[i].PositionFilled := FALSE;
						EXIT; // exit for loop
					END_IF		
				END_IF
			END_FOR;
			
		END_IF
	END_IF
	MotionProgram.Pick.PositionSelected := TRUE;				
	TrackingFrameSetUserData(ADR(MotionProgram.Pick.TrackingFrame.UserData), 
							SIZEOF(MotionProgram.Pick.TrackingFrame.UserData), 
							MotionProgram.Pick.TrackingFrame.ID);			
	MotionProgram.Pick.TrackingFrame.Attribute := SetAttributeBasedOnUserData(MotionProgram.Pick.TrackingFrame.ID, MotionProgram.Pick.TrackingFrame.UserData);
END_FUNCTION

(*
 * Configures the place operation in the MotionProgram based on selected TrackingFrame userData.
 * Updates synchronization positions, transfers object data from pick to place position, and marks position as filled.
 * 
 * @param MotionProgram: RobotMotionProgramType - IN_OUT: Motion program structure to update
 * @param objectTypeRed: BOOL - TRUE if red objects should be considered for placement
 * @param objectTypeBlack: BOOL - TRUE if black objects should be considered for placement
 * @param objectTypeContainer: BOOL - TRUE to place entire container, FALSE to place individual item in container
 * @return BOOL - Success status of the operation
 *)
	FUNCTION SetPlacePositionBasedOnUserData : BOOL
	VAR_IN_OUT
		MotionProgram : RobotMotionProgramType;
	END_VAR
	VAR_INPUT
		objectTypeRed : BOOL;
		objectTypeBlack : BOOL;
		objectTypeContainer : BOOL; // TRUE the entire container will be picked, FALSE only a contained item will be picked
	END_VAR
	VAR
		i : UINT;
	END_VAR
	IF MotionProgram.Place.TrackingFrame.UserData.PositionType = TrackingFramePositionTypeEnum#SingleItemPosition THEN
		MotionProgram.Place.SynchPosUp := MotionProgram.Place.TrackingFrame.UserData.SingleItemPositionData.SyncPosUp;
		MotionProgram.Place.SynchPosDown := MotionProgram.Place.TrackingFrame.UserData.SingleItemPositionData.SyncPosDown;	
		// Transfer product identification from pick to place position for traceability
		MotionProgram.Place.TrackingFrame.UserData.SingleItemPositionData.ProductID := MotionProgram.Pick.TrackingFrame.UserData.SingleItemPositionData.ProductID;
		MotionProgram.Place.TrackingFrame.UserData.SingleItemPositionData.PositionFilled := TRUE;
	ELSE // MotionProgram.Place.TrackingFrame.UserData.PositionType = TrackingFramePositionTypeEnum#ContainerPosition	
		IF objectTypeContainer THEN // Entire container will be placed
			MotionProgram.Place.SynchPosUp := MotionProgram.Place.TrackingFrame.UserData.ContainerPositionData.SyncPosUp;
			MotionProgram.Place.SynchPosDown := MotionProgram.Place.TrackingFrame.UserData.ContainerPositionData.SyncPosDown;
			MotionProgram.Place.TrackingFrame.UserData.ContainerPositionData := MotionProgram.Pick.TrackingFrame.UserData.ContainerPositionData; // Copy container data from pick to place position
			MotionProgram.Place.TrackingFrame.UserData.ContainerPositionData.PositionFilled := TRUE;	
		ELSE // Will be placed in a contained position only
			// Search for position with object present
			FOR i := 0 TO MAX_CONTAINER_POS_INDEX DO
				IF NOT MotionProgram.Place.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[i].PositionFilled THEN
					IF objectTypeRed AND MotionProgram.Place.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[i].ObjectType = ObjectTypeEnum#Red THEN
						MotionProgram.Place.SynchPosUp := MotionProgram.Place.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[i].SyncPosUp;
						MotionProgram.Place.SynchPosDown := MotionProgram.Place.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[i].SyncPosDown;
						MotionProgram.Place.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[i].ProductID := 
							MotionProgram.Pick.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[MotionProgram.PickedObject.ContainerIndex].ProductID;
						MotionProgram.Place.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[i].PositionFilled := TRUE;
						EXIT; // exit for loop
					ELSIF objectTypeBlack AND MotionProgram.Place.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[i].ObjectType = ObjectTypeEnum#Black THEN
						MotionProgram.Place.SynchPosUp := MotionProgram.Place.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[i].SyncPosUp;
						MotionProgram.Place.SynchPosDown := MotionProgram.Place.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[i].SyncPosDown;
						MotionProgram.Place.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[i].ProductID := 
							MotionProgram.Pick.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[MotionProgram.PickedObject.ContainerIndex].ProductID;
						MotionProgram.Place.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[i].PositionFilled := TRUE;
						EXIT; // exit for loop
					END_IF
				END_IF
			END_FOR;
		END_IF
	END_IF
	MotionProgram.Place.PositionSelected := TRUE;				
	TrackingFrameSetUserData(ADR(MotionProgram.Place.TrackingFrame.UserData), 
							SIZEOF(MotionProgram.Place.TrackingFrame.UserData), 
							MotionProgram.Place.TrackingFrame.ID);			
	MotionProgram.Place.TrackingFrame.Attribute := SetAttributeBasedOnUserData(MotionProgram.Place.TrackingFrame.ID, MotionProgram.Place.TrackingFrame.UserData);
END_FUNCTION