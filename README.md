# Simple Parking System Verilog Implementation

This is a simple parking system simulation designed in Verilog for FPGA implementation. The system has a capacity of 4 parking spots and handles the entry and exit of vehicles, along with displaying relevant status information.

## Features

- **Entry Sensor**: Detects when a vehicle enters the parking lot.
- **Exit Sensor**: Detects when a vehicle exits the parking lot.
- **Full Light**: Turns on when the parking lot is full.
- **Door Open Light**: Indicates when the parking entrance door is open.
- **Capacity Management**: Tracks the available parking spaces and the number of parked vehicles.
- **Seven Segment Display**: Shows the current parking location and capacity using a 7-segment display.

## Components

### 1. Frequency Divider Controller
- Divides the clock signal to generate time intervals for controlling the lights and door open logic.
- Uses different frequencies for 1Hz and 2Hz operations.

### 2. Seven Segment Display
- Displays the current parking location and available capacity.

### 3. Main Parking Logic
- Manages the state transitions of the parking system, including checking entry and exit, opening doors, and managing parking spaces.

## State Machine

The system uses a state machine to handle different states of operation:

- **IDLE**: Initial state, waiting for sensor input.
- **CHECK_ENTRY**: When a vehicle enters, checks if space is available.
- **CHECK_EXIT**: When a vehicle exits, updates the parking spots.
- **FULL**: The parking lot is full, and no entry is allowed.
- **DOOR_OPEN**: The door opens to allow entry or exit.

## Requirements

- **Verilog**: The design is implemented in Verilog.
- **FPGA**: The design is intended to be synthesized and implemented on an FPGA.
- **Simulation Tools**: Use a Verilog simulator like ModelSim or Vivado for simulation.


## Steps to Run the Project

1. **Open the Verilog Files**
   - Use your preferred FPGA design tool (e.g., Vivado, Quartus).

2. **Synthesize and Simulate**
   - Synthesize the design.
   - Simulate the system to verify its functionality.

3. **Implement on FPGA**
   - Deploy the synthesized design to your FPGA board.
   - Connect the required peripherals, such as:
     - 7-segment display
     - Sensors (entry/exit)

## Example Simulation

- **Entry Sensor:**  
  When the entry sensor is triggered (vehicle enters), the system checks for available parking space.
  
- **Exit Sensor:**  
  When the exit sensor is triggered (vehicle exits), the system updates the parking capacity.

## License
This project is open-source and available under the [MIT License](LICENSE).

## Contact
If you have any questions or suggestions, feel free to:
- Open an issue on this repository.
- Create a pull request with your contributions.
