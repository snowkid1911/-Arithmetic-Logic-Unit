module alu #(
	parameter WIDTH = 8
)(
	input [WIDTH-1:0] a, b,
	input [3:0] op,
	output reg [WIDTH-1:0] result,
	output reg carry, overflow,
	output zero, negative
);
	assign zero = result == 0;
	assign negative = result[WIDTH-1];
	reg [WIDTH:0] ext;
	always @(*) begin
		ext = 9'd0;
		result = 8'd0;
		carry = 1'd0;
		overflow = 1'd0;
		case(op)
			4'd0: begin //add
				ext = {1'b0, a} + {1'b0, b};
				result = ext[WIDTH-1:0];
				carry = ext[WIDTH];
				overflow = (a[WIDTH-1] == b[WIDTH-1]) && (result[WIDTH-1] != a[WIDTH-1]);
			end
			4'd1: begin //sub
				ext = {1'b0, a} - {1'b0, b};
				result = ext[WIDTH-1:0];
				carry = ext[WIDTH];
				overflow = (a[WIDTH-1] != b[WIDTH-1]) && (result[WIDTH-1] != a[WIDTH-1]);
			end
			4'd2: result = a & b;
			4'd3: result = a | b;
			4'd4: result = a ^ b;
			4'd5: result = ~a;
			4'd6: result = a << b[2:0];
			4'd7: result = a >> b[2:0];
			4'd8: result = $signed(a) >>> b[2:0];
			4'd9: result = ($signed(a) < $signed(b)) ? 1 : 0;
			default : result = 0;
		endcase
	end
endmodule