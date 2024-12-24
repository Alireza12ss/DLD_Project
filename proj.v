module main(
    input wire clk,
    input wire reset,
    input wire Entry_sensor,
    input wire Exit_sensor,
    input wire [1:0] Exit_parking,
    output wire Full_light,
    output wire Door_Open_light,
    output reg [3:0] parkings,
    output reg [2:0] capacity,
    output reg [1:0] location,
    output reg [2:0] state
);

parameter IDLE = 3'b000,
          CHECK_ENTRY = 3'b001,
          CHECK_EXIT = 3'b010,
          FULL = 3'b011,
          DOOR_OPEN = 3'b100,
          PARK_CAR = 3'b101,
          UPDATE_DISPLAY = 3'b110;

reg [2:0] current_state, next_state;

wire open_door;
wire full;
reg internal_full;
reg internal_open_door;



assign full = internal_full;
assign open_door = internal_open_door;



reg [31:0] delay_counter;

FrequencyDividerController controller(
    .clk(clk),
    .reset(reset),
    .full(full),
    .open_door(open_door),
    .open_door_output(Door_Open_light),
    .full_output(Full_light)
);

initial begin
    current_state = IDLE;
    parkings = 4'b0000;
    location = 2'b00;
    capacity = 3'b100;
    delay_counter = 0;
end

always @(posedge clk or posedge reset) begin
    state <= current_state;
    if (reset) begin
        current_state <= IDLE;
    end else begin
        current_state <= next_state;
    end
end

always @(posedge clk) begin
    if (reset) begin
        delay_counter <= 0;
    end 
    else if (internal_open_door || internal_full) begin
        if (current_state == FULL) begin
            if (delay_counter < 51) // 6 ثانیه
                delay_counter <= delay_counter + 1;
            else
                delay_counter <= 0; 
        end else if (current_state == DOOR_OPEN) begin
            if (delay_counter < 51) // 10 ثانیه
                delay_counter <= delay_counter + 1;
            else
                delay_counter <= 0; 
        end 
        else begin
            delay_counter <= 0; 
        end
    end
    else
        delay_counter <= 0;
end

