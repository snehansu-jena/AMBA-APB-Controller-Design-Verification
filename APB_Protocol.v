`timescale 1ns/1ns

module APB_Protocol(
    input        PCLK,
    input        PRESETn,
    input        transfer,
    input        READ_WRITE,
    input  [7:0] apb_write_paddr,
    input  [8:0] apb_read_paddr,
    output       PSLVERR,
    output [7:0] apb_read_data_out
);

    wire [7:0] PWDATA;
    wire [7:0] PRDATA;
    wire [7:0] PRDATA1, PRDATA2;
    wire [8:0] PADDR;
    wire       PREADY, PREADY1, PREADY2;
    wire       PENABLE, PSEL1, PSEL2, PWRITE;

    // FIXED: broken ternary
    assign PREADY = PADDR[8] ? PREADY2 : PREADY1;

    // FIXED: safe PRDATA mux
    assign PRDATA = READ_WRITE ? 
                    (PADDR[8] ? PRDATA2 : PRDATA1) :  8'b0;

    master_bridge dut_mas (
        .apb_write_paddr(apb_write_paddr),
        .apb_read_paddr (apb_read_paddr),
        .PRDATA         (PRDATA),
        .PRESETn        (PRESETn),
        .PCLK           (PCLK),
        .READ_WRITE     (READ_WRITE),
        .transfer       (transfer),
        .PREADY         (PREADY),
        .PSEL1          (PSEL1),
        .PSEL2          (PSEL2),
        .PENABLE        (PENABLE),
        .PADDR          (PADDR),
        .PWRITE         (PWRITE),
        .PWDATA         (PWDATA),
        .apb_read_data_out(apb_read_data_out),
        .PSLVERR        (PSLVERR)
    );

    slave1 dut1 (
        PCLK, PRESETn, PSEL1, PENABLE, PWRITE,
        PADDR[7:0], PWDATA, PRDATA1, PREADY1
    );

    slave2 dut2 (
        PCLK, PRESETn, PSEL2, PENABLE, PWRITE,
        PADDR[7:0], PWDATA, PRDATA2, PREADY2
    );

endmodule
