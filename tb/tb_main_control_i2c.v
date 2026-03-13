`timescale 1ns / 1ps

module tb_main_control_i2c;

    // Endereco do escravo e bytes completos de endereco + bit R/W.
    localparam [6:0] I2C_SLAVE_ADDR = 7'h6A;
    localparam [7:0] I2C_ADDR_WR    = {I2C_SLAVE_ADDR, 1'b0};
    localparam [7:0] I2C_ADDR_RD    = {I2C_SLAVE_ADDR, 1'b1};

    // Clock interno do DUT e temporizacao aproximada do barramento I2C da TB.
    localparam integer CLK_PERIOD_NS      = 10;
    localparam integer I2C_HALF_PERIOD_NS = 200;

    reg         clk;
    reg         rstn;
    reg         scl;
    reg  [31:0] err_count;
    reg  [3:0]  sync;

    reg         sda_master_drive_low;
    tri1        sda;

    wire [1:0]  mux_control;
    wire        en_reset_counter;

    reg  [31:0] rd_data;
    reg  [31:0] cfg_word;
    reg         ok;
    integer     error_count_tb;

    // O master da TB so consegue forcar '0' em SDA. O '1' vem do pull-up.
    assign sda = sda_master_drive_low ? 1'b0 : 1'bz;

    main_control dut (
        .clk             (clk),
        .rstn            (rstn),
        .err_count       (err_count),
        .sync            (sync),
        .sda             (sda),
        .scl             (scl),
        .mux_control     (mux_control),
        .en_reset_counter(en_reset_counter)
    );

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD_NS/2) clk = ~clk;
    end

    initial begin
        // Valores iniciais de estimulo e barramento em idle.
        rstn                = 1'b0;
        scl                 = 1'b1;
        err_count           = 32'h4433_2211;
        sync                = 4'b0000;
        sda_master_drive_low = 1'b0;
        rd_data             = 32'h0000_0000;
        cfg_word            = 32'h0000_0000;
        ok                  = 1'b0;
        error_count_tb      = 0;

        repeat (5) @(posedge clk);
        rstn = 1'b1;
        repeat (10) @(posedge clk);

        // Le o registrador de configuracao para conferir os defaults do reset.
        $display("TB: leitura do registrador 0x00 apos reset");
        i2c_read_reg32(8'h00, rd_data, ok);
        if (!ok) begin
            $display("TB ERROR: leitura de 0x00 falhou por NACK");
            error_count_tb = error_count_tb + 1;
        end else if (rd_data !== 32'h0000_0E40) begin
            $display("TB ERROR: 0x00 = %h, esperado = 00000E40", rd_data);
            error_count_tb = error_count_tb + 1;
        end

        sync = 4'b1111;
        repeat (20) @(posedge clk);

        // Le o registrador de status apos sinal presente em todos os canais.
        $display("TB: leitura do registrador 0x01 com status inicial");
        i2c_read_reg32(8'h01, rd_data, ok);
        if (!ok) begin
            $display("TB ERROR: leitura de 0x01 falhou por NACK");
            error_count_tb = error_count_tb + 1;
        end else if (rd_data !== 32'h0000_003C) begin
            $display("TB ERROR: 0x01 = %h, esperado = 0000003C", rd_data);
            error_count_tb = error_count_tb + 1;
        end

        cfg_word = {20'h00010, 8'hE4, 2'b10, 1'b1, 1'b1};

        // Escreve fallback/manual/manual_channel/channel_priority/reset_timer via I2C.
        $display("TB: escrita no registrador 0x00 para habilitar manual channel 2");
        i2c_write_reg32(8'h00, cfg_word, ok);
        if (!ok) begin
            $display("TB ERROR: escrita de 0x00 falhou por NACK");
            error_count_tb = error_count_tb + 1;
        end

        repeat (30) @(posedge clk);

        // Confere efeito da escrita no banco interno e na saida de selecao do topo.
        if (dut.mm_mapped.mm_reg[0] !== cfg_word) begin
            $display("TB ERROR: mm_reg[0] = %h, esperado = %h", dut.mm_mapped.mm_reg[0], cfg_word);
            error_count_tb = error_count_tb + 1;
        end

        if (mux_control !== 2'd2) begin
            $display("TB ERROR: mux_control = %0d, esperado = 2", mux_control);
            error_count_tb = error_count_tb + 1;
        end

        // Le os contadores vindos da entrada err_count do topo.
        $display("TB: leitura do registrador 0x02 com contadores fixos");
        i2c_read_reg32(8'h02, rd_data, ok);
        if (!ok) begin
            $display("TB ERROR: leitura de 0x02 falhou por NACK");
            error_count_tb = error_count_tb + 1;
        end else if (rd_data !== 32'h4433_2211) begin
            $display("TB ERROR: 0x02 = %h, esperado = 44332211", rd_data);
            error_count_tb = error_count_tb + 1;
        end

        // Rele o status para confirmar que o canal ativo refletiu a configuracao manual.
        $display("TB: leitura do registrador 0x01 apos escrita de configuracao");
        i2c_read_reg32(8'h01, rd_data, ok);
        if (!ok) begin
            $display("TB ERROR: leitura de 0x01 apos configuracao falhou por NACK");
            error_count_tb = error_count_tb + 1;
        end else if (rd_data !== 32'h0000_003E) begin
            $display("TB ERROR: 0x01 apos configuracao = %h, esperado = 0000003E", rd_data);
            error_count_tb = error_count_tb + 1;
        end

        if (error_count_tb == 0)
            $display("TB PASS: todas as verificacoes passaram");
        else
            $display("TB FAIL: %0d verificacoes falharam", error_count_tb);

        #1000;
        $stop;
    end

    // Pequeno atraso reutilizado pelas tasks do barramento.
    task i2c_bus_wait;
        begin
            #(I2C_HALF_PERIOD_NS);
        end
    endtask

    // START: SDA desce enquanto SCL permanece em nivel alto.
    task i2c_start;
        begin
            sda_master_drive_low = 1'b0;
            scl = 1'b1;
            i2c_bus_wait;
            sda_master_drive_low = 1'b1;
            i2c_bus_wait;
            scl = 1'b0;
            i2c_bus_wait;
        end
    endtask

    // STOP: SDA sobe enquanto SCL permanece em nivel alto.
    task i2c_stop;
        begin
            sda_master_drive_low = 1'b1;
            i2c_bus_wait;
            scl = 1'b1;
            i2c_bus_wait;
            sda_master_drive_low = 1'b0;
            i2c_bus_wait;
        end
    endtask

    // Escreve um bit em barramento open-drain: '1' = libera SDA, '0' = puxa SDA para baixo.
    task i2c_write_bit;
        input bit_value;
        begin
            scl = 1'b0;
            sda_master_drive_low = ~bit_value;
            i2c_bus_wait;
            scl = 1'b1;
            i2c_bus_wait;
            scl = 1'b0;
            i2c_bus_wait;
        end
    endtask

    // Le um bit gerado pelo escravo durante a fase alta de SCL.
    task i2c_read_bit;
        output bit_value;
        begin
            scl = 1'b0;
            sda_master_drive_low = 1'b0;
            i2c_bus_wait;
            scl = 1'b1;
            i2c_bus_wait;
            bit_value = sda;
            scl = 1'b0;
            i2c_bus_wait;
        end
    endtask

    // Envia um byte MSB-first e amostra o bit de ACK do escravo.
    task i2c_write_byte;
        input  [7:0] tx_byte;
        output       ack_ok;
        integer      idx;
        reg          ack_bit;
        begin
            for (idx = 7; idx >= 0; idx = idx - 1)
                i2c_write_bit(tx_byte[idx]);

            i2c_read_bit(ack_bit);
            ack_ok = (ack_bit == 1'b0);
        end
    endtask

    // Le um byte MSB-first e devolve ACK/NACK ao escravo ao final.
    task i2c_read_byte;
        output [7:0] rx_byte;
        input        ack_to_slave;
        integer      idx;
        reg          sampled_bit;
        begin
            rx_byte = 8'h00;
            for (idx = 7; idx >= 0; idx = idx - 1) begin
                i2c_read_bit(sampled_bit);
                rx_byte[idx] = sampled_bit;
            end

            i2c_write_bit(~ack_to_slave);
        end
    endtask

    // Protocolo de escrita usado pela bridge:
    // SLA+W, endereco do registrador e quatro bytes de payload.
    task i2c_write_reg32;
        input  [7:0]  reg_addr;
        input  [31:0] reg_data;
        output        success;
        reg           ack_ok_local;
        begin
            success = 1'b1;

            i2c_start;

            i2c_write_byte(I2C_ADDR_WR, ack_ok_local);
            success = success & ack_ok_local;

            i2c_write_byte(reg_addr, ack_ok_local);
            success = success & ack_ok_local;

            i2c_write_byte(reg_data[31:24], ack_ok_local);
            success = success & ack_ok_local;

            i2c_write_byte(reg_data[23:16], ack_ok_local);
            success = success & ack_ok_local;

            i2c_write_byte(reg_data[15:8], ack_ok_local);
            success = success & ack_ok_local;

            i2c_write_byte(reg_data[7:0], ack_ok_local);
            success = success & ack_ok_local;

            i2c_stop;
            repeat (8) @(posedge clk);
        end
    endtask

    // Protocolo de leitura:
    // primeiro aponta o registrador com SLA+W, depois faz repeated START com SLA+R.
    task i2c_read_reg32;
        input  [7:0]  reg_addr;
        output [31:0] reg_data;
        output        success;
        reg           ack_ok_local;
        reg  [7:0]    byte3;
        reg  [7:0]    byte2;
        reg  [7:0]    byte1;
        reg  [7:0]    byte0;
        begin
            success = 1'b1;
            reg_data = 32'h0000_0000;

            i2c_start;

            i2c_write_byte(I2C_ADDR_WR, ack_ok_local);
            success = success & ack_ok_local;

            i2c_write_byte(reg_addr, ack_ok_local);
            success = success & ack_ok_local;

            i2c_start;

            i2c_write_byte(I2C_ADDR_RD, ack_ok_local);
            success = success & ack_ok_local;

            i2c_read_byte(byte3, 1'b1);
            i2c_read_byte(byte2, 1'b1);
            i2c_read_byte(byte1, 1'b1);
            i2c_read_byte(byte0, 1'b0);

            reg_data = {byte3, byte2, byte1, byte0};

            i2c_stop;
            repeat (8) @(posedge clk);
        end
    endtask

endmodule
