`timescale 1ns / 1ps

module FrequencyDividerController (

    input wire clk,

    input wire reset,

    input wire full,

    input wire open_door,

    output reg open_door_output,

    output reg full_output

);



  reg [ 3:0] full_counter;

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

    end else begin

      if (full) begin

        open_door_output <= 0;

        door_counter <= 0;

        if (full_counter < 6) begin

          if (clk_divider_1Hz == 40000000) begin

            full_counter <= full_counter + 1;

            full_output <= ~full_output;

            clk_divider_1Hz <= 0;

          end else begin

            clk_divider_1Hz <= clk_divider_1Hz + 1;

          end

        end else begin

          full_output <= 0;

        end

      end else if (open_door) begin

        full_output  <= 0;

        full_counter <= 0;

        if (door_counter < 40) begin

          if (clk_divider_2Hz == 10000000) begin

            door_counter <= door_counter + 1;

            open_door_output <= ~open_door_output;

            clk_divider_2Hz <= 0;

          end else begin

            clk_divider_2Hz <= clk_divider_2Hz + 1;

          end

        end else begin

          open_door_output <= 0;

        end

      end else begin

        open_door_output <= 0;

        full_counter <= 0;

        door_counter <= 0;

        full_output <= 0;

      end

    end

  end



endmodule





module seven_segment_display (

    input wire clk,

    input wire [19:0] s1a,

    output reg [7:0] set_Data,

    output reg [4:0] see_sel

);

  reg [ 3:0] digit;

  reg [ 1:0] digit_select;

  reg [21:0] refresh_counter;


  always @(posedge clk) begin

    if (refresh_counter[9] == 1) refresh_counter <= 0;

    else refresh_counter <= refresh_counter + 1;

  end



  always @(digit) begin

    case (digit)

      4'd0: set_Data = 8'b00111111;

      4'd1: set_Data = 8'b00000110;

      4'd2: set_Data = 8'b01011011;

      4'd3: set_Data = 8'b01001111;

      4'd4: set_Data = 8'b01100110;

      4'd5: set_Data = 8'b01101101;

      4'd6: set_Data = 8'b01111101;

      4'd7: set_Data = 8'b00000111;

      4'd8: set_Data = 8'b01111111;

      4'd9: set_Data = 8'b01101111;

      4'd10: set_Data = 8'b00111011;

      4'd10: set_Data = 8'b00000000;      

      default: set_Data = 8'b00000000;

    endcase

  end



  always @(posedge clk) begin

    if (refresh_counter[9] == 1) begin

      if (digit_select < 3) digit_select <= digit_select + 1;

      else digit_select <= 0;



      case (digit_select)

        3'b011: begin

          digit  = s1a[3:0];

          see_sel = 5'b00001;

        end

        3'b010: begin

          digit   = s1a[7:4];

          see_sel = 5'b00010;

        end

        3'b001: begin

          digit   = s1a[11:8];

          see_sel = 5'b00100;

        end

        3'b000: begin

          digit   = s1a[15:12];

          see_sel = 5'b01000;

        end
        3'b100: begin

          digit   = s1a[16];

          see_sel = 5'b01000;

        end

      endcase

    end

  end

endmodule






module main (

    input wire clk,

    input wire reset,

    input wire Entry_sensor,

    input wire Exit_sensor,

    input wire [1:0] Exit_parking,

    output wire Full_light,

    output wire Door_Open_light,

    output reg [3:0] parkings,

    output [4:0] seven_seg,

    output [7:0] seg_data

);



  parameter IDLE = 3'b000,

CHECK_ENTRY = 3'b001,

CHECK_EXIT = 3'b010,

FULL = 3'b011,

DOOR_OPEN = 3'b100;



  reg [2:0] current_state, next_state;

  reg [2:0] location, next_location;

  reg [2:0] capacity, next_capacity;

  reg internal_full, internal_open_door, timert;

  reg [31:0] delay_counter;
  reg [35:0] timer_counter;

  reg [3:0] next_parkings;

  reg [19:0] data7;

  reg [15:0] timer[3:0];
  reg [15:0] display_timer;
  reg [1:0] exit_slot;



  wire open_door;

  wire full;

  wire [19:0] data;



  assign data = data7;

  assign full = internal_full;

  assign open_door = internal_open_door;



  seven_segment_display display (

      .clk(clk),

      .s1a(data),

      .set_Data(seg_data),

      .see_sel(seven_seg)

  );



  FrequencyDividerController controller (

      .clk(clk),

      .reset(reset),

      .full(full),

      .open_door(open_door),

      .open_door_output(Door_Open_light),

      .full_output(Full_light)

  );



  initial begin

    current_state = IDLE;

    internal_full = 0;

    internal_open_door = 0;

    parkings = 4'b0000;

    next_parkings = 4'b0000;

    next_location = 3'b000;

    next_capacity = 3'b100;

    location = 3'b000;

    capacity = 3'b100;

  end



  always @(posedge clk) begin

    if(timert) begin
        data7[3:0] <= {1'b0 , display_timer[2] , display_timer[1] , display_timer[0]}
        data7[7:4] <= 0;
        data7[11:8] <= 0;
        data7[15:12] <= 0;
        data7[19:16] <= 4'd10;
    end else begin
        data7[3:0] <= {1'b0 , location};
        data7[7:4] <= 0;
        data7[11:8] <= 0;
        data7[15:12] <= {1'b0 , capacity};
        data7[19:16] <= 4'd11;
    end

  end







  always @(posedge clk) begin

    if (reset) begin

      delay_counter <= 0;

    end else if (internal_full) begin

      if (delay_counter <= 6 * 40000000) delay_counter <= delay_counter + 1;

      else delay_counter <= 0;

    end else if (internal_open_door) begin

      if (delay_counter <= 10 * 40000000) delay_counter <= delay_counter + 1;

      else delay_counter <= 0;

    end else if (timert) begin

      if (delay_counter <= 15 * 40000000) delay_counter <= delay_counter + 1;

      else delay_counter <= 0;

    end else begin

      delay_counter <= 0;

    end

  end
  always @(posedge clk or posedge reset) begin

    if (reset) begin

      current_state <= IDLE;

      parkings <= 4'b0000;

      location <= 3'b000;

      capacity <= 3'b100;
      timer[0] <= 0;
      timer[1] <= 0;
      timer[2] <= 0;
      timer[3] <= 0;

    end else begin

      current_state <= next_state;

      capacity <= next_capacity;

      parkings <= next_parkings;

      location <= next_location;
      if (timer_counter == 60 * 40000000) begin
        timer_counter = 0; // <= ????
        if (parkings[0]) timer[0] <= timer[0] + 1;
        if (parkings[1]) timer[1] <= timer[1] + 1;
        if (parkings[2]) timer[2] <= timer[2] + 1;
        if (parkings[3]) timer[3] <= timer[3] + 1;
      end
      else timer_counter = timer_counter + 1;

    end

  end



  always @(posedge clk) begin

    next_state = current_state;

    next_capacity = capacity;

    next_parkings = parkings;



    case (current_state)

      IDLE: begin

        internal_full = 0;

        internal_open_door = 0;

        if (~Entry_sensor) next_state = CHECK_ENTRY;

        else if (~Exit_sensor) next_state = CHECK_EXIT;

      end

      CHECK_ENTRY: begin

        if (capacity == 0 || location == 3'b111) begin

          next_state = FULL;

        end else begin

          next_parkings[location] = 1;

          next_capacity = capacity - 1;

          next_state = DOOR_OPEN;

        end

      end

      FULL: begin

        internal_full = 1;

        if (delay_counter == 6 * 40000000 - 2) begin

          internal_full = 0;

          next_state = IDLE;

        end

      end

      DOOR_OPEN: begin

        internal_open_door = 1;

        if (delay_counter == 10 * 40000000 - 2) begin

          internal_open_door = 0;

          next_state = IDLE;

        end

      end

      CHECK_EXIT: begin

        if (capacity == 3'b100 || parkings[Exit_parking] == 0) begin

          next_state = IDLE;

        end else begin

          next_parkings[Exit_parking] = 0;

          next_capacity = capacity + 1;

          next_state = DISPLAY_TIME;

        end

      end
      DISPLAY_TIME: begin
        timert = 1;
        if (delay_counter == 15 * 40000000 - 2) begin
          timer[Exit_parking] = 0;
          timert = 0;
          next_state = DOOR_OPEN;
        end else next_state = DISPLAY_TIME;
      end
    endcase

  end



  always @(posedge clk) begin
    next_location = (parkings[0] == 0) ? 3'b000 :

                    (parkings[1] == 0) ? 3'b001 :

                    (parkings[2] == 0) ? 3'b010 :

                    (parkings[3] == 0) ? 3'b011 : 3'b000;
  end
endmodule
