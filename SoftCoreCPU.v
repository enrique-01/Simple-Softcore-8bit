////////////////////////////////
// Enrique Alvarez Maciel
// 
//
// SoftCore RISC CPU 8-bit, Harvard*, 4 Registers 8-bit wide, Data + Instruction BUS
//
// Device Family: Cyclone IV E | Device Name: EP4CE115F29C7
//
////////////////////////////////
 
//OP Codes
`define ADD 6'b000000
`define AND 6'b000001
`define CMP 6'b000010
`define DEC 6'b000011
`define DIV 6'b000100
`define LOOP 6'b000101;
`define MOV 6'b000110;
`define MUL 6'b000111;
`define OR 6'b001000;
`define SUB 6'b001001;
`define XOR 6'b001010;
`define JMP 6'b001011;
`define ST 6'b001100;
`define LD 6'b001101;
`define NOT 6'100000;
`define OUT 6'b100001;
`define POP 6'b100010;
`define PUSH 6'b100011;
`define SHL 6'b100100;
`define SHR 6'b100101;
`define RET 6'b100110;
`define BRA 6'100111;
`define BEQ 6'b101000;
`define BHI 6'b101001;
`define NOP 6'b101010;




//States
`define FETCH 3'b001;
`define EXECUTE 3'b010;
`define WRITE 3'b100;


module SoftCoreCPU(CPU_CLK,reset,in_port,data_bus,address_bus,out_port);
	input CPU_CLK,reset;
	
	////Creating 4 in+out ports 8-bits wide
	input [7:0] in_port[3:0];
	output [7:0] out_port[3:0];

	///Creating Busses
	input [7:0] data_bus; //data_bus from software to CPU so one way*
	output [7:0] address_bus; //CPU to address bus
	
	////Registers
	reg [7:0] register[3:0]; //Registers Bank
	reg [7:0] program_counter;
	reg [7:0] stack_pointer;
	reg Z; //Zero Flag
	reg X; //Carry Bit
	//reg N; //Negative Flag *IMPLEMENT LATER*
	reg V; //Overflow flag
	reg A7;
	reg B7;
	////Memory 
	reg [7:0] memory[255:0];

	////State Machine
	reg [2:0] state_machine; //3 states currently *implement more?*

	////Defining Special and General Purpose Registers
	reg [5:0] instruction; //6-bits to accomdate sepcial OPCODES w/ no Register(s) needed
	reg [1:0] general_reg_one, general_reg_two; //2-bits wide for 4 posible Register Addresses
	reg A7,B7;
	reg [7:0] result; //concat result of all bits,etc
	
	//Wires
	wire [7:0] in_port[3:0];
	reg [7:0] out_port[3:0];
	wire [5:0] type_one_op_code; //4-bit op codes
	wire [5:0] type_two_op_code; //6-bit op codes
	wire [1:0] type_one__reg_A; //Reg A 
	wire [1:0] type_one_reg_B; //Reg B
	wire [1:0] type_two_reg_A; //Type 2 with only Reg A
	wire [7:0] argument;
	wire r7; //will have significant bit
	
	//Assignments
	assign address_bus = program_counter;
	assign type_one_op_code= {2'b00,data_bus[7:4]}; //4-bit op code
	assign type_two_op_code = data_bus[7:2]; //6-bit op code
	assign type_one_reg_A = data_bus[3:2];
	assign type_one_reg_B = data_bus[1:0];
	assign type_two_reg_B = data_bus[1:0];
	assign argument = data_bus;
	
	//State Machine
	always @(posedge CPU_CLK)begin
	if(reset)begin
		state_machine <= 0;
		program_counter <= 8'b00000000;
		stack_pointer <= 8'b11111111; //point to top of stack so 0xFF
		end
		else begin
			case(state_machine)
				`FETCH : begin
					if(data_bus[7] == 1'b0)begin
					instruction <= type_one_op_code;
					general_reg_one <= type_one_reg_A;
					general_reg_two <= type_one_regB;
					end
					else begin 
						instruction <= type_two_op_code;
						general_reg_two <= type_two_reg_B;
						case(type_two_op_code)
							'LOAD,
							'CMP,
							'BRA,
							'BHI,
							'BEQ: program_counter <= program_counter 8'd1;
							endcase 
						end
						state <= `EXECUTE;
					end 
					`EXECUTE : begin
						case(instruction)
							`ADD : begin 
							result <= register[general_register_one] + register[general_register_two];
							A7 <= register[general_register_one][7]; //used to pull significant bits for flags
							B7 <= register[general_register_two][7];	
							state_machine <= `WRITE;
						end 
							`MUL : begin //could have issues if they're are the same register being multiplied together
							{register[general_register_two],register[general_register_one]} <= register[general_register_one] * register[general_register_two];
							program_counter = program_counter + 1;
							state <= `FETCH;
						end 
							`MOV : begin
							register[general_register_one] <= register[general_register_two];
							Z <= (register[general_register_two]==0)?1:0; //Zero Flag?
							N <= register[general_register_two][7];
							V <= 0; //cant get overflow from transfer
							program_counter = program_counter + 1;
							state <= `FETCH;
						end
							`NOP : begin
							program_counter <= program_counter + 1;
							state_machine <= `FETCH;
						end 
							
							