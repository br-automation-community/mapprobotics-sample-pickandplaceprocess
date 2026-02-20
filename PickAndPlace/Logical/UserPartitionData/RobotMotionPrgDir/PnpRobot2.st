#include 'HelperFunctions.st'
#pragma LOAD 'SharedConstants.var'

(**
 * This program controls robot 2 movements and object selection.
 * Robot 2 has a gripper designed for picking entire containers (4 objects at once). 
 * Robot 2 has a single pick-and-place job to execute:
 *		Pick complete containers that have been filled by robot 1 from conveyor belt 2 
 *		and place them on conveyor belt 1.
 *
 * Operation: Robot 2 waits for containers on conveyor 2 that contain objects (filled by Robot 1),
 * then transfers these complete containers to conveyor 1.
 *)

VAR CONSTANT
	ParkPosWithoutObject      : McPointType := (Pos:=(X:=-200, Y:=-200, Z:= -800));
	ParkPosWithObject      : McPointType := (Pos:=(X:=200, Y:=200, Z:= -800));
END_VAR  
VAR {AT 'Mechanics'}
	MotionProgramRob2 : RobotMotionProgramType;	
END_VAR

// Robot 2 helper functions
	
(**
 * Selects a filled container on conveyor 2 for picking operation.
 * Searches for containers that contain objects (filled by Robot 1) and are ready for transfer.
 * Automatically updates TrackingFrame UserData and Attributes for the selected position.
 * 
 * @param MotionProgram: RobotMotionProgramType - IN_OUT: Motion program structure to update with pick position
 *)	
