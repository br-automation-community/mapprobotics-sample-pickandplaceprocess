(**
 * Main Mechanics Control Program
 * 
 * This program manages the complete pick-and-place system including:
 * - Two conveyor belts with automatic TrackingFrame creation
 * - Two robots (Robot 1: single object picker, Robot 2: container picker)
 * - System initialization, homing, and operational state management
 * - TrackingPath coordination and parameter management
 * 
 * System Flow:
 * 0. Buffer: Provides initial objects for Robot 1 to pick from
 * 1. Conveyor 1: Feeds individual objects to Robot 1
 * 2. Robot 1: Picks objects and fills containers on Conveyor 2
 * 3. Robot 2: Transfers filled containers from Conveyor 2 back to Conveyor 1
 * 4. Buffer: Provides temporary storage when direct transfer isn't possible
 *
 * Purpose & Scope:
 * This demonstration program showcases how multiple mapp Robotics features can be integrated
 * to create a complete pick-and-place solution. The focus is on demonstrating feature integration
 * and process coordination rather than production-ready implementation.
 * 
 * Note: This is a demonstration/training example and does not implement production-grade
 * safety protocols, error handling, or machine lifecycle management (power-up, homing,
 * shutdown procedures) that would be required for a real industrial application.
 *)

PROGRAM _INIT
	
	SIMULATION_ACTIVE := DiagCpuIsSimulated() OR DiagCpuIsARsim();
	
	// Initial process parameters
	Cmd.Settings.Conveyor1.AutoFrameCreation.Space := 200;
	Cmd.Settings.Conveyor2.AutoFrameCreation.Space := 200;
	Cmd.Settings.Conveyor1.Velocity := 60;
	Cmd.Settings.Conveyor2.Velocity := 60;

	// Robots
	MpRobotPar_1.ProgramName := 'PnpRobot1.st'; // Single object pick-and-place robot
	MpRobotPar_2.ProgramName := 'PnpRobot2.st'; // Container transfer robot
	
	Cmd.Settings.Robot1.AgilityReductionFactor := 1;
	Cmd.Settings.Robot1.SpeedLimitReductionFactor := 1;
	Cmd.Settings.Robot2.AgilityReductionFactor := 1;
	Cmd.Settings.Robot2.SpeedLimitReductionFactor := 1;
	
	MpRobot_1.MpLink := ADR(gAxesGroup_D4r1100R_1);
	MpRobot_1.Enable := TRUE;
	MpRobot_1.Parameters := ADR(MpRobotPar_1);
	MpRobot_1.Override := 100;
	
	MpRobot_2.MpLink := ADR(gAxesGroup_D4r1100R_2);
	MpRobot_2.Enable := TRUE;
	MpRobot_2.Parameters := ADR(MpRobotPar_2);
	MpRobot_2.Override := 100;

	// Conveyor belts
	MpAxisParConv1.Velocity := Cmd.Settings.Conveyor1.Velocity;
	MpAxisParConv2.Velocity := Cmd.Settings.Conveyor2.Velocity;
	MpAxisConv1.MpLink := ADR(conveyer1Ax);
	MpAxisConv1.Parameters := ADR(MpAxisParConv1);
	MpAxisConv1.Enable := TRUE;
	MpAxisConv2.MpLink := ADR(conveyer2Ax);
	MpAxisConv2.Parameters := ADR(MpAxisParConv2);
	MpAxisConv2.Enable := TRUE;
	StatusTrackingPath1.Enable := TRUE;
	StatusTrackingPath2.Enable := TRUE;
	StatusTrackingPath1.TrackingPath := ADR(gTrackingPath_1);
	StatusTrackingPath2.TrackingPath := ADR(gTrackingPath_2);

	// IMPORTANT: Coordinate system alignment between conveyors
	// TrackingPath_1 is 180° rotated relative to TrackingPath_2
	// To prevent robot rotation for each transfer from TrackingPath_1 to TrackingPath_2,
	// containers created on TrackingPath_1 are pre-rotated by 180°
	Cmd.Settings.Conveyor1.ContainerOrientation := 180; // Pre-rotation to match Path_2 orientation 
	
	UseInternalPVs;
	
END_PROGRAM


(**
 * Main Cyclic Control Program
 * 
 * Manages the complete system operation through a state machine:
 * 1. STARTUP - Wait for system readiness
 * 2. WAIT_FOR_POWER_AND_HOME - Wait for user command to start
 * 3. POWER - Power up all components
 * 4. HOME - Home all axes and robots
 * 5. READ_CURRENT_PARAMETERS - Initialize TrackingPath parameters
 * 6. RUN - Normal operation with continuous monitoring
 *)

