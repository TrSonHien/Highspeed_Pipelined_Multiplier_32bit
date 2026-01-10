 module pipelined_mult (
    input clk,
    input rst,
    input [31:0] a,
    input [31:0] b,
    output reg [63:0] p
);

    // --- STAGE 1: INPUT SPLIT ---
    reg [15:0] a_h, a_l;
    reg [15:0] b_h, b_l;

    always @(posedge clk) begin
        if (rst) begin
            a_h <= 0; a_l <= 0; b_h <= 0; b_l <= 0;
        end else begin
            a_h <= a[31:16]; a_l <= a[15:0];
            b_h <= b[31:16]; b_l <= b[15:0];
        end
    end

    // --- STAGE 2: MULTIPLICATION ---
    reg [31:0] p_hh, p_hl, p_lh, p_ll;

    always @(posedge clk) begin
        if (rst) begin
            p_hh <= 0; p_hl <= 0; p_lh <= 0; p_ll <= 0;
        end else begin
            p_hh <= a_h * b_h;
            p_hl <= a_h * b_l;
            p_lh <= a_l * b_h;
            p_ll <= a_l * b_l;
        end
    end

    // --- STAGE 3: FIRST ADDITION (Cộng các phần chéo trước) ---
    // Thay vì cộng tất cả, nhịp này chỉ cộng HL + LH thôi cho nhẹ.
    reg [32:0] mid_sum;
    reg [31:0] p_hh_pipe, p_ll_pipe;

    always @(posedge clk) begin
        if (rst) begin
            mid_sum <= 0; p_hh_pipe <= 0; p_ll_pipe <= 0;
        end else begin
            mid_sum <= p_hl + p_lh; // Chỉ làm mỗi việc cộng 2 số này
            p_hh_pipe <= p_hh;      // Mấy cái kia chỉ việc đi chơi (truyền thẳng)
            p_ll_pipe <= p_ll;
        end
    end

    // --- STAGE 4: SECOND ADDITION (Chuẩn bị số hạng) ---
    // Tách việc dịch bit và cộng ra
    reg [63:0] term_high, term_mid, term_low;

    always @(posedge clk) begin
         if (rst) begin
            term_high <= 0; term_mid <= 0; term_low <= 0;
         end else begin
            term_high <= {32'b0, p_hh_pipe} << 32;
            term_mid  <= {31'b0, mid_sum}   << 16;
            term_low  <= {32'b0, p_ll_pipe};
         end
    end

    // --- STAGE 5: FINAL MERGE ---
    // Cộng 3 số hạng cuối cùng
    always @(posedge clk) begin
        if (rst) p <= 0;
        else p <= term_high + term_mid + term_low;
    end

endmodule 
