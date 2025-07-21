# mappRobotics-Sample-PickAndPlaceProcess

## Scope

This sample demonstrates a dual-robot pick-and-place system using B&R's mapp Robotics and Conveyor Tracking technologies. Robot 1 picks individual objects from a conveyor and places them into containers, while Robot 2 transfers filled containers between conveyors. The system includes a buffer for temporary object storage and showcases a design to handle multiple pick-and-place jobs with priority-based scheduling.

This is a demonstration/training example focused on feature integration rather than production implementation. It does not include production-grade safety protocols or comprehensive error handling.

https://github.com/user-attachments/assets/d4283c99-f4b8-4b0e-b12e-de0a676b7322

## Prerequisites

- B&R Automation Studio 6.3.1 or later
- Automation Runtime 6.3.4
- mapp Motion 6.4.1
- mapp View 6.3.1  
- mapp Cockpit 6.3.1
- Basic understanding of Structured Text and robot Motion Structured Text (MotionST) programming
- Familiarity with mapp Robotics and Conveyor Tracking concepts

## How to Run the Simulation

1. Open `PickAndPlace.apj` (ensure required technology packages are installed)
2. Activate Simulation mode
3. Transfer to target (ArSim)
4. Open Watch window for 'Mechanics' task (Logical View → Tasks) and add 'Cmd' structure
5. Set `PowerAndHome` to `TRUE`
6. Set `MoveConveyor1` to `TRUE`
7. Set `MoveConveyor2` to `TRUE`
8. Set `MoveProgramRobot1` to `TRUE`
9. Set `MoveProgramRobot2` to `TRUE`
10. Open 3D visualization (Logical View → Scene → Customized)
11. In Scene Viewer: Online → OPC UA → Connect
    - Target: `127.0.0.1`
    - Username: `gmctest`
    - Password: `gmctest`
12. Click 'OK' to connect the 3D visualization to the simulated PLC

## Notes

- **Troubleshooting**: Check Logger for error entries if issues occur
- **Error Recovery**: Restart the simulated PLC to recover from errors
- **Runtime Changes**: Most settings under `Cmd.Settings` can be modified during operation
- **Agility Changes**: When changing `AgilityReductionFactor`, ensure robot programs are stopped (`Cmd.MoveProgramRobotX = FALSE`)

