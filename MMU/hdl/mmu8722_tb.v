// `timescale 1ns/100ps // 1 ns time unit, 100 ps resolution
module mmu8722_tb ();

    reg clk, rst, rw;
    reg [15:0] a;
    reg [7:0] d_r;
    wire [7:0] d_q;

    mmu8722 DUT (
        .reset_i_n(rst),
        .clk_i(clk),
        .rw_i(rw),
        .addr_i(a),
        .d_q(d_q)
    );

    assign d_q = (rw == 0) ? d_r : 8'bz;

    initial begin
        clk = 1'b0;
        forever #1 clk = !clk;
    end

    initial begin
        rst = 1'b1;
        #2
        rst = 1'b0;
        #2
        rst = 1'b1;
    end

    initial begin
        $dumpfile("wave.vcd");      // create a VCD waveform dump called "wave.vcd"
        $dumpvars(0, mmu8722_tb); // dump variable changes in the testbench
        
        a = 16'h0000; 
        rw = 1'b1;
        d_r = 8'h00;
        #6
        a = 16'hd500;
        rw = 1'b0;
        d_r = 8'h55;
        #2
        a = 16'h0000;
        rw = 1'b1;
        d_r = 8'h00;
        #4
        a = 16'hd500;
        rw = 1'b1;
        #2
        a = 16'h0000;

        #10

        $finish();
        
    end

endmodule