PROGRAM _CYCLIC
	// Bridge for integrating the camera in the system
	CameraIntegration;
	
	// Synchronize user interface commands with robot/conveyor controls
	MotionProgramRob1.CleaningMachine := Cmd.CleanUpMode;
	
	IF gMechanics.Param.CameraReady THEN
		MpRobot_1.MoveProgram := Cmd.MoveProgramRobot1;
		MpRobot_2.MoveProgram := Cmd.MoveProgramRobot2;
		MpAxisConv1.MoveVelocity := Cmd.MoveConveyor1;
		MpAxisConv2.MoveVelocity := Cmd.MoveConveyor2;
	END_IF
	
	MpRobot_1.Stop := Cmd.Stop;
	MpRobot_2.Stop := Cmd.Stop;
	MpAxisConv1.Stop := Cmd.Stop;
	MpAxisConv2.Stop := Cmd.Stop;

	// Update robot performance parameters based on settings
	AgilityReductionInit;
	SpeedLimitReduction;
	
	CleaningProcess;
	
	(* Main state machine *)
	CASE Cmd.Info.State OF

		STARTUP:
			// Wait for all components to report ready status
			Cmd.Info.Status := 'Awaiting machine readiness before starting the system';
			IF MpAxisConv1.Info.ReadyToPowerOn AND MpAxisConv2.Info.ReadyToPowerOn AND MpRobot_1.Info.ReadyToPowerOn AND MpRobot_2.Info.ReadyToPowerOn  THEN 
				Cmd.Info.State := WAIT_FOR_POWER_AND_HOME;
			END_IF		


		WAIT_FOR_POWER_AND_HOME:
			// System ready - wait for operator command to begin startup sequence
			Cmd.Info.Status := 'Machine ready for power-up and homing!';
			IF Cmd.PowerAndHome THEN
				Cmd.Info.State := POWER;
			END_IF


		POWER:
			// Power up all components
			Cmd.Info.Status := 'Stuck here? Power-on failed, see log for details.';
			MpRobot_1.Power := TRUE;   // Power robot 1 drives
			MpRobot_2.Power := TRUE;   // Power robot 2 drives  
			MpAxisConv1.Power := TRUE; // Power conveyor 1 drive
			MpAxisConv2.Power := TRUE; // Power conveyor 2 drive
			// Wait for all power-on confirmations before proceeding
			IF   MpAxisConv1.PowerOn AND MpAxisConv2.PowerOn AND MpRobot_1.PowerOn AND MpRobot_2.PowerOn THEN 
				Cmd.Info.State := HOME;
			END_IF


		HOME:
			// Home all axes to establish reference positions
			IF SIMULATION_ACTIVE THEN
				// In simulation: Use direct homing (drives are simulated)
				SimHome;
			ELSE
				// Real hardware: Use absolute homing procedure
				MpRobot_1.Home := TRUE;
				MpRobot_2.Home := TRUE;
				
			END_IF
			MpAxisConv1.Home := TRUE;  // Home conveyor 1
			MpAxisConv2.Home := TRUE;  // Home conveyor 2
			
			// Wait for all homing operations to complete
			IF  MpAxisConv1.IsHomed AND MpAxisConv2.IsHomed AND MpRobot_1.IsHomed AND MpRobot_2.IsHomed THEN
				// Enable automatic tracking frame creation once homed
				Cmd.Settings.Conveyor1.AutoFrameCreation.Enable := TRUE;
				Cmd.Settings.Conveyor2.AutoFrameCreation.Enable := TRUE;
				Cmd.Info.State := READ_CURRENT_PARAMETERS;	
				
				gMechanics.Status.Homed := TRUE;
			END_IF


		READ_CURRENT_PARAMETERS:
			
			// Read current automatic creation condition parameters configured for TrackingPath components

			IF StatusTrackingPath1.TrackingPathReady AND StatusTrackingPath2.TrackingPathReady THEN
				ReadgTrackingPath_1_param;
				ReadgTrackingPath_2_param;
			END_IF
		
			// Wait for parameter read operations to complete
			IF ProcessParam_AutCrtCond1TrkPath1.Done AND ProcessParam_AutCrtCond1TrkPath2.Done THEN 
				// Reset function block execute flags
				ProcessParam_AutCrtCond1TrkPath1.Execute := FALSE;
				ProcessParam_AutCrtCond1TrkPath2.Execute := FALSE;
				
				// Update settings with values read from configuration
				Cmd.Settings.Conveyor1.AutoFrameCreation.Space := AutoCreateConditionParTrkPath1.Condition.DistanceBased.Distance;
				Cmd.Settings.Conveyor2.AutoFrameCreation.Space := AutoCreateConditionParTrkPath2.Condition.DistanceBased.Distance;
				
				Cmd.Info.Status := 'Machine Running';
				Cmd.Info.State := RUN;

			END_IF


		RUN:
			// Normal operation mode - continuous parameter monitoring and updates

			// Apply any changes to tracking path parameters during operation
			AdjustTrackingPath_1_distance;  // Update conveyor 1 frame spacing
			AdjustTrackingPath_2_distance;  // Update conveyor 2 frame spacing
			AdjustTrackingPath_1_Angle3;    // Update conveyor 1 container orientation
			
			// Dynamic conveyor velocity updates
			IF MpAxisParConv1.Velocity <> Cmd.Settings.Conveyor1.Velocity THEN
				MpAxisParConv1.Velocity := Cmd.Settings.Conveyor1.Velocity;
				MpAxisConv1.Update := TRUE;
				MpAxisConv1();
				MpAxisConv1.Update := FALSE;
			END_IF
			IF MpAxisParConv2.Velocity <> Cmd.Settings.Conveyor2.Velocity THEN
				MpAxisParConv2.Velocity := Cmd.Settings.Conveyor2.Velocity;
				MpAxisConv2.Update := TRUE;
				MpAxisConv2();
				MpAxisConv2.Update := FALSE;
			END_IF
		
			IF Cmd.Settings.Conveyor1.ContainerOrientation <= 0 OR Cmd.Settings.Conveyor1.ContainerOrientation >= 360 THEN
				Cmd.Info.Status := 'Please enter an orientation value greater than 0 and less than 360, robot 2 in error state';
				Cmd.Stop := TRUE;
			ELSE
				IF Cmd.Stop THEN
					Cmd.Stop := FALSE;
					// Note: MpRobot_.MoveProgram and MpAxisConv.MoveVelocity need manual restart after stop
				END_IF
			END_IF

	END_CASE


	MpRobot_1();
	MpRobot_2();
	
	MpAxisConv1();
	MpAxisConv2();
	
	ProcessParam_AutCrtCond1TrkPath1();
	ProcessParam_AutCrtCond1TrkPath2();
	
	StatusTrackingPath1();
	StatusTrackingPath2();
	
END_PROGRAM