
`define HeaderSize 1080 // bmp header size
`define IMG 512*512 // Image resolution

module Testbench(

    );
    
reg clk;
reg rst;
reg [7:0] imgdata;
reg imgdatavalid; 

integer file;
integer file_out;
integer i;
integer sentdata;
integer receiveddata=0;

wire intr;
wire [7:0] outdata;
wire outdatavalid;
    
initial // clock signal
begin
  clk = 1'b0;
  forever 
  begin
    #5 clk = ~clk;
  end
end  

initial // reset signal
begin 
    rst = 0;
    sentdata = 0;
    imgdatavalid = 0;
    #100;
    rst = 1;
    #100;
    
    file = $fopen("owl_in.bmp","rb"); // Open input file
    file_out = $fopen("owl_out.bmp","wb"); // Open output file

    for(i=0;i<`HeaderSize;i=i+1) // Write header in the output file
    begin
        $fscanf(file,"%c",imgdata);
        $fwrite(file_out,"%c",imgdata);
    end
    
    for(i=0;i<4*512;i=i+1) Load 4 rows of pixels to the line buffers so the processing can start
    begin
        @(posedge clk);
        $fscanf(file,"%c",imgdata);
        imgdatavalid <= 1'b1;       
    end
    
    sentdata = 4*512;
   @(posedge intr); // 1st empty line for top row 
    for(i=0;i<512;i=i+1)
        begin
            @(posedge clk);
            imgdata <= 0;
            imgdatavalid <= 1'b1;
        end

    @(posedge clk); // Send the rest of the image data for processing
    imgdatavalid <= 1'b0;
    while(sentdata<`IMG)
    begin 
        @(posedge intr);
        for(i=0;i<512;i=i+1)
        begin
            @(posedge clk);
            $fscanf(file,"%c",imgdata);
            imgdatavalid <= 1'b1;
        end
        
        @(posedge clk);
        imgdatavalid <= 1'b0;
        sentdata = sentdata+512;
    end  
    @(posedge clk);
    imgdatavalid <= 1'b0;

    @(posedge intr); // 2nd empty line for the bottom row
    for(i=0;i<512;i=i+1)
        begin
            @(posedge clk);
            imgdata <= 0;
            imgdatavalid <= 1'b1;
        end
        @(posedge clk);
        imgdatavalid <= 1'b0;
      
        @(posedge clk); // close the input file
        imgdatavalid <= 1'b0;
        $fclose(file);
end

always @(posedge clk) / write the processed data to the output file
 begin
     if(outdatavalid)
     begin
         $fwrite(file_out,"%c",outdata);
         receiveddata = receiveddata+1;
     end 
     if(receiveddata == `IMG)
     begin
        $fclose(file_out); // Close output file
        $stop; // Stop simulation
     end
 end

    
        

Top_module dut( // Instantiate top module
.top_clk(clk),
.top_rst(rst),
.in_data_valid(imgdatavalid),
.in_data(imgdata),
.out_data_ready(),
.out_data_valid(outdatavalid),
.out_data(outdata),
.in_data_ready(1'b1),
.interrupt(intr)
);    
    
endmodule
