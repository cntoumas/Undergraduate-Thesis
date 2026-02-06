
module Top_module(
input top_clk,
input top_rst,
//slave
input in_data_valid,
input [7:0] in_data,
output out_data_ready,
//master
output out_data_valid,
output [7:0] out_data,
input in_data_ready,

output interrupt
);

wire [71:0] pixel_data;
wire pixel_data_valid;
wire axis_prog_full;
wire [7:0] conv_data;
wire conv_data_valid;

assign out_data_ready = !axis_prog_full; // FIFO control signal (negative)

ctrlunit CtrlUnit( // Instantiate control unit module
.clk(top_clk),
.rst(!top_rst), 
.pixel_data(in_data),
.pixel_data_valid(in_data_valid),
.out_pixel_data(pixel_data),
.out_pixel_data_valid(pixel_data_valid),
.interrupt(interrupt)
);

convolution Convo( // Instantiate convolution module
.clk(top_clk), 
.pixel_data(pixel_data), 
.pixel_data_valid(pixel_data_valid), 
.conv_data(conv_data), 
.conv_data_valid(convolved_data_valid) 
);


Output_FIFO OutputBuffer ( // Instantiate FIFO
  .s_aclk(top_clk),                  
  .s_aresetn(top_rst),           
  .s_axis_tvalid(convolved_data_valid),   
  .s_axis_tready(),    
  .s_axis_tdata(conv_data),      
  .m_axis_tvalid(out_data_valid),    
  .m_axis_tready(in_data_ready),    
  .m_axis_tdata(out_data),      
  .axis_prog_full(axis_prog_full)  
);
endmodule