always @(posedge clk) begin
    case (current_state)
        IDLE: begin
            next_state = Entry_sensor ? CHECK_ENTRY :
                         Exit_sensor ? CHECK_EXIT : IDLE;
        end
        CHECK_ENTRY: begin
            if (capacity == 0) 
                next_state = FULL;
            else begin
                parkings[location] = 1;
                location <= (parkings[0] == 0) ? 2'b00 :
                            (parkings[1] == 0) ? 2'b01 :
                            (parkings[2] == 0) ? 2'b10 : 2'b11;
                capacity <= capacity - 1;
                next_state = DOOR_OPEN;
            end
        end
        FULL: begin
            internal_full = 1;
            if (delay_counter == 30)begin
                internal_full = 0;
                next_state = IDLE;
            end
            else
                next_state = FULL;
        end
        DOOR_OPEN: begin
            internal_open_door = 1;
            if (delay_counter == 30)begin
                internal_open_door = 0;
                next_state = IDLE;
            end
            else
                next_state = DOOR_OPEN;
        end
        CHECK_EXIT: begin
            if(capacity == 3'b100)begin
                next_state = IDLE;
            end
            else begin
            parkings[Exit_parking] = 0;
            location <= (parkings[0] == 0) ? 2'b00 :
                        (parkings[1] == 0) ? 2'b01 :
                        (parkings[2] == 0) ? 2'b10 : 2'b11;
            capacity = capacity + 1;
            next_state = DOOR_OPEN;
            end
        end
    endcase
end
endmodule

module FrequencyDividerController (
    input wire clk,
    input wire reset,
    input wire full,
    input wire open_door,
    output reg open_door_output,
    output reg full_output
);

reg [3:0] full_counter;
reg [23:0] door_counter;
reg [25:0] clk_divider_1Hz;
reg [24:0] clk_divider_2Hz;

initial begin
    full_counter = 0;
    door_counter = 0;
    full_output = 0;
    open_door_output = 0;
end

always @(posedge clk or posedge reset) begin
    if (reset) begin
        clk_divider_1Hz <= 0;
        clk_divider_2Hz <= 0;
        full_counter <= 0;
        door_counter <= 0;
        full_output <= 0;
        open_door_output <= 0;
    end 
    else begin
        if(open_door) begin
            full_output <= 0;
            full_counter <= 0;
            if (door_counter < 10) begin 
                if (clk_divider_2Hz == 2) begin
                    door_counter <= door_counter + 1;
                    open_door_output <= ~open_door_output;
                    clk_divider_2Hz <= 0;
                end
                else begin
                    clk_divider_2Hz <= clk_divider_2Hz + 1;
                end
            end 
            else begin
                open_door_output <= 0;
            end
        end
        else if(full) begin
                open_door_output <= 0;
                door_counter <= 0;
                if (full_counter < 6) begin 
                    if (clk_divider_1Hz == 2) begin
                        full_counter <= full_counter + 1;   
                        full_output <= ~full_output;
                        clk_divider_1Hz <= 0;
                    end
                    else begin
                        clk_divider_1Hz <= clk_divider_1Hz + 1;
                    end
                end 
                else begin
                    full_output <= 0;
                end
            end
            else begin
                open_door_output <= 0;
                full_counter <= 0;
                door_counter <= 0;
                full_output <= 0;
            end
    end
end

endmodule
module main_tb;

    reg clk;
    reg reset;
    reg Entry_sensor;
    reg Exit_sensor;
    reg [1:0] Exit_parking;

    wire Full_light;
    wire Door_Open_light;
    wire [3:0] parkings;
    wire [2:0] capacity;
    wire [1:0] location;
    wire [2:0] state;

    // Instantiate the main module
    main uut (
        .clk(clk),
        .reset(reset),
        .Entry_sensor(Entry_sensor),
        .Exit_sensor(Exit_sensor),
        .Exit_parking(Exit_parking),
        .Full_light(Full_light),
        .Door_Open_light(Door_Open_light),
        .parkings(parkings),
        .capacity(capacity),
        .location(location),
        .state(state)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #1 clk = ~clk; // 50 MHz clock
    end

    // Test sequence
    initial begin
        $dumpfile("main_tb.vcd"); // Generate waveform file
        $dumpvars(1, main_tb);

        // Initial conditions
        reset = 1;
        Entry_sensor = 0;
        Exit_sensor = 0;
        Exit_parking = 2'b00;

        #2 reset = 0; // Deassert reset

        // Test: Entry to parking
        #50 Entry_sensor = 1; // Car at entry
        #60 Entry_sensor = 0; // Car entered

        // Test: Another entry
        #50 Entry_sensor = 1;
        #60 Entry_sensor = 0;

        // Test: Another entry
        #50 Entry_sensor = 1;
        #60 Entry_sensor = 0;

        // Test: Another entry
        #50 Entry_sensor = 1;
        #60 Entry_sensor = 0;

        // Test: Another entry
        #50 Entry_sensor = 1;
        #50 Entry_sensor = 0;

        // Wait for FULL state to complete (6 seconds)
        #100;

        // Test: Exit from parking
        #10 Exit_sensor = 1;
        Exit_parking = 2'b01; // Car exiting from location 1
        #40 Exit_sensor = 0;

        // Wait for DOOR_OPEN state to complete (10 seconds)
        #100;

        // Test: Reset and reinitialize
        #20 reset = 1;
        #40 reset = 0;

        #200 $finish; // End simulation
    end

    // Monitor signals
    initial begin
        $monitor("Time: %d | Reset: %b | Entry: %b | Exit: %b | Full: %b | Door: %b | Parkings: %b | Capacity: %b | Location: %b | State: %b",
            $time, reset, Entry_sensor, Exit_sensor, Full_light, Door_Open_light, parkings, capacity, location , state);
    end
endmodule