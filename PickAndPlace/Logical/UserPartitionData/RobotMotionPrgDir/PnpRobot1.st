#include 'HelperFunctions.st'
#pragma LOAD 'SharedConstants.var'

(**
 * This program controls robot 1 movements and the object selection.
 * Robot 1 has a gripper for pick single products only. 
 * Robot 1 has the following pick-and-place jobs to execute:
 *		1. Pick red products from conveyor belt 1 and place them to conveyor belt 2
 *		2. Pick black products from conveyor belt 1 and place them to conveyor belt 2
 *		3. Pick red products from conveyor belt 1 and place them to buffer between the conveyor belts
 *		4. Pick black products from conveyor belt 1 and place them to buffer between the conveyor belts
 *		5. Pick red products from buffer and place them to conveyor belt 2
 *		6. Pick black products from buffer and place them to conveyor belt 2
 *
 * Priority of the jobs	
 *	1. Try to find an available pick-and-place sequence for job 1 or 2:
 *		1.1 Try to find a container that that will go out of workspace next and has empty positions (HasEmptyPosForRedObj|HasEmptyPosForBlackObj)
 * 			1.1.1 Try to find a pick position that can fill this container (black or red object) (HasRedObj||HasBlackObj)
 * 	2. Alternatively when no full pick-and-place sequence is available, search for a pick position only, to initiate job 3 or job 4:
 * 		2.1 First search for pick position on conveyor belt 1, when no place position is available on conveyor 2
 * 			2.1.1 Place the object to buffer (job 3 or job 4)
 * 			2.1.2 Go to waiting position with the object in the hand and wait for place positions on conveyor 2 (job 1 or job 2)	
 * 	3. If no pick position available execute job 5 or job 6:
 * 		3.1 Search for products on buffer and place them on conveyor 2 (job 5 or job 6)
 *)

VAR CONSTANT
	ParkPosWithoutObject	: McPointType 	:= (Pos:=(X:=200, Y:=200, Z:= -800));
	ParkPosWithObject		: McPointType 	:= (Pos:=(X:=-200, Y:=-200, Z:= -800));
END_VAR  
	
VAR {AT 'Mechanics'}
	MotionProgramRob1 : RobotMotionProgramType;	
END_VAR

	
// Robot 1 helper functions
	
(**
 * Selects the optimal pick and place positions for the next robot operation based on priority logic.
 * Implements the job priority system: first tries complete pick-place sequences (jobs 1-2),
 * then pick-only operations to buffer (jobs 3-4), finally buffer-to-conveyor operations (jobs 5-6).
 * Automatically updates TrackingFrame UserData and Attributes for selected positions.
 * 
 * @param MotionProgram: RobotMotionProgramType - IN_OUT: Motion program structure to update with selected positions
 *)
