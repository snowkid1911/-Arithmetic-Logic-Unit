module tb;
	localparam WIDTH = 8;
	localparam MASK  = (1 << WIDTH) - 1;
	localparam NRAND = 5000;
	reg [WIDTH-1:0] a, b;
	reg [3:0] op;
	wire [WIDTH-1:0] result;
	wire carry, overflow, zero, negative;
	alu #(WIDTH) dut(a, b, op, result, carry, overflow, zero, negative);
//	initial begin
//		a = 8'h7F; b = 8'h01; op = 0; #1;
//	end
	integer checks = 0;
	integer errors = 0;
	function to_singed;
		input integer v;
		begin
			to_singed = (v >= (1 << (WIDTH-1))) ? v - (1 << WIDTH) : v;
		end
	endfunction
	integer exp_result;
	reg exp_carry, exp_ovf, exp_zero, exp_neg;
	task model;
		input integer ia, ib;
		input [3:0] iop;
		integer sa, sb, tmp, sh;
		begin 
			exp_carry = 0;
			exp_ovf = 0;
			sa = to_singed(ia);
			sb = to_singed(ib);
			sh = ib % WIDTH;
			case(iop)
				0: begin
				  tmp = ia + ib;
				  exp_result = tmp & MASK;
				  exp_carry  = (tmp > MASK);
				  tmp = sa + sb;
				  exp_ovf    = (tmp > (1 << (WIDTH-1)) - 1) || (tmp < -(1 << (WIDTH-1)));
				end
				1: begin
				  tmp = ia - ib;
				  exp_result = tmp & MASK;
				  exp_carry  = (tmp < 0);
				  tmp = sa - sb;
				  exp_ovf    = (tmp > (1 << (WIDTH-1)) - 1) || (tmp < -(1 << (WIDTH-1)));
				end
				2: exp_result = ia & ib;
				3: exp_result = ia | ib;
				4: exp_result = ia ^ ib;
				5: exp_result = (~ia) & MASK;
				6: exp_result = (ia << sh) & MASK;
				7: exp_result = (ia >> sh) & MASK;
				8: begin
					tmp = sa;
					repeat (sh) tmp = (tmp >= 0) ? (tmp / 2) : ((tmp - 1) / 2);
					exp_result = tmp & MASK;
				end
				9: exp_result = (sa < sb) ? 1 : 0;
				default: exp_result = 0;
			endcase
			exp_zero = (exp_result == 0);
			exp_neg  = (exp_result >> (WIDTH-1)) & 1;
		end
	endtask
	task apply_and_check;
	input [WIDTH-1:0] ta, tb;
	input [3:0]       top;
	begin
		a = ta; b = tb; op = top;
		#1;
		model(ta, tb, top);
		checks = checks + 1;
		if (result !== exp_result[WIDTH-1:0] ||
			 carry !== exp_carry || overflow !== exp_ovf ||
			 zero !== exp_zero || negative !== exp_neg) begin
			 errors = errors + 1;
			 $display("[FAIL] t=%0t op=%0d a=%0d b=%0d | DUT: r=%0d c=%b v=%b z=%b n=%b | EXP: r=%0d c=%b v=%b z=%b n=%b",
						 $time, top, ta, tb,
						 result, carry, overflow, zero, negative,
						 exp_result, exp_carry, exp_ovf, exp_zero, exp_neg);
		end
	end
	endtask

	integer i, o;
	reg [WIDTH-1:0] corner [0:5];

	initial begin
	corner[0] = 8'h00;
	corner[1] = 8'hFF;
	corner[2] = 8'h01;
	corner[3] = 8'h7F;  // max dương
	corner[4] = 8'h80;  // min âm
	corner[5] = 8'hAA;

	// Directed: mọi phép toán x mọi cặp corner case
	for (o = 0; o <= 9; o = o + 1)
		for (i = 0; i < 36; i = i + 1)
			 apply_and_check(corner[i/6], corner[i%6], o[3:0]);

	// Opcode không hợp lệ
	for (o = 10; o <= 15; o = o + 1)
		apply_and_check($random, $random, o[3:0]);

	// Random
	for (i = 0; i < NRAND; i = i + 1)
		apply_and_check($random, $random, $urandom % 10);

	$display("--------------------------------");
	$display("Checks: %0d | Errors: %0d", checks, errors);
	if (errors == 0) $display("TEST PASSED");
	else             $display("TEST FAILED");
	$finish;
	end
endmodule