
module convolution(
input clk, // clock
input [71:0] pixel_data, // input data from line buffers (3 line buffer x 24 bits = 72 bits input)
input pixel_data_valid, 
output reg [7:0] conv_data, // output data (8 bits because of the convolution operation with kernel)
output reg conv_data_valid 
)

reg [7:0] kernel [8:0];
reg [15:0] muldata [8:0];
reg [15:0] sumdatatemp;
reg [15:0] sumdata;
reg muldata_valid;
reg sumdata_valid;
reg convolved_data_valid;
integer i;

initial begin // creation of kernel (Box blur)
  for (i=0; i<9; i=i+1)
    begin 
      kernel[i]=1;
    end 
  end

always @(posedge clk) // multiply the kernel with the pixel data
begin 
  for (i=0; i<9; i=i+1)
    begin
      muldata[i] <= kernel[i]*pixel_data[i*8+:8];
    end 
  muldata_valid <= pixel_data_valid; // 1st level of pipeline  
end 

always @(*) // add data 
begin
    sumdatatemp = 0;
    for(i=0;i<9;i=i+1)
    begin
        sumdatatemp = sumdatatemp + muldata[i];
    end
end

always @(posedge clk) // pass data to the final reg
begin
  sumdata <= sumdatatemp;
  sumdata_valid <= muldata_valid; // 2nd level of pipeline
end 

always @(posedge clk)// divide summed data with 9 to create the final result of the kernel
begin
  conv_data <= sumdata/9;
  conv_data_valid= sumdata_valid; // 3rd level of pipeline
end

endmodule
