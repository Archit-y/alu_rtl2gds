// -----------------------------------------------------------------------------
// alu.v
// Parameterized synchronous ALU
// Supports: ADD, SUB, AND, OR, XOR, NOT, SLL, SRL, SLT, PASS
// Registered output (single clock domain, active-low async reset)
// -----------------------------------------------------------------------------

module alu #(
    parameter WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [WIDTH-1:0]      a,
    input  wire [WIDTH-1:0]      b,
    input  wire [3:0]            opcode,
    input  wire                  valid_in,

    output reg  [WIDTH-1:0]      result,
    output reg                   zero_flag,
    output reg                   carry_flag,
    output reg                   overflow_flag,
    output reg                   valid_out
);

    // Opcode encoding
    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b0001;
    localparam ALU_AND  = 4'b0010;
    localparam ALU_OR   = 4'b0011;
    localparam ALU_XOR  = 4'b0100;
    localparam ALU_NOT  = 4'b0101;
    localparam ALU_SLL  = 4'b0110;
    localparam ALU_SRL  = 4'b0111;
    localparam ALU_SLT  = 4'b1000;
    localparam ALU_PASS = 4'b1001;

    reg [WIDTH:0]  add_ext;
    reg [WIDTH:0]  sub_ext;
    reg [WIDTH-1:0] alu_result;
    reg             c_flag;
    reg             ovf_flag;

    always @(*) begin
        add_ext  = {1'b0, a} + {1'b0, b};
        sub_ext  = {1'b0, a} - {1'b0, b};
        c_flag   = 1'b0;
        ovf_flag = 1'b0;
        alu_result = {WIDTH{1'b0}};

        case (opcode)
            ALU_ADD: begin
                alu_result = add_ext[WIDTH-1:0];
                c_flag     = add_ext[WIDTH];
                ovf_flag   = (a[WIDTH-1] == b[WIDTH-1]) &&
                             (alu_result[WIDTH-1] != a[WIDTH-1]);
            end
            ALU_SUB: begin
                alu_result = sub_ext[WIDTH-1:0];
                c_flag     = sub_ext[WIDTH];
                ovf_flag   = (a[WIDTH-1] != b[WIDTH-1]) &&
                             (alu_result[WIDTH-1] != a[WIDTH-1]);
            end
            ALU_AND:  alu_result = a & b;
            ALU_OR:   alu_result = a | b;
            ALU_XOR:  alu_result = a ^ b;
            ALU_NOT:  alu_result = ~a;
            ALU_SLL:  alu_result = a << b[$clog2(WIDTH)-1:0];
            ALU_SRL:  alu_result = a >> b[$clog2(WIDTH)-1:0];
            ALU_SLT:  alu_result = ($signed(a) < $signed(b)) ? {{(WIDTH-1){1'b0}}, 1'b1}
                                                               : {WIDTH{1'b0}};
            ALU_PASS: alu_result = a;
            default:  alu_result = {WIDTH{1'b0}};
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result        <= {WIDTH{1'b0}};
            zero_flag     <= 1'b0;
            carry_flag    <= 1'b0;
            overflow_flag <= 1'b0;
            valid_out     <= 1'b0;
        end else begin
            result        <= alu_result;
            zero_flag     <= (alu_result == {WIDTH{1'b0}});
            carry_flag    <= c_flag;
            overflow_flag <= ovf_flag;
            valid_out     <= valid_in;
        end
    end

endmodule
