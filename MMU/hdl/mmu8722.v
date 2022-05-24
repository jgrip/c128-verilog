module mmu8722 (
    input        reset_i_n,
    input        rw_i,
    input [15:0] addr_i,
    input        clk_i,
    input        k4080,

    output       ms3_o,
    output [7:0] taddr_o,
    output       cas0,
    output       cas1,

    inout [7:0]  d_q
);

    reg [7:0] d_r;
    wire d_d;

    // Internal registers
    reg [7:0] cr_r;
    reg [7:0] pcr_r[3:0];
    reg [11:0] page0_r;
    reg [11:0] page1_r;
    reg [3:0] page0_h_r;
    reg [3:0] page1_h_r;

    // Mode Configuration Register
    reg cpu_r;        // CPU selection: 0 = Z80, 1 = 8502
    reg os_r;         // OS mode: 0 = C128, 1 = C64
    reg fsdir_r;      // Fast serial direction: 0 = in, 1 = out
    reg game_r;       // GAME input from cartridge port
    reg exrom_r;      // EXROM input from cartridge port

    // RAM Configuration Register
    reg [1:0] rcr_common_s_r;
    reg       rcr_common_h_r;
    reg       rcr_common_l_r;
    reg [1:0] vicbank_r;

    wire cs_d500 = (addr_i >= 16'hd500 && addr_i <= 16'hd50b);
    wire cs_ff00 = (addr_i >= 16'hff00 && addr_i <= 16'hff04);

    assign d_d = rw_i && (cs_d500 | cs_ff00);
    assign d_q = d_d ? d_r : 8'bz;

    /* Register write and chip reset */
    always @(negedge clk_i or negedge reset_i_n) begin
        if (~reset_i_n) begin
            cr_r <= 8'h00;
            pcr_r[0] <= 8'h00;
            pcr_r[1] <= 8'h00;
            pcr_r[2] <= 8'h00;
            pcr_r[3] <= 8'h00;
            page0_r <= 12'h000;
            page0_h_r <= 4'h0;
            page1_r <= 12'h000;
            page1_h_r <= 4'h0;
            cpu_r <= 0;
            os_r <= 0;
            fsdir_r <= 1;
            game_r <= 1;
            exrom_r <= 1;
            rcr_common_s_r <= 2'b00;
            rcr_common_l_r <= 0;
            rcr_common_h_r <= 0;
            vicbank_r <= 2'b00;
        end else if (rw_i == 0) begin
            if (cs_d500 && os_r == 0) begin
                case (addr_i[4:0])
                    0 : cr_r <= d_q;
                    1 : pcr_r[0] <= d_q;
                    2 : pcr_r[1] <= d_q;
                    3 : pcr_r[2] <= d_q;
                    4 : pcr_r[3] <= d_q;
                    5 : begin
                            cpu_r <= d_q[0];
                            fsdir_r <= d_q[3];
                            game_r <= d_q[4];
                            exrom_r <= d_q[5];
                            os_r <= d_q[6];
                        end
                    6 : begin
                            rcr_common_s_r <= d_q[1:0];
                            rcr_common_l_r <= d_q[2];
                            rcr_common_h_r <= d_q[3];
                            vicbank_r <= d_q[7:6]; 
                        end
                    7 : begin
                            page0_r[7:0] <= d_q;
                            page0_r[11:8] <= page0_h_r;
                        end
                    8 : begin
                            page0_h_r <= d_q[3:0];
                        end
                    9 : begin
                            page1_r[7:0] <= d_q;
                            page1_r[11:8] <= page1_h_r;
                        end
                    10: begin
                            page1_h_r <= d_q[3:0];
                        end
                endcase
            end else if (cs_ff00) begin
                case (addr_i[4:0])
                    0 : cr_r <= d_q;
                    1 : cr_r <= pcr_r[0];
                    2 : cr_r <= pcr_r[1];
                    3 : cr_r <= pcr_r[2];
                    4 : cr_r <= pcr_r[3];
                endcase
            end
        end
    end

    always @(*) begin
        if (rw_i == 1 && cs_d500 && os_r == 0) begin
            case (addr_i[4:0])
                0 : d_r = cr_r;
                1 : d_r = pcr_r[0];
                2 : d_r = pcr_r[1];
                3 : d_r = pcr_r[2];
                4 : d_r = pcr_r[3];
                5 : d_r = {k4080, os_r, exrom_r, game_r, fsdir_r, 2'b00, cpu_r};
                6 : d_r = {vicbank_r, 2'b00, rcr_common_h_r, rcr_common_l_r, rcr_common_s_r};
                7 : d_r = page0_r[7:0];
                8 : d_r = {4'b0000, page0_r[11:8]};
                9 : d_r = page1_r[7:0];
                10: d_r = {4'b0000, page1_r[11:8]};
                11: d_r = 8'h20;
            endcase
        end
    end

    /* Outputs */
    reg [7:0] taddr_r;

    assign ms3_o = os_r;
    assign taddr_o = taddr_r;

    always @(*) begin
        if (os_r == 0) begin
            // C128 mode
            taddr_r <= addr_i[15:8];
        end else begin
            // C64 mode
            taddr_r <= addr_i[15:8];
        end
    end


endmodule
