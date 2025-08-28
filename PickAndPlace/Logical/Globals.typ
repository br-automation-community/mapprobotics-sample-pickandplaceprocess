(*Type for Mechanics ctrl structure*)

TYPE
	MechanicsStatus_Type : 	STRUCT 
		Moving : BOOL;
		Homed : BOOL;
	END_STRUCT;
	MechanicsParam_Type : 	STRUCT 
		CameraReady : BOOL;
	END_STRUCT;
	MechanicsCtrl_Type : 	STRUCT 
		Status : MechanicsStatus_Type;
		Param : MechanicsParam_Type;
	END_STRUCT;
END_TYPE

(*Type for Vision ctrl structure*)

TYPE
	VisionCtrl_Type : 	STRUCT 
		Param : VisionParam_Type;
		Status : VisionStatus_Type;
	END_STRUCT;
	VisionStatus_Type : 	STRUCT 
		Configured : BOOL;
	END_STRUCT;
	VisionParam_Type : 	STRUCT 
		MachineReadyAndHomed : BOOL;
	END_STRUCT;
END_TYPE
