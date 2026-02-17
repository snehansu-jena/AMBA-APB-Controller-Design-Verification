module master_bridge(
    input  [8:0] apb_write_paddr,
    input  [8:0] apb_read_paddr,
    input  [7:0] apb_write_data,
    input  [7:0] PRDATA,
    input        PRESETn,
    input        PCLK,
    input        READ_WRITE,
    input        transfer,
    input        PREADY,

    output reg   PSEL1,
    output reg   PSEL2,
    output reg   PENABLE,
    output reg [8:0] PADDR,
    output reg   PWRITE,
    output reg [7:0] PWDATA,
    output reg [7:0] apb_read_data_out,
    output reg   PSLVRR
);

    // Simple synchronous FSM with registered outputs
    localparam IDLE   = 3'b001,
               SETUP  = 3'b010,
               ENABLE = 3'b100;

    reg [2:0] state, next_state;

    // next-output signals (combinational)
    reg        next_enable;
    reg [8:0]  next_paddr;
    reg        next_pwrite;
    reg [7:0]  next_pwdata;
    reg        capture_read_data;

    // error flags (combinational)
    reg setup_error;
    reg invalid_read_paddr;
    reg invalid_write_paddr;
    reg invalid_write_data;
    reg invalid_setup_error_nxt;

    // ----------------------------------
    // State register & registered outputs
    // ----------------------------------
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            state             <= IDLE;
            PENABLE           <= 1'b0;
            PADDR             <= 9'd0;
            PWRITE            <= 1'b0;
            PWDATA            <= 8'd0;
            apb_read_data_out <= 8'd0;
            PSEL1             <= 1'b0;
            PSEL2             <= 1'b0;
            PSLVRR            <= 1'b0;
        end else begin
            state   <= next_state;
            PENABLE <= next_enable;
            PADDR   <= next_paddr;
            PWRITE  <= next_pwrite;
            PWDATA  <= next_pwdata;

            if (capture_read_data)
                apb_read_data_out <= PRDATA;

            // PSEL decode from address MSB
            if (state != IDLE) begin
                if (next_paddr[8]) begin
                    PSEL1 <= 1'b0;
                    PSEL2 <= 1'b1;
                end else begin
                    PSEL1 <= 1'b1;
                    PSEL2 <= 1'b0;
                end
            end else begin
                PSEL1 <= 1'b0;
                PSEL2 <= 1'b0;
            end

            PSLVRR <= invalid_setup_error_nxt;
        end
    end

    // ----------------------------------
    // Combinational next-state / outputs
    // ----------------------------------
    always @(*) begin
        // defaults
        next_state        = state;
        next_enable       = 1'b0;
        next_paddr        = PADDR;
        next_pwrite       = PWRITE;
        next_pwdata       = PWDATA;
        capture_read_data = 1'b0;

        setup_error             = 1'b0;
        invalid_read_paddr      = 1'b0;
        invalid_write_paddr     = 1'b0;
        invalid_write_data      = 1'b0;
        invalid_setup_error_nxt = 1'b0;

        case (state)
            IDLE: begin
                if (transfer) begin
                    next_state  = SETUP;
                    next_enable = 1'b0;
                    next_pwrite = ~READ_WRITE;
                    next_paddr  = READ_WRITE ? apb_read_paddr : apb_write_paddr;
                    next_pwdata = apb_write_data;
                end
            end

            SETUP: begin
                next_enable = 1'b0;
                next_pwrite = ~READ_WRITE;
                next_paddr  = READ_WRITE ? apb_read_paddr : apb_write_paddr;
                next_pwdata = apb_write_data;
                next_state  = PSLVRR ? IDLE : ENABLE;
            end

            ENABLE: begin
                next_enable = 1'b1;
                if (PSLVRR)
                    next_state = IDLE;
                else if (PREADY) begin
                    capture_read_data = READ_WRITE;
                    next_state = transfer ? SETUP : IDLE;
                    next_pwrite = ~READ_WRITE;
                    next_paddr  = READ_WRITE ? apb_read_paddr : apb_write_paddr;
                    next_pwdata = apb_write_data;
                end
            end

            default: next_state = IDLE;
        endcase

        // error checks
        if ((apb_write_data === 8'bx) && !READ_WRITE &&
            (state == SETUP || state == ENABLE))
            invalid_write_data = 1'b1;

        if ((apb_write_paddr === 9'bx) && !READ_WRITE &&
            (state == SETUP || state == ENABLE))
            invalid_write_paddr = 1'b1;

        if ((apb_read_paddr === 9'bx) && READ_WRITE &&
            (state == SETUP || state == ENABLE))
            invalid_read_paddr = 1'b1;

        if (state == SETUP) begin
            if (next_pwrite) begin
                if ((next_paddr !== apb_write_paddr) ||
                    (next_pwdata !== apb_write_data))
                    setup_error = 1'b1;
            end else begin
                if (next_paddr !== apb_read_paddr)
                    setup_error = 1'b1;
            end
        end

        invalid_setup_error_nxt =
            setup_error |
            invalid_read_paddr |
            invalid_write_paddr |
            invalid_write_data;
    end

endmodule
