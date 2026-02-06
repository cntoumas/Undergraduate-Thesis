
module convolution(
input        clk, 
input [71:0] pixel_data, 
input        pixel_data_valid,
output reg [7:0] conv_data, 
output reg   conv_data_valid 
);
    
integer i; 
reg [7:0] kernel1 [8:0]; // x axis kernel
reg [7:0] kernel2 [8:0]; // y axis kernel
reg [10:0] muldata1[8:0]; // x axis multiplication data
reg [10:0] muldata2[8:0]; // y axis multiplication data
reg [10:0] sumdatatemp1; // x axis temp summed data
reg [10:0] sumdatatemp2; // y axis temp summed data
reg [10:0] sumdata1; // x axis final summed data
reg [10:1] sumdata2; // y axis final summed data
reg muldata_valid; 
reg sumdata_valid; 
reg convolved_data_valid; 
reg [20:0] conv_data_int1; // x axis squared data
reg [20:0] conv_data_int2; // y axis squared data
wire [21:0] conv_data_int; // Final squared data
reg conv_data_int_valid;

initial // create kernels (Sobel operator)
begin
    kernel1[0] =  1;
    kernel1[1] =  0;
    kernel1[2] = -1;
    kernel1[3] =  2;
    kernel1[4] =  0;
    kernel1[5] = -2;
    kernel1[6] =  1;
    kernel1[7] =  0;
    kernel1[8] = -1;
    
    kernel2[0] =  1;
    kernel2[1] =  2;
    kernel2[2] =  1;
    kernel2[3] =  0;
    kernel2[4] =  0;
    kernel2[5] =  0;
    kernel2[6] = -1;
    kernel2[7] = -2;
    kernel2[8] = -1;
end    
    
always @(posedge clk) // Multiply kernels with pixels. Signed multiplication because of the specific kernels
begin
    for(i=0;i<9;i=i+1)
    begin
        muldata1[i] <= $signed(kernel1[i])*$signed({1'b0,pixel_data[i*8+:8]}); 
        muldata2[i] <= $signed(kernel2[i])*$signed({1'b0,pixel_data[i*8+:8]}); 
    muldata_valid <= pixel_data_valid; 


always @(*) // Add data (signed addition).
begin
    sumdatatemp1 = 0; 
    sumdatatemp2 = 0; 
    for(i=0;i<9;i=i+1)
    begin
        sumdatatemp1 = $signed(sumdatatemp1) + $signed(muldata1[i]); 
        sumdatatemp2 = $signed(sumdatatemp2) + $signed(muldata2[i]); 
    end
end

always @(posedge clk) // Pass data to the final reg
begin
    sumdata1 <= sumdatatemp1; 
    sumdata2 <= sumdatatemp2; 
    sumdata_valid <= muldata_valid; 
end

always @(posedge clk) // Square the data before adding them (signed multiplication).
begin
    conv_data_int1 <= $signed(sumdata1)*$signed(sumdata1); 
    conv_data_int2 <= $signed(sumdata2)*$signed(sumdata2); 
    conv_data_int_valid <= sumdata_valid; 
end

assign conv_data_int = conv_data_int1 + conv_data_int2; // Add squared data and assign them to output

    
always @(posedge clk) // Specify the threshold of the edge detection
begin
    if(conv_data_int > 4000) 
        conv_data <= 8'hff; // Output pixel is white
    else
        conv_data <= 8'h00; 
    conv_data_valid <= conv_data_int_valid; // Output pixel is black
end
    
endmodule 