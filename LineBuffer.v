
module LineBuffer(
input clk, 
input rst, 
input [7:0] in_data, a 
input in_data_valid, 
input read_data, 
output [23:0] out_data 
);

reg [7:0] linebf [511:0]; // line buffer (memory) 
reg [8:0] writept; // write pointer (indicates where are the data writen in line buffer)
reg [8:0] readpt; // read pointer (indicate from where are the data read in line buffer)


always @ (posedge clk) // position pointer in the correct address
begin 
  if (in_data_valid)
   linebf[writept] <= in_data;
end  

always @ (posedge clk) // reset write pointer or change the address
begin
  if (rst)
    writept <= 'd0;
  else if (in_data_valid)
    writept <= writept + 'd1;
end

assign out_data = {linebf[readpt], linebf[readpt+1], linebf[readpt+2]}; // assing the output data before changing the read pointer

always @ (posedge clk) // reset read pointer or change the address
begin
  if (rst)
    readpt <= 'd0;
  else if (read_data)
    readpt <= readpt + 'd1;
end
  
endmodule

