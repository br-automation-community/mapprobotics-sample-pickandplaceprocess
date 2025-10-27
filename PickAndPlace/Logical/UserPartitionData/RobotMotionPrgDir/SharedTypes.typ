(*TrackingFrame user data*)

TYPE
	TrackingFrameUserDataType : 	STRUCT 
		PositionType : TrackingFramePositionTypeEnum;
		SingleItemPositionData : SingleItemPositionDataType;
		ContainerPositionData : ContainerPositionDataType;
	END_STRUCT;
	TrackingFramePositionTypeEnum : 
		(
		SingleItemPosition := 0,
		ContainerPosition := 1
		);
	SingleItemPositionDataType : 	STRUCT 
		PositionFilled : BOOL;
		ObjectType : ObjectTypeEnum;
		ProductID : UDINT; (*Optional: ID of product*)
		SyncPosUp : McPointType;
		SyncPosDown : McPointType;
	END_STRUCT;
	ContainerPositionDataType : 	STRUCT 
		PositionFilled : BOOL;
		ContainedPositions : ARRAY[0..MAX_CONTAINER_POS_INDEX]OF SingleItemPositionDataType;
		ContainerID : UDINT; (*Optional: ID of container*)
		SyncPosUp : McPointType;
		SyncPosDown : McPointType;
	END_STRUCT;
	ObjectTypeEnum : 
		(
		Red := 0,
		Black := 1
		);
	RobotStateEnum : 
		(
		Start := 0,
		PickObject := 1,
		PlaceObject := 2,
		ParkWithNoObject := 3,
		ParkWithGrippedObject := 4
		);
END_TYPE

(*Motion Program*)

TYPE
	RobotMotionProgramType : 	STRUCT 
		Pick : RobotMotionPickPlaceType;
		Place : RobotMotionPickPlaceType;
		PickedObject : PickedObjectType;
		State : RobotStateEnum;
		CloseGripper : BOOL;
		GripperContent : GripperContentType;
		CleaningMachine : BOOL;
	END_STRUCT;
	RobotMotionPickPlaceType : 	STRUCT 
		PositionSelected : BOOL;
		TrackingFrame : RobotMotionTrkFrmType;
		SynchPosUp : McPointType;
		SynchPosDown : McPointType;
	END_STRUCT;
	RobotMotionTrkFrmType : 	STRUCT 
		ID : McTrkFrmIdentType;
		UserData : TrackingFrameUserDataType;
		Attribute : UDINT;
	END_STRUCT;
	PickedObjectType : 	STRUCT 
		Type : ObjectTypeEnum;
		ContainerIndex : UINT; (*Use for pick/place positions in a container only*)
	END_STRUCT;
	GripperContentType : 	STRUCT 
		RedObjectInGripper : ARRAY[0..3]OF BOOL;
		BlackObjectInGripper : ARRAY[0..3]OF BOOL;
	END_STRUCT;
END_TYPE

(*TrackingFrame attribute: Bit code*)

TYPE
	TrackingFrameAttributeBits : 
		(
		HasEmptyPosForRedObj := 2#00000000000000000000000000000001,
		HasEmptyPosForBlackObj := 2#00000000000000000000000000000010,
		HasRedObj := 2#00000000000000000000000000000100,
		HasBlackObj := 2#00000000000000000000000000001000,
		HasEmptyPosForContainer := 2#00000000000000000000000000010000
		);
END_TYPE
