`include "./src/struct_s.sv"
//`define DUMMY
module rule_packer_32_128 (
    input   logic           clk,
    input   logic           rst,
    input   logic           in_rule_sop,
    input   logic           in_rule_eop,
    input   logic [1:0]     in_rule_empty,
    input   logic           in_rule_valid,
    input   logic [31:0]    in_rule_data,
    output  logic           in_rule_ready,

    output  logic           out_rule_sop,
    output  logic           out_rule_eop,
    output  logic           out_rule_valid,
    output  logic [128:0]   out_rule_data,
    output  logic [3:0]     out_rule_empty,
    input   logic           out_rule_ready
);


`ifdef DUMMY
    assign out_rule_sop   = in_rule_sop;
    assign out_rule_empty = in_rule_empty;
    assign out_rule_eop   = in_rule_eop;
    assign out_rule_data  = in_rule_data;
    assign out_rule_valid = in_rule_valid;
    assign in_rule_ready  = out_rule_ready;
`else
logic [3:0] int_cnt;


assign out_rule_sop = 0;
assign out_rule_empty = 0;

// Convert to 512 bit for PCIe.
assign in_rule_ready = !(in_rule_eop & int_cnt != 0) & out_rule_ready;

always @(posedge clk) begin
    if (rst) begin
        int_cnt <= 0;
        out_rule_eop <= 0;
        out_rule_data <= 0;
        out_rule_valid <= 0;
    end else begin
        if(out_rule_ready)begin
            out_rule_eop <= 0;
            out_rule_valid <= 0;
            if (in_rule_valid) begin
                if (in_rule_eop) begin
                    // Fetch, write, clear the output
                    if (int_cnt == 0) begin
                        out_rule_valid <= 1;
                        out_rule_eop <= 1;
                    end else begin
                    // Forward the valid data first. Clear the
                    // cnt, then forward the last. Wait, write
                    // whatever is there.
                        int_cnt <= 0;
                        out_rule_valid <= 1;
                    end
                end else begin
                    // Fetch and write
                    if (int_cnt == 3) begin
                        int_cnt <= 0;
                        out_rule_valid <= 1;
                    end else begin
                    // Fetch, do not write
                        int_cnt <= int_cnt + 1;
                    end
                end
            end
        end
    end

    // Clear the data
    if (in_rule_valid) begin
        if (int_cnt == 0) begin
            out_rule_data <= 0;
        end
        case (int_cnt)
            4'd0:  out_rule_data[31:0]    <= in_rule_data;
            4'd1:  out_rule_data[63:32]   <= in_rule_data;
            4'd2:  out_rule_data[95:64]   <= in_rule_data;
            4'd3:  out_rule_data[127:96]  <= in_rule_data;
            default: out_rule_data <= 0;
        endcase
    end
end
`endif


endmodule
