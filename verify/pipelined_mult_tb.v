`timescale 1ns / 1ps

module tb_pipelined_mult;

    // 1. Tín hiệu giao tiếp với DUT
    reg clk;
    reg rst;
    reg [31:0] a;
    reg [31:0] b;
    wire [63:0] p;

    // 2. Gọi Module (Device Under Test)
    pipelined_mult uut (
        .clk(clk),
        .rst(rst),
        .a(a),
        .b(b),
        .p(p)
    );

    // 3. Tạo Clock 500MHz (Chu kỳ 2ns)
    initial begin
        clk = 0;
        forever #1 clk = ~clk; 
    end

    // 4. PIPELINE REFERENCE MODEL (Mô hình tham chiếu)
    // Vì mạch DUT có 5 tầng thanh ghi, ta cần 5 biến trễ để so sánh
    reg [63:0] exp_1, exp_2, exp_3, exp_4, exp_5;
    reg [63:0] exp_final; // Biến này sẽ nối với exp_5

    // Logic tính toán kết quả đúng (Behavioral) - Chạy ở cạnh LÊN
    always @(posedge clk) begin
        if (rst) begin
            exp_1 <= 0; exp_2 <= 0; exp_3 <= 0; 
            exp_4 <= 0; exp_5 <= 0;
        end else begin
            // Bước 1: Tính toán chuẩn (Golden calculation)
            // Ép kiểu về 64-bit trước khi nhân để tránh tràn số
            exp_1 <= {32'd0, a} * {32'd0, b}; 
            
            // Bước 2: Dịch chuyển qua 5 giai đoạn để khớp với độ trễ của DUT
            exp_2 <= exp_1;
            exp_3 <= exp_2;
            exp_4 <= exp_3;
            exp_5 <= exp_4; 
            // Sau dòng này, exp_5 chứa kết quả ứng với input của 5 chu kỳ trước
        end
    end

    // Gán kết quả mong đợi cuối cùng
    always @(*) exp_final = exp_5;

    // 5. CHECKER (Trọng tài) - Chạy ở cạnh XUỐNG
    // Kiểm tra lệch pha để đảm bảo tín hiệu đã ổn định
    integer error_count = 0;
    
    always @(negedge clk) begin
        if (!rst && $time > 20) begin // Bỏ qua giai đoạn Reset
            if (p !== exp_final) begin
                $display("[ERROR] Time %0t: Mismatch!", $time);
                $display("  Input A: %d, Input B: %d (Input cũ 5 nhịp trước)", a, b); 
                // Lưu ý: A, B hiển thị ở đây là A, B *mới* đang vào, không phải A, B tạo ra lỗi này
                // Muốn debug kỹ phải nhìn Waveform
                $display("  DUT Output : %h (%d)", p, p);
                $display("  Expected   : %h (%d)", exp_final, exp_final);
                error_count = error_count + 1;
            end
        end
    end

    // 6. STIMULUS (Kịch bản Test)
    initial begin
        // Khởi tạo
        rst = 1; a = 0; b = 0;
        #20; // Giữ reset 10 chu kỳ
        rst = 0;
        
        $display("==================================================");
        $display("   BẮT ĐẦU TEST BENCH CHO 5-STAGE PIPELINE");
        $display("==================================================");

        // --- TEST CASE 1: Cơ bản ---
        @(posedge clk); a = 2; b = 3;         // Exp = 6
        @(posedge clk); a = 10; b = 20;       // Exp = 200
        @(posedge clk); a = 100; b = 100;     // Exp = 10000

        // --- TEST CASE 2: Corner Cases (Số đặc biệt) ---
        @(posedge clk); a = 0; b = 12345;     // Nhân với 0
        @(posedge clk); a = 1; b = 99999;     // Nhân với 1
        @(posedge clk); a = 32'hFFFFFFFF; b = 1; // Số lớn nhất 32bit * 1
        @(posedge clk); a = 32'hFFFFFFFF; b = 32'hFFFFFFFF; // Max * Max (Test 64bit Output)

        // --- TEST CASE 3: Random Stress Test ---
        $display("Running 2000 Random Vectors...");
        repeat (2000) begin
            @(posedge clk);
            a = $urandom; 
            b = $urandom;
        end

        // Chờ kết quả cuối cùng chui ra khỏi ống
        repeat (10) @(posedge clk);

        $display("==================================================");
        if (error_count == 0) begin
            $display("   TEST PASSED! TUYỆT VỜI ÔNG MẶT TRỜI! :D");
            $display("   Mạch chạy đúng 5-Stage Pipeline.");
        end else begin
            $display("   TEST FAILED! Có %0d lỗi xảy ra.", error_count);
        end
        $display("==================================================");
        $finish;
    end

    // Tạo file sóng
    initial begin
        $dumpfile("tb_pipelined_mult.vcd");
        $dumpvars(0, tb_pipelined_mult);
    end

endmodule
