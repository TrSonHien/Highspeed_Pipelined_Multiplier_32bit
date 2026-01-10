module pipelined_mult (
    input clk,
    input rst,
    input [31:0] a,
    input [31:0] b,
    output reg [63:0] p
);

    // =========================================================
    // STAGE 1: INPUT SPLIT & REGISTER
    // Tách input thành 2 phần 16-bit để chuẩn bị cho nhân nhỏ
    // =========================================================
    reg [15:0] a_h, a_l;
    reg [15:0] b_h, b_l;
    
    always @(posedge clk) begin
        if (rst) begin
            a_h <= 0; a_l <= 0; b_h <= 0; b_l <= 0;
        end else begin
            a_h <= a[31:16]; 
            a_l <= a[15:0];
            b_h <= b[31:16]; 
            b_l <= b[15:0];
        end
    end

    // =========================================================
    // STAGE 2: 16-BIT MULTIPLICATION
    // Nhân chéo các cặp 16-bit (DSP slices hoạt động tốt ở đây)
    // =========================================================
    reg [31:0] p_hh, p_hl, p_lh, p_ll;
    
    always @(posedge clk) begin
        if (rst) begin
            p_hh <= 0; p_hl <= 0; p_lh <= 0; p_ll <= 0;
        end else begin
            p_hh <= a_h * b_h; // High * High
            p_hl <= a_h * b_l; // High * Low
            p_lh <= a_l * b_h; // Low * High
            p_ll <= a_l * b_l; // Low * Low
        end
    end

    // =========================================================
    // STAGE 3: MIDDLE ADDITION
    // Cộng 2 phần ở giữa: (A_h * B_l) + (A_l * B_h)
    // Các phần HH và LL được register (truyền thẳng) để đợi
    // =========================================================
    reg [32:0] mid_sum; // 33-bit để chứa carry nếu có
    reg [31:0] p_hh_st3, p_ll_st3;

    always @(posedge clk) begin
        if (rst) begin
            mid_sum  <= 0;
            p_hh_st3 <= 0;
            p_ll_st3 <= 0;
        end else begin
            mid_sum  <= p_hl + p_lh; 
            p_hh_st3 <= p_hh;
            p_ll_st3 <= p_ll;
        end
    end

    // =========================================================
    // STAGE 4: HIGH PART ADDITION (TỐI ƯU HÓA Ở ĐÂY)
    // Thay vì chỉ dịch bit, ta thực hiện cộng High + Mid tại đây.
    // Việc này giảm tải cho Stage 5.
    // =========================================================
    reg [63:0] sum_upper; // Chứa kết quả của (HH << 32) + (Mid << 16)
    reg [31:0] p_ll_st4;  // LL tiếp tục đợi thêm 1 nhịp

    always @(posedge clk) begin
         if (rst) begin
            sum_upper <= 0;
            p_ll_st4  <= 0;
         end else begin
            // Logic: High nằm ở bit [63:32], Mid nằm ở [48:16]
            // Cộng 2 thằng này lại trước.
            sum_upper <= ({32'b0, p_hh_st3} << 32) + ({15'b0, mid_sum} << 16);
            
            // Lưu thằng Low lại để nhịp sau cộng nốt
            p_ll_st4  <= p_ll_st3;
         end
    end

    // =========================================================
    // STAGE 5: FINAL MERGE
    // Bây giờ chỉ cần cộng nốt phần Low vào là xong.
    // Phép cộng 64-bit này nhẹ hơn nhiều so với cộng 3 số.
    // =========================================================
    always @(posedge clk) begin
        if (rst) begin
            p <= 0;
        end else begin
            p <= sum_upper + {32'b0, p_ll_st4};
        end
    end

endmodule
