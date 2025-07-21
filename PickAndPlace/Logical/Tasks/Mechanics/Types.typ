
TYPE
	CommandType : 	STRUCT 
		PowerAndHome : BOOL;
		MoveConveyor1 : BOOL;
		MoveConveyor2 : BOOL;
		MoveProgramRobot1 : BOOL;
		MoveProgramRobot2 : BOOL;
		Settings : CmdSettingsType;
		Info : InfoType;
		Stop : BOOL;
		CleanUpMode : BOOL; (*once TRUE the robots will start to put the object back to the container*)
	END_STRUCT;
	RobotSettingsType : 	STRUCT 
		AgilityReductionFactor : REAL; (*Reduces the velocity, acceleration and jerk limits (path limit and axes limit). Value range 0 to 1. This value must not be changed during program run.*)
		SpeedLimitReductionFactor : REAL; (*Reduces the velocity limit (path limit and axes limit). Value range 0 to 1. This value can also be changed during program run.*)
	END_STRUCT;
	TrackingFrameCreationType : 	STRUCT 
		Enable : BOOL;
		Space : LREAL;
	END_STRUCT;
	Conveyor1SettingsType : 	STRUCT 
		Velocity : REAL;
		AutoFrameCreation : TrackingFrameCreationType;
		ContainerOrientation : REAL; (*The orientation of Container 1 is defined relative to the coordinate system of Tracking Path 1. A value of 180° indicates a 180-degree rotation around the Z-axis from the original orientation of Tracking Path 1.

The robot allows rotation values strictly between 0° and 360°—that is, values must be greater than 0° and less than 360°. Both 0° and 360° are not included in the allowed range to avoid ambiguity*)
	END_STRUCT;
	Conveyor2SettingsType : 	STRUCT 
		Velocity : REAL;
		AutoFrameCreation : TrackingFrameCreationType;
	END_STRUCT;
	CmdSettingsType : 	STRUCT 
		Conveyor1 : Conveyor1SettingsType;
		Conveyor2 : Conveyor2SettingsType;
		Robot1 : RobotSettingsType;
		Robot2 : RobotSettingsType;
	END_STRUCT;
	StateType : 
		(
		STARTUP,
		WAIT_FOR_POWER_AND_HOME,
		POWER,
		HOME,
		READ_CURRENT_PARAMETERS,
		RUN
		);
	InfoType : 	STRUCT 
		Status : STRING[120];
		State : StateType;
	END_STRUCT;
END_TYPE
