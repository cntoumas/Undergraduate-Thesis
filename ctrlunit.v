
module ctrlunit(
input clk,
input rst, 
input [7:0] pixel_data,
input pixel_data_valid,
output reg [71:0] out_pixel_data,
output out_pixel_data_valid,
output reg interrupt
);

reg [8:0] pixelcounter; // Counts pixels written in the line buffer. The range is 0 to 511
reg [1:0] currentwritebuffer; // Points in which line buffer we are currently writing
reg [3:0] LineBuffer_data_valid; // valid signal for line buffer
reg [3:0] read_data_valid; //valid signal for read
reg [1:0] currentreadbuffer; // Points from which line buffer we are currently reading 
reg [8:0] readcounter; // Counts pixels read from the line buffer.
reg [11:0] totalcounter; // counts the total pixels that have been processed
reg readstate; // Stores the states of the state machine 
reg readbuffer; // Control signal for reading operations 
  
wire [23:0] LB0data; // Connects LB0 with the control unit
wire [23:0] LB1data; // Connects LB1 with the control unit
wire [23:0] LB2data; // Connects LB2 with the control unit
wire [23:0] LB3data; // Connects LB3 with the control unit

localparam WAIT = 1'b0,
           READ = 1'b1;

assign out_pixel_data_valid = readbuffer; // Makes the output data valid whenever readbuffer is 1          

always @(posedge clk) //Counts the pixels needed to generate the readbuffer signal (1536). Adds 1 when write subtracts 1 when read
begin
  if (rst)
    totalcounter <= 0;
  else
  begin
    if (pixel_data_valid & !readbuffer)
      totalcounter <= totalcounter + 1;
    else if (!pixel_data_valid & readbuffer)
      totalcounter <= totalcounter - 1;
  end
end 

always @(posedge clk) // State machine. Wait state: wait for enough data to be stored in line buffers (at least 3 full buffers). Read state: begin reading data from line buffers
begin
  if (rst)
  begin
    readstate <= WAIT;
    readbuffer <= 1'b0;
    interrupt <= 1'b0;
  end
  else
  begin 
    case (readstate)
      WAIT:begin
             interrupt <= 1'b0;
             if (totalcounter >= 1536)
             begin 
               readbuffer <= 1'b1;
               readstate <= READ;
             end
           end
      READ:begin
             if (readcounter == 511)
             begin
               readstate <= WAIT;
               readbuffer <= 1'b0;
               interrupt <= 1'b1;
             end
           end
    endcase
  end
end

always @(posedge clk) // Counts the pixels that are writen in the line buffer 
begin
  if (rst)
    pixelcounter <= 0;
  else
  begin
    if (pixel_data_valid)
      pixelcounter <= pixelcounter + 1;
  end 
end

always @(posedge clk) // If the current line buffers is full pixelcounter overflows and the currentwritebuffer increases in order to write data in the next line buffer.
begin 
  if (rst)
    currentwritebuffer <=0;
  else
  begin
    if (pixelcounter == 511 & pixel_data_valid)
      currentwritebuffer <= currentwritebuffer + 1;
    end     
end

always @(*) // Makes the line buffer data valid zero except the one we are currently writing data so data are writen only in the valid one
begin
  LineBuffer_data_valid = 4'b0;
  LineBuffer_data_valid[currentwritebuffer] = pixel_data_valid;
end  

always @(posedge clk) // Counts the pixels that are read from the line buffer 
begin
  if (rst)
    readcounter <= 0;
  else
  begin
    if (readbuffer)
      readcounter <= readcounter + 1;
  end 
end

always @(posedge clk) //  If the current line buffers is full readcounter overflows and the currentreadbuffer increases in order to read data from the next line buffer.
begin
  if (rst)
    currentreadbuffer <=0;
  else
  begin
    if (readcounter == 511 & readbuffer)
      currentreadbuffer <= currentreadbuffer + 1;
    end     
end

always @(*) // Based on the currentreadbuffer we assign a diffrent trio of line buffers to the output
begin
  case(currentreadbuffer)
    0:begin 
        out_pixel_data = {LB2data, LB1data, LB0data};
      end
    1:begin 
        out_pixel_data = {LB3data, LB2data, LB1data};
      end 
    2:begin 
        out_pixel_data = {LB0data, LB3data, LB2data};
      end
    3:begin 
        out_pixel_data = {LB1data, LB0data, LB3data};
      end
  endcase
end  

always @(*) // Based on the currentreadbuffer we deactivate 1 line buffer using the read_data_valid signal
begin
  case (currentreadbuffer)
    0:begin
        read_data_valid[0] = readbuffer; 
        read_data_valid[1] = readbuffer; 
        read_data_valid[2] = readbuffer; 
        read_data_valid[3] = 1'b0; 
      end
    1:begin
        read_data_valid[0] = 1'b0; 
        read_data_valid[1] = readbuffer; 
        read_data_valid[2] = readbuffer; 
        read_data_valid[3] = readbuffer; 
      end
    2:begin
        read_data_valid[0] = readbuffer; 
        read_data_valid[1] = 1'b0;; 
        read_data_valid[2] = readbuffer; 
        read_data_valid[3] = readbuffer; 
      end
    3:begin
        read_data_valid[0] = readbuffer; 
        read_data_valid[1] = readbuffer; 
        read_data_valid[2] = 1'b0; 
        read_data_valid[3] = readbuffer; 
      end       
  endcase
end


LineBuffer LB0 ( //Line Buffer 0
  .clk(clk), 
  .rst(rst), 
  .in_data(pixel_data), 
  .in_data_valid(LineBuffer_data_valid[0]), 
  .read_data(read_data_valid[0]), 
  .out_data(LB0data) 
);

LineBuffer LB1 ( //Line Buffer 1
  .clk(clk), 
  .rst(rst), 
  .in_data(pixel_data), 
  .in_data_valid(LineBuffer_data_valid[1]), 
  .read_data(read_data_valid[1]), 
  .out_data(LB1data) 
);

LineBuffer LB2 ( //Line Buffer 2
  .clk(clk), 
  .rst(rst), 
  .in_data(pixel_data), 
  .in_data_valid(LineBuffer_data_valid[2]), 
  .read_data(read_data_valid[2]), 
  .out_data(LB2data) 
);

LineBuffer LB3 ( //Line Buffer 3
  .clk(clk), 
  .rst(rst), 
  .in_data(pixel_data), 
  .in_data_valid(LineBuffer_data_valid[3]), 
  .read_data(read_data_valid[3]), 
  .out_data(LB3data) 
);



endmodule
