module mmu8722 (
    input       reset_in,
    input       rw_in,
    input[15:0] addr_in,
    input       clk,

    output      ms3_out,
    output[7:0] page_out,

    inout[7:0]  d_d
);

    wire rst = ~reset_in;

    wire d_dir;

    // Internal registers
    reg[7:0] reg_cr;
    reg[7:0] reg_pcr[3:0];
    reg[9:0] reg_page0;
    reg[9:0] reg_page1;
    reg[1:0] reg_page0_hb;
    reg[1:0] reg_page1_hb;

    // Mode Configuration Register
    reg reg_cpu;        // CPU selection: 0 = Z80, 1 = 8502
    reg reg_os;         // OS mode: 0 = C128, 1 = C64
    reg reg_fsdir;      // Fast serial direction: 0 = in, 1 = out
    reg reg_game;       // GAME input from cartridge port
    reg reg_exrom;      // EXROM input from cartridge port

    // RAM Configuration Register
    reg[1:0]    reg_common_size;
    reg         reg_common_low;
    reg         reg_common_high;
    reg[1:0]    reg_vicbank;

    wire cs_d500;
    wire cs_ff00;

    // assign cs_d500 = addr_in[15:4] == 12'hd50;
    assign cs_d500 = (addr_in >= 16'hd500 && addr_in <= 16'hd50b);
    // assign cs_ff00 = addr_in[15:4] == 12'hff0;
    assign cs_ff00 = (addr_in >= 16'hff00 && addr_in <= 16'hff04);

    assign d_dir = (rw_in == 1) & (cs_d500 | cs_ff00);

    /* Register write and chip reset */
    always @(negedge clk) begin
        if (rst) begin
            reg_cr <= 8'h00;
            reg_pcr[0] <= 8'h00;
            reg_pcr[1] <= 8'h00;
            reg_pcr[2] <= 8'h00;
            reg_pcr[3] <= 8'h00;
            reg_page0 <= 10'h000;
            reg_page1 <= 10'h000;
            reg_cpu <= 0;
            reg_os <= 0;
            reg_fsdir <= 1;
            reg_game <= 1;
            reg_exrom <= 1;
            reg_common_size <= 2'b00;
            reg_common_low <= 0;
            reg_common_high <= 0;
            reg_vicbank <= 2'b00;
        end else if (rw_in == 1) begin
            if (cs_d500) begin
                case (addr_in[4:0])
                    0 : reg_cr <= d_d;
                    1 : reg_pcr[0] <= d_d;
                    2 : reg_pcr[1] <= d_d;
                    3 : reg_pcr[2] <= d_d;
                    4 : reg_pcr[3] <= d_d;
                    5 : begin
                            reg_cpu <= d_d[0];
                            reg_fsdir <= d_d[3];
                            reg_game <= d_d[4];
                            reg_exrom <= d_d[5];
                            reg_os <= d_d[6];
                        end
                    6 : begin
                            reg_common_size <= d_d[1:0];
                            reg_common_low <= d_d[2];
                            reg_common_high <= d_d[3];
                            reg_vicbank <= d_d[7:6]; 
                        end
                    7 : begin
                            reg_page0[7:0] <= d_d;
                            reg_page0[9:8] <= reg_page0_hb;
                        end
                    8 : begin
                            reg_page0_hb <= d_d[1:0];
                        end
                    9 : begin
                            reg_page1[7:0] <= d_d;
                            reg_page1[9:8] <= reg_page1_hb;
                        end
                    10: begin
                            reg_page1_hb <= d_d[1:0];
                        end
                endcase
            end else if (cs_ff00) begin
                case (addr_in[4:0])
                    0 : reg_cr <= d_d;
                    1 : reg_cr <= reg_pcr[0];
                    2 : reg_cr <= reg_pcr[1];
                    3 : reg_cr <= reg_pcr[2];
                    4 : reg_cr <= reg_pcr[3];
                endcase
            end
        end
    end

    /* Register reads */
    reg[7:0] d_out;

    assign d_d = (d_dir) ? d_out : 8'bz;

    always @(posedge clk) begin
        if (rw_in == 0 && (cs_d500 | cs_ff00)) begin
            case (addr_in[4:0])
                0 : d_out <= reg_cr;
                1 : d_out <= reg_pcr[0];
                2 : d_out <= reg_pcr[1];
                3 : d_out <= reg_pcr[2];
                4 : d_out <= reg_pcr[3];
            endcase
        end
    end

    /* Outputs */
    reg[7:0] taddr_out;

    assign ms3_out = reg_os;
    assign page_out = taddr_out;

    always @(posedge clk) begin
        if (reg_os == 0) begin
            // C128 mode
            taddr_out <= addr_in[15:8];
        end else begin
            // C64 mode
            
        end
    end


endmodule
