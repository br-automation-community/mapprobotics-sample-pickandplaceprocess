
TYPE
	CameraParam_Type : 	STRUCT 
		GainLevel : USINT;
		SetFocus : UINT;
		FlashSegment : USINT;
		FlashColor : USINT;
		ExposureTime : UDINT;
	END_STRUCT;
	CameraStatus_Type : 	STRUCT 
		ModuleOk : BOOL;
		CameraStatus : UDINT;
		CompletedAcquisitionCount : USINT;
		ImageProcessingActive : BOOL;
	END_STRUCT;
	Camera_Type : 	STRUCT 
		Status : CameraStatus_Type;
		Param : CameraParam_Type;
		Output : VF_Output_Type;
		Input : VF_Input_Type;
	END_STRUCT;
	CoordinatePixel_Type : 	STRUCT 
		X : DINT;
		Y : DINT;
	END_STRUCT;
	Coordinate_mm_Type : 	STRUCT 
		X : LREAL;
		Y : LREAL;
	END_STRUCT;
	ObjInfo_Type : 	STRUCT  (*information regarding the object found*)
		Pos : CoordinatePixel_Type;
		Orient : REAL;
		Model : USINT;
	END_STRUCT;
	VF_Input_Type : 	STRUCT 
		EnableVF : BOOL; (*Input for enabling the VisionFunction*)
		NumSearchMax : USINT;
	END_STRUCT;
	VF_Output_Type : 	STRUCT 
		NumObjFound : USINT;
		Obj : ARRAY[0..MaxObjectDetectable]OF ObjInfo_Type;
	END_STRUCT;
	VisionState_Enum : 
		(
		WAITING_FOR_SYSTEM_READY, (*in this state camera triggering is waiting the correct configuration of the axis connected*)
		NEXT_CAPTURE_PENDING,
		WAITING_VF,
		DETECTED_OBJECT_FRAME_CREATION, (*Retrieves existing frames on the conveyor, filters raw camera detections (via CameraOutputFiltering), 
converts kept detections from pixels to millimeters with an affine transform, and creates new tracking frames only 
if each candidate is at least OBJECT_MIN_DIST away from all already-present frames. 
Assigns attributes/user data BY color (BLACK/RED) and latches the current conveyor position before submitting the batch TO the tracking path.*)
		RESETTING_VARIABLES
		);
END_TYPE