FUNCTION SelectPickPlacePositionAndSetPnpSequenceData : BOOL
	VAR_IN_OUT
		MotionProgram : RobotMotionProgramType;
	END_VAR
	VAR
		i : UINT;
	END_VAR

	// PRIORITY 1: Try to find complete pick-place sequence (jobs 1-2)
	// First, look for containers on conveyor 2 that need filling
	TrackingFrameSelectorSetAttributeMasks('Rob1_Place_Conveyor2', 0, TrackingFrameAttributeBits#HasEmptyPosForRedObj OR TrackingFrameAttributeBits#HasEmptyPosForBlackObj, 0);
	IF TrackingFrameSelect(MotionProgram.Place.TrackingFrame.ID, 'Rob1_Place_Conveyor2') THEN
		TrackingFrameGetUserData(ADR(MotionProgram.Place.TrackingFrame.UserData), 
								SIZEOF(MotionProgram.Place.TrackingFrame.UserData), 
								MotionProgram.Place.TrackingFrame.ID);
		// Container found on conveyor 2 - now find matching objects on conveyor 1		
		FOR i := 0 TO MAX_CONTAINER_POS_INDEX DO
			IF NOT MotionProgram.Place.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[i].PositionFilled THEN
				IF MotionProgram.Place.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[i].ObjectType = ObjectTypeEnum#Red THEN
					// Look for red object on conveyor 1 to fill red container slot
								
					TrackingFrameSelectorSetAttributeMasks('Rob1_Pick_Conveyor1', 0, TrackingFrameAttributeBits#HasRedObj, 0);
					IF TrackingFrameSelect(MotionProgram.Pick.TrackingFrame.ID, 'Rob1_Pick_Conveyor1') THEN
						TrackingFrameGetUserData(ADR(MotionProgram.Pick.TrackingFrame.UserData), 
												SIZEOF(MotionProgram.Pick.TrackingFrame.UserData), 
												MotionProgram.Pick.TrackingFrame.ID); 
						SetPickPositionBasedOnUserData(MotionProgram, TRUE, FALSE, FALSE);
						SetPlacePositionBasedOnUserData(MotionProgram, TRUE, FALSE, FALSE);
						// Complete pick-place sequence found for red object (job 1)
						EXIT; // exit for loop
					END_IF
									
				ELSE // Container slot expects black object
					// Look for black object on conveyor 1 to fill black container slot
								
					TrackingFrameSelectorSetAttributeMasks('Rob1_Pick_Conveyor1', 0, TrackingFrameAttributeBits#HasBlackObj, 0);
					IF TrackingFrameSelect(MotionProgram.Pick.TrackingFrame.ID, 'Rob1_Pick_Conveyor1') THEN
						TrackingFrameGetUserData(ADR(MotionProgram.Pick.TrackingFrame.UserData), 
												SIZEOF(MotionProgram.Pick.TrackingFrame.UserData), 
												MotionProgram.Pick.TrackingFrame.ID);
						SetPickPositionBasedOnUserData(MotionProgram, FALSE, TRUE, FALSE);
						SetPlacePositionBasedOnUserData(MotionProgram, FALSE, TRUE, FALSE);
						// Complete pick-place sequence found for black object (job 2)
						EXIT; // exit for loop
					END_IF	
				END_IF
			END_IF
		END_FOR;

	END_IF

	// PRIORITY 2: No complete sequence found - try pick-only operations (jobs 3-4)
	IF MotionProgram.Pick.PositionSelected=FALSE THEN
					
		// No pick/place combination found -> Search only for pick position
		TrackingFrameSelectorSetAttributeMasks('Rob1_Pick_Conveyor1', 0, TrackingFrameAttributeBits#HasRedObj OR TrackingFrameAttributeBits#HasBlackObj, 0);
		IF TrackingFrameSelect(MotionProgram.Pick.TrackingFrame.ID, 'Rob1_Pick_Conveyor1') THEN
			TrackingFrameGetUserData(ADR(MotionProgram.Pick.TrackingFrame.UserData), 
									SIZEOF(MotionProgram.Pick.TrackingFrame.UserData), 
									MotionProgram.Pick.TrackingFrame.ID);	
			SetPickPositionBasedOnUserData(MotionProgram, TRUE, TRUE, FALSE);
			// Robot will PickObject			
		ELSE 
			TrackingFrameSelectorSetAttributeMasks('Rob1_Place_Conveyor2', 0, TrackingFrameAttributeBits#HasEmptyPosForRedObj OR TrackingFrameAttributeBits#HasEmptyPosForBlackObj, 0); 
			IF TrackingFrameSelect(MotionProgram.Place.TrackingFrame.ID, 'Rob1_Place_Conveyor2')  THEN
				TrackingFrameGetUserData(ADR(MotionProgram.Place.TrackingFrame.UserData), 
										SIZEOF(MotionProgram.Place.TrackingFrame.UserData), 
										MotionProgram.Place.TrackingFrame.ID);
				// Expected here: Container object is present on the container placeholder position					
				FOR i := 0 TO MAX_CONTAINER_POS_INDEX DO
					IF NOT MotionProgram.Place.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[i].PositionFilled THEN
						IF MotionProgram.Place.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[i].ObjectType = ObjectTypeEnum#Red THEN
							
							TrackingFrameSelectorSetAttributeMasks('Rob1_PickPlace_Buffer', 0, TrackingFrameAttributeBits#HasRedObj, 0);
							IF TrackingFrameSelect(MotionProgram.Pick.TrackingFrame.ID, 'Rob1_PickPlace_Buffer') THEN
								TrackingFrameGetUserData(ADR(MotionProgram.Pick.TrackingFrame.UserData), 
														SIZEOF(MotionProgram.Pick.TrackingFrame.UserData), 
														MotionProgram.Pick.TrackingFrame.ID);
								SetPickPositionBasedOnUserData(MotionProgram, TRUE, FALSE, FALSE);
								SetPlacePositionBasedOnUserData(MotionProgram, TRUE, FALSE, FALSE);							
								// Robot will PickObject
								EXIT; // exit for loop
							END_IF
								
						ELSE // TrackingFrameUserData_Place.ContainerPositionData.ContainedPositions[i].ObjectType = ObjectTypeEnum#Black	
							TrackingFrameSelectorSetAttributeMasks('Rob1_PickPlace_Buffer', 0, TrackingFrameAttributeBits#HasBlackObj, 0);
							IF TrackingFrameSelect(MotionProgram.Pick.TrackingFrame.ID, 'Rob1_PickPlace_Buffer') THEN
								TrackingFrameGetUserData(ADR(MotionProgram.Pick.TrackingFrame.UserData), 
														SIZEOF(MotionProgram.Pick.TrackingFrame.UserData), 
														MotionProgram.Pick.TrackingFrame.ID);
								SetPickPositionBasedOnUserData(MotionProgram, FALSE, TRUE, FALSE);
								SetPlacePositionBasedOnUserData(MotionProgram, FALSE, TRUE, FALSE);
								// Robot will PickObject
								EXIT; // exit for loop
							END_IF
						END_IF
					END_IF
				END_FOR;							
			END_IF
		END_IF
			
		// No positions selected					
	END_IF
END_FUNCTION
	
(**
 * Selects an appropriate place position for an object that was already picked but has no place destination.
 * This function handles scenarios where the robot picked an object but couldn't immediately find a place position.
 * Prioritizes conveyor 2 containers, falls back to buffer positions if needed.
 * 
 * @param MotionProgram: RobotMotionProgramType - IN_OUT: Motion program with picked object data
 *)
FUNCTION  SelectPlacePositionAndSetPlacementData : BOOL
	VAR_IN_OUT
		MotionProgram : RobotMotionProgramType;
	END_VAR
	VAR
		i : UINT;
	END_VAR
	
	
	// 1. Check type of already picked object and select place position accordingly
	IF MotionProgram.PickedObject.Type = ObjectTypeEnum#Red THEN
		TrackingFrameSelectorSetAttributeMasks('Rob1_Place_Conveyor2', 0, TrackingFrameAttributeBits#HasEmptyPosForRedObj, 0);
	ELSE // MotionProgram.PickedObject.Type = ObjectTypeEnum#Black
		TrackingFrameSelectorSetAttributeMasks('Rob1_Place_Conveyor2', 0, TrackingFrameAttributeBits#HasEmptyPosForBlackObj, 0);
	END_IF
		
	IF TrackingFrameSelect(MotionProgram.Place.TrackingFrame.ID, 'Rob1_Place_Conveyor2') THEN
		TrackingFrameGetUserData(ADR(MotionProgram.Place.TrackingFrame.UserData), 
								SIZEOF(MotionProgram.Place.TrackingFrame.UserData), 
								MotionProgram.Place.TrackingFrame.ID);
		SetPlacePositionBasedOnUserData(MotionProgram, 
										MotionProgram.PickedObject.Type=ObjectTypeEnum#Red, 
										MotionProgram.PickedObject.Type=ObjectTypeEnum#Black);
	ELSE 
		FOR i := 0 TO MAX_CONTAINER_POS_INDEX DO
			IF MotionProgram.PickedObject.Type = ObjectTypeEnum#Red THEN
				TrackingFrameSelectorSetAttributeMasks('Rob1_PickPlace_Buffer', 0, TrackingFrameAttributeBits#HasEmptyPosForRedObj, 0);
				IF TrackingFrameSelect(MotionProgram.Place.TrackingFrame.ID, 'Rob1_PickPlace_Buffer') THEN
					TrackingFrameGetUserData(ADR(MotionProgram.Place.TrackingFrame.UserData),
											SIZEOF(MotionProgram.Place.TrackingFrame.UserData),
											MotionProgram.Place.TrackingFrame.ID);
					SetPlacePositionBasedOnUserData(MotionProgram, TRUE, FALSE);
					// Robot will PickObject
					EXIT; // exit for loop
				END_IF
						
			ELSE // MotionProgram.PickedObject.Type = ObjectTypeEnum#Black
				TrackingFrameSelectorSetAttributeMasks('Rob1_PickPlace_Buffer', 0, TrackingFrameAttributeBits#HasEmptyPosForBlackObj, 0);
				IF TrackingFrameSelect(MotionProgram.Place.TrackingFrame.ID, 'Rob1_PickPlace_Buffer') THEN
					TrackingFrameGetUserData(ADR(MotionProgram.Place.TrackingFrame.UserData), 
											SIZEOF(MotionProgram.Place.TrackingFrame.UserData), 
											MotionProgram.Place.TrackingFrame.ID);
					SetPlacePositionBasedOnUserData(MotionProgram, FALSE, TRUE);
					// Robot will PickObject
					EXIT;
				END_IF
				
			END_IF
		END_FOR;	
	END_IF

END_FUNCTION

(**
 * Main selection function for pick and place positions when robot has no object.
 * Calls the detailed selection logic and determines the next robot state based on results.
 * Handles parking behavior when no suitable positions are found.
 * 
 * @param MotionProgram: RobotMotionProgramType - IN_OUT: Motion program structure to update
 * @param FromPlacePos: BOOL - TRUE if coming from place position, FALSE if from waiting position
 *)
FUNCTION SelectPickPlacePosition : BOOL
	VAR_IN_OUT
		MotionProgram : RobotMotionProgramType;
	END_VAR
	VAR_INPUT
		FromPlacePos : BOOL; // TRUE: coming from place position, FALSE: coming from waiting position
	END_VAR

	MotionProgram.Pick.PositionSelected := FALSE;
	MotionProgram.Place.PositionSelected := FALSE;			
	SelectPickPlacePositionAndSetPnpSequenceData(MotionProgram);
	IF MotionProgram.Pick.PositionSelected AND MotionProgram.Place.PositionSelected THEN
		MotionProgram.State := RobotStateEnum#PickObject;
	ELSIF MotionProgram.Pick.PositionSelected THEN
		MotionProgram.State := RobotStateEnum#PickObject;	
	ELSE
		IF FromPlacePos THEN 
			TrackStopR(MachineFrame, ParkPosWithoutObject, 50, 50); 
			WaitEndMove();
		END_IF
		MotionProgram.State := RobotStateEnum#ParkWithNoObject;
	END_IF
END_FUNCTION	

(**
 * Selects a place position for an object already held by the robot.
 * Used when robot picked an object but couldn't immediately find a place destination.
 * Handles parking behavior with object when no place position is available.
 * 
 * @param MotionProgram: RobotMotionProgramType - IN_OUT: Motion program with picked object data
 * @param FromPickPos: BOOL - TRUE if coming from pick position, FALSE if from waiting position
 *)
FUNCTION SelectPlacePosition : BOOL
	VAR_IN_OUT
		MotionProgram : RobotMotionProgramType;
	END_VAR
	VAR_INPUT
		FromPickPos : BOOL; // TRUE: coming from pick position, FALSE: coming from waiting position
	END_VAR
	MotionProgram.Place.PositionSelected := FALSE;	
	SelectPlacePositionAndSetPlacementData(MotionProgram);
	IF MotionProgram.Place.PositionSelected THEN
		MotionProgram.State:=RobotStateEnum#PlaceObject;
	ELSE
		IF FromPickPos THEN 
			TrackStopR(MachineFrame, ParkPosWithObject, 50, 50); 
			WaitEndMove();
		END_IF
		MotionProgram.State := RobotStateEnum#ParkWithGrippedObject;
	END_IF
	
END_FUNCTION	

	
// Robot 1 Main Motion Program - State Machine Implementation
	
PROGRAM _MAIN
       
	MotionProgramRob1.State := RobotStateEnum#Start;
    
	REPEAT
		CASE MotionProgramRob1.State OF
          
			RobotStateEnum#Start:
				// Initialize robot to park position without object
				MoveLR(ParkPosWithoutObject);
				WaitALAP();	
				MotionProgramRob1.State := RobotStateEnum#ParkWithNoObject;		

			RobotStateEnum#PickObject:
				// Execute pick operation
				TrackObjectR(MotionProgramRob1.Pick.TrackingFrame.ID, MotionProgramRob1.Pick.SynchPosUp, 50, 50);
				DO_PATH_SYNCH
					MotionProgramRob1.CloseGripper := TRUE;	 // To increase throughput (reduce required WaitTime), also signaling feature could be used for activating the vaccuum
				END_PATH_SYNCH
				MoveLR(MotionProgramRob1.Pick.SynchPosDown);
				WaitTime(0.2); 
				MoveLR(MotionProgramRob1.Pick.SynchPosUp);
				IF MotionProgramRob1.Place.PositionSelected THEN
					MotionProgramRob1.State := RobotStateEnum#PlaceObject;
				ELSE
					WaitALAP();
					SelectPlacePosition(MotionProgramRob1, TRUE);
				END_IF
				
			RobotStateEnum#PlaceObject:
				// Execute place operation
				TrackObjectR(MotionProgramRob1.Place.TrackingFrame.ID, MotionProgramRob1.Place.SynchPosUp, 50, 50);
				MoveLR(MotionProgramRob1.Place.SynchPosDown);
				DO_PATH_SYNCH
					MotionProgramRob1.CloseGripper := FALSE;	 // To increase throughput (reduce required WaitTime), also signaling feature could be used for deactivating the vaccuum
				END_PATH_SYNCH
				WaitTime(0.1); 
				MoveLR(MotionProgramRob1.Place.SynchPosUp);	
				WaitALAP();
				// Look for next pick-place sequence after successful placement
				SelectPickPlacePosition(MotionProgramRob1, TRUE); 
 
			RobotStateEnum#ParkWithNoObject:
				// Robot is parked without object - continuously search for work
				SelectPickPlacePosition(MotionProgramRob1, FALSE);        
         
			RobotStateEnum#ParkWithGrippedObject:
				// Robot has object but no place position - search for place destination
				SelectPlacePosition(MotionProgramRob1, FALSE);
         
		END_CASE      
	UNTIL FALSE END_REPEAT;
       
END_PROGRAM  