module slave1(
    input        PCLK,
    input        PRESETn,
    input        PSEL,
    input        PENABLE,
    input        PWRITE,
    input  [7:0] PADDR,
    input  [7:0] PWDATA,
    output [7:0] PRDATA1,
    output reg   PREADY
);

    reg [7:0] reg_addr;
    reg [7:0] mem [0:63];

    assign PRDATA1 = mem[reg_addr];

    // ----------------------------------
    // Sequential logic (storage updates)
    // ----------------------------------
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            reg_addr <= 8'd0;
        end else begin
            if (PSEL && PENABLE && !PWRITE) begin
                reg_addr <= PADDR;
            end
            if (PSEL && PENABLE && PWRITE) begin
                mem[PADDR] <= PWDATA;
            end
        end
    end

    // ----------------------------------
    // Combinational READY generation
    // ----------------------------------
    always @(*) begin
        PREADY = 1'b0;

        if (PSEL && PENABLE)
            PREADY = 1'b1;
    end

endmodule