FUNCTION SelectPickPositionAndSetPickData : BOOL
	VAR_IN_OUT
		MotionProgram : RobotMotionProgramType;
	END_VAR
	VAR
		i : UINT;
	END_VAR

	// Search for containers on conveyor 2 that contain objects (red or black)
	TrackingFrameSelectorSetAttributeMasks('Rob2_Pick_Conveyor2', 0, TrackingFrameAttributeBits#HasRedObj OR TrackingFrameAttributeBits#HasBlackObj, 0);
	
	IF TrackingFrameSelect(MotionProgram.Pick.TrackingFrame.ID, 'Rob2_Pick_Conveyor2') THEN
		TrackingFrameGetUserData(ADR(MotionProgram.Pick.TrackingFrame.UserData), 
								SIZEOF(MotionProgram.Pick.TrackingFrame.UserData), 
								MotionProgram.Pick.TrackingFrame.ID);	
		SetPickPositionBasedOnUserData(MotionProgram, FALSE, FALSE, TRUE);
		// Container selected for pickup				
	END_IF	
END_FUNCTION
	
(**
 * Selects an empty container position on conveyor 1 for placing the picked container.
 * Searches for available container placeholder positions on the destination conveyor.
 * Automatically updates TrackingFrame UserData and Attributes for the selected position.
 * 
 * @param MotionProgram: RobotMotionProgramType - IN_OUT: Motion program structure to update with place position
 *)
FUNCTION  SelectPlacePositionAndSetPlacementData : BOOL
	VAR_IN_OUT
		MotionProgram : RobotMotionProgramType;
	END_VAR
	VAR
		i : UINT;
	END_VAR
	
	// Search for empty container positions on conveyor 1
	TrackingFrameSelectorSetAttributeMasks('Rob2_Place_Conveyor1', 0, TrackingFrameAttributeBits#HasEmptyPosForContainer, 0);
	IF TrackingFrameSelect(MotionProgram.Place.TrackingFrame.ID, 'Rob2_Place_Conveyor1') THEN
		TrackingFrameGetUserData(ADR(MotionProgram.Place.TrackingFrame.UserData), 
								SIZEOF(MotionProgram.Place.TrackingFrame.UserData), 
								MotionProgram.Place.TrackingFrame.ID);
		SetPlacePositionBasedOnUserData(MotionProgram, FALSE, FALSE, TRUE);
	END_IF
END_FUNCTION

(**
 * Main selection function for pick positions when robot has no container.
 * Calls the detailed pick selection logic and determines the next robot state based on results.
 * Handles parking behavior when no suitable containers are available for pickup.
 * 
 * @param MotionProgram: RobotMotionProgramType - IN_OUT: Motion program structure to update
 * @param FromPlacePos: BOOL - TRUE if coming from place position, FALSE if from waiting position
 *)
FUNCTION SelectPickPosition : BOOL
	VAR_IN_OUT
		MotionProgram : RobotMotionProgramType;
	END_VAR
	VAR_INPUT
		FromPlacePos : BOOL; // TRUE: coming from place position, FALSE: coming from waiting position
	END_VAR
	MotionProgram.Pick.PositionSelected := FALSE;		
	SelectPickPositionAndSetPickData(MotionProgram);
	IF MotionProgram.Pick.PositionSelected THEN
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
 * Selects a place position for a container already held by the robot.
 * Used when robot picked a container but couldn't immediately find a place destination.
 * Handles parking behavior with container when no place position is available.
 * 
 * @param MotionProgram: RobotMotionProgramType - IN_OUT: Motion program with picked container data
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
		MotionProgram.State:=RobotStateEnum#ParkWithGrippedObject;
	END_IF
END_FUNCTION	

(**
 *  * Updates the products in the gripper to be shown in Scene Viewer
 *)
FUNCTION UpdateGripperContent : BOOL
	VAR_IN_OUT
		MotionProgram : RobotMotionProgramType;
	END_VAR
	VAR_INPUT
		Pick : BOOL; // TRUE: Pick operation, FALSE: Place operation
	END_VAR
	IF Pick THEN
		MotionProgram.GripperContent.RedObjectInGripper[0] := MotionProgram.Pick.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[0].PositionFilled AND MotionProgram.Pick.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[0].ObjectType = ObjectTypeEnum#Red;
		MotionProgram.GripperContent.RedObjectInGripper[1] := MotionProgram.Pick.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[1].PositionFilled AND MotionProgram.Pick.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[1].ObjectType = ObjectTypeEnum#Red;
		MotionProgram.GripperContent.RedObjectInGripper[2] := MotionProgram.Pick.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[2].PositionFilled AND MotionProgram.Pick.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[2].ObjectType = ObjectTypeEnum#Red;
		MotionProgram.GripperContent.RedObjectInGripper[3] := MotionProgram.Pick.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[3].PositionFilled AND MotionProgram.Pick.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[3].ObjectType = ObjectTypeEnum#Red;
		
		MotionProgram.GripperContent.BlackObjectInGripper[0] := MotionProgram.Pick.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[0].PositionFilled AND MotionProgram.Pick.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[0].ObjectType = ObjectTypeEnum#Black;
		MotionProgram.GripperContent.BlackObjectInGripper[1] := MotionProgram.Pick.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[1].PositionFilled AND MotionProgram.Pick.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[1].ObjectType = ObjectTypeEnum#Black;
		MotionProgram.GripperContent.BlackObjectInGripper[2] := MotionProgram.Pick.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[2].PositionFilled AND MotionProgram.Pick.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[2].ObjectType = ObjectTypeEnum#Black;
		MotionProgram.GripperContent.BlackObjectInGripper[3] := MotionProgram.Pick.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[3].PositionFilled AND MotionProgram.Pick.TrackingFrame.UserData.ContainerPositionData.ContainedPositions[3].ObjectType = ObjectTypeEnum#Black;
	ELSE 
		MotionProgram.GripperContent.RedObjectInGripper[0] := FALSE;
		MotionProgram.GripperContent.RedObjectInGripper[1] := FALSE;
		MotionProgram.GripperContent.RedObjectInGripper[2] := FALSE;
		MotionProgram.GripperContent.RedObjectInGripper[3] := FALSE;
		
		MotionProgram.GripperContent.BlackObjectInGripper[0] := FALSE;
		MotionProgram.GripperContent.BlackObjectInGripper[1] := FALSE;
		MotionProgram.GripperContent.BlackObjectInGripper[2] := FALSE;
		MotionProgram.GripperContent.BlackObjectInGripper[3] := FALSE;
	END_IF
END_FUNCTION
	
		
// Robot 2 Main Motion Program - Container Transfer State Machine

PROGRAM _MAIN
       
	MotionProgramRob2.State := RobotStateEnum#Start;
    
	REPEAT
		CASE MotionProgramRob2.State OF
          
			RobotStateEnum#Start:
				// Initialize robot to park position
				MoveLR(ParkPosWithoutObject);
				WaitALAP();	
				MotionProgramRob2.State := RobotStateEnum#ParkWithNoObject;		

			RobotStateEnum#PickObject:
				// Execute container pick operation
				TrackObjectR(MotionProgramRob2.Pick.TrackingFrame.ID, MotionProgramRob2.Pick.SynchPosUp, 50, 50);
				DO_PATH_SYNCH
					MotionProgramRob2.CloseGripper := TRUE;	 // To increase throughput (reduce required WaitTime), also signaling feature could be used for deactivating the vaccuum
				END_PATH_SYNCH
				MoveLR(MotionProgramRob2.Pick.SynchPosDown);
				DO_PATH_SYNCH
					UpdateGripperContent(MotionProgramRob2, TRUE);
				END_PATH_SYNCH
				WaitTime(0.1); // Allow time for container to settle in gripper
				MoveLR(MotionProgramRob2.Pick.SynchPosUp);
				WaitALAP();
				// Search for place position after successful container pickup
				SelectPlacePosition(MotionProgramRob2, TRUE);
				
			RobotStateEnum#PlaceObject:
				// Execute container place operation
				TrackObjectR(MotionProgramRob2.Place.TrackingFrame.ID, MotionProgramRob2.Place.SynchPosUp, 50, 50);
				MoveLR(MotionProgramRob2.Place.SynchPosDown);
				DO_PATH_SYNCH
					MotionProgramRob2.CloseGripper := FALSE;	 // To increase throughput (reduce required WaitTime), also signaling feature could be used for deactivating the vaccuum
					UpdateGripperContent(MotionProgramRob2, FALSE);
				END_PATH_SYNCH
				WaitTime(0.05); // Brief wait for container release
				MoveLR(MotionProgramRob2.Place.SynchPosUp);	
				WaitALAP();
				// Look for next container to transfer after successful placement
				SelectPickPosition(MotionProgramRob2, TRUE); 
 
			RobotStateEnum#ParkWithNoObject:
				// Robot is parked without container - continuously search for containers to transfer
				SelectPickPosition(MotionProgramRob2, FALSE);        
         
			RobotStateEnum#ParkWithGrippedObject:
				// Robot has container but no place position - search for place destination
				SelectPlacePosition(MotionProgramRob2, FALSE);
         
		END_CASE      
	UNTIL FALSE END_REPEAT;
       
END_PROGRAM  