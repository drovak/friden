// Friden EC-130 (4-counter) simulation
// Kyle Owen - 3 July 2022

parameter DELAY_LINE_LENGTH = 1800;
parameter KEYBOARD_DELAY = 100;

module top (
	input clk, // master clock, 8x TOSC4 = 2666.667 kHz

    // calculator keys
    // 1: pressed, 0: not pressed
    // thou shalt not press multiple keys at the same time
    input key_of_lock,
    input key_chg_sign,
    input key_repeat,
    input key_div,
    input key_clr_ent,
    input key_enter,
    input key_mult,
    input key_clr_all,
    input key_sub,
    input key_add,
    input key_store,
    input key_recall,
    input key_dp,
    input key_0,
    input key_1,
    input key_2,
    input key_3,
    input key_4,
    input key_5,
    input key_6,
    input key_7,
    input key_8,
    input key_9,

    // decimal point selector switch
    // allows for DP at positions 0 to 13
    input [3:0] sw_dp,

    // overflow lamp and keyboard lock solenoid outputs
    output lamp_overflow,
    output kbd_lock,

    // feedback for key presses (for those that use the EKBD3 signal, anyways)
    output kbd_ack,

    // phase counter output
    output reg [2:0] phase,

    // A, B, C, and D counter output, as BCD (or 0xF for invalid state)
    output [3:0] a_cnt,
    output [3:0] b_cnt,
    output [3:0] c_cnt,
    output [3:0] d_cnt,

    // decimal point counter output
    output [3:0] dp_cnt,

    // all of the important flip-flops in the calculator
    output ff_start,
    output ff_chg_sign,
    output ff_shift_down,
    output ff_store,
    output ff_recall,
    output ff_repeat,
    output ff_mult,
    output ff_div,
    output ff_com_dig,
    output ff_com_fun,
    output ff_add_sub,
    output ff_cfs,
    output ff_sign_cont,
    output ff_dps,
    output ff_of,
    output ff_carry,
    output ff_carry_of,
    output ff_home,

    // the complete timing chain output
    output [13:0] timing,

    // finally, the main working registers, decoded from the delay line
    // these are unpacked outputs
    output reg [3:0] reg_4 [0:15],
    output reg [3:0] reg_3 [0:15],
    output reg [3:0] reg_2 [0:15],
    output reg [3:0] reg_1 [0:15],
    output reg [3:0] reg_0 [0:15],
    output reg [3:0] reg_s [0:15],

    // these are packed outputs
    output reg [15:0][3:0] reg_4_l,
    output reg [15:0][3:0] reg_3_l,
    output reg [15:0][3:0] reg_2_l,
    output reg [15:0][3:0] reg_1_l,
    output reg [15:0][3:0] reg_0_l,
    output reg [15:0][3:0] reg_s_l
);

// get rid of annoying unused warnings
/* verilator lint_off UNUSED */

// debugging output
reg [2:0] reg_cnt;
reg [3:0] col_cnt;
reg [3:0] dig_cnt;

reg TFD2_prev;

reg [13:0] timing_dbg;

// decode the data on the delay line and such
always @(posedge TFD1) begin
    reg_cnt <= {TFG1, TFF1, TFE1};
    col_cnt <= {TFL1, TFK1, TFJ1, TFH1};
end

always @(posedge clk_div_4) begin
    TFD2_prev <= TFD2;

    if (clk_div_8)
        timing_dbg <= {TFN1, TFM1, TFL1, TFK1, TFJ1, TFH1, TFG1, TFF1, TFE1, TFD1, TFC1, TFB1, TFA1, TCLK2};

    if (TFA1 & TFB2 & TFC2 & TFD2)
        dig_cnt <= 0;
    else if (!XRDL4)
        dig_cnt <= dig_cnt + 1;

    if (TFD2 & !TFD2_prev) begin
        if (reg_cnt == 3'o6) begin
            reg_s[col_cnt] <= dig_cnt;
            reg_s_l[col_cnt] <= dig_cnt;
        end
        if (reg_cnt == 3'o7) begin
            reg_0[col_cnt] <= dig_cnt;
            reg_0_l[col_cnt] <= dig_cnt;
        end
        if (reg_cnt == 3'o0) begin
            reg_1[col_cnt] <= dig_cnt;
            reg_1_l[col_cnt] <= dig_cnt;
        end
        if (reg_cnt == 3'o1) begin
            reg_2[col_cnt] <= dig_cnt;
            reg_2_l[col_cnt] <= dig_cnt;
        end
        if (reg_cnt == 3'o2) begin
            reg_3[col_cnt] <= dig_cnt;
            reg_3_l[col_cnt] <= dig_cnt;
        end
        if (reg_cnt == 3'o3) begin
            reg_4[col_cnt] <= dig_cnt;
            reg_4_l[col_cnt] <= dig_cnt;
        end
    end
end

always @(posedge TFL1) begin
    phase <= {PC41, PC21, PC11};
end

assign dp_cnt = {DC81, DC41, DC21, DC11};
assign ff_chg_sign = ECS1;
assign ff_shift_down = ESD1;
assign ff_store = ESTO1;
assign ff_recall = ERC1;
assign ff_repeat = ERP1;
assign ff_add_sub = EAS1;
assign ff_mult = EMU1;
assign ff_div = EDV1;
assign ff_com_dig = ECD1;
assign ff_com_fun = ECF1;
assign ff_cfs = ECFS1;
assign ff_sign_cont = ASC1;
assign ff_dps = EDPS1;
assign ff_of = AOFL1;
assign ff_carry = ACRY1;
assign ff_carry_of = ACOF1;
assign ff_start = ESTA1;
assign ff_home = HOME1;
assign timing = timing_dbg;

// decode the ring counters to BCD
wire [4:0] CA = {CA51, CA41, CA31, CA21, CA11};
wire [4:0] CB = {CB51, CB41, CB31, CB21, CB11};
wire [4:0] CC = {CC51, CC41, CC31, CC21, CC11};
wire [4:0] CD = {CD51, CD41, CD31, CD21, CD11};
always @(*) begin
    if (CA == 5'b00000)
        a_cnt = 0;
    else if (CA == 5'b00001)
        a_cnt = 1;
    else if (CA == 5'b00011)
        a_cnt = 2;
    else if (CA == 5'b00111)
        a_cnt = 3;
    else if (CA == 5'b01111)
        a_cnt = 4;
    else if (CA == 5'b11111)
        a_cnt = 5;
    else if (CA == 5'b11110)
        a_cnt = 6;
    else if (CA == 5'b11100)
        a_cnt = 7;
    else if (CA == 5'b11000)
        a_cnt = 8;
    else if (CA == 5'b10000)
        a_cnt = 9;
    else
        a_cnt = 4'hf;

    if (CB == 5'b00000)
        b_cnt = 0;
    else if (CB == 5'b00001)
        b_cnt = 1;
    else if (CB == 5'b00011)
        b_cnt = 2;
    else if (CB == 5'b00111)
        b_cnt = 3;
    else if (CB == 5'b01111)
        b_cnt = 4;
    else if (CB == 5'b11111)
        b_cnt = 5;
    else if (CB == 5'b11110)
        b_cnt = 6;
    else if (CB == 5'b11100)
        b_cnt = 7;
    else if (CB == 5'b11000)
        b_cnt = 8;
    else if (CB == 5'b10000)
        b_cnt = 9;
    else
        b_cnt = 4'hf;

    if (CC == 5'b00000)
        c_cnt = 0;
    else if (CC == 5'b00001)
        c_cnt = 1;
    else if (CC == 5'b00011)
        c_cnt = 2;
    else if (CC == 5'b00111)
        c_cnt = 3;
    else if (CC == 5'b01111)
        c_cnt = 4;
    else if (CC == 5'b11111)
        c_cnt = 5;
    else if (CC == 5'b11110)
        c_cnt = 6;
    else if (CC == 5'b11100)
        c_cnt = 7;
    else if (CC == 5'b11000)
        c_cnt = 8;
    else if (CC == 5'b10000)
        c_cnt = 9;
    else
        c_cnt = 4'hf;

    if (CD == 5'b00000)
        d_cnt = 0;
    else if (CD == 5'b00001)
        d_cnt = 1;
    else if (CD == 5'b00011)
        d_cnt = 2;
    else if (CD == 5'b00111)
        d_cnt = 3;
    else if (CD == 5'b01111)
        d_cnt = 4;
    else if (CD == 5'b11111)
        d_cnt = 5;
    else if (CD == 5'b11110)
        d_cnt = 6;
    else if (CD == 5'b11100)
        d_cnt = 7;
    else if (CD == 5'b11000)
        d_cnt = 8;
    else if (CD == 5'b10000)
        d_cnt = 9;
    else
        d_cnt = 4'hf;
end

// master clock divider
// AC gates simulate the capacitor charging/discharging, so
// we need a slightly faster clock for them versus the rest of
// the calculator
//
// also, edge detection for FFs is done with the master clock
reg clk_div_2;
reg clk_div_4;
reg clk_div_8;
always @(posedge clk) begin
    clk_div_2 <= !clk_div_2;
    if (clk_div_2) begin
        clk_div_4 <= !clk_div_4;
        if (clk_div_4)
            clk_div_8 <= !clk_div_8;
    end
end

// INPUT AND START
wire ESTA1, ESTA2;
ff START_1010 (
    .clk(clk),
    .rst_l(1'b0),
    .set_l(key_clr_all),
    .set_p(1'b0),
    .rst_p(EKBD3),
    .tog_p(1'b0),
    .q(ESTA1),
    .q_n(ESTA2)
);
wire ESTA3 = !ESTA2;

// keyboard decoding
wire sw_com_dig = key_0 | key_1 | key_2 | key_3 | key_4 | key_5 | key_6 | key_7 | key_8 | key_9;
wire sw_com_fun = key_chg_sign | key_repeat | key_div | key_enter | key_mult | key_sub |
                  key_add | key_store | key_recall;

reg XB597;
reg XB487;
reg XB377;
reg XB267;
reg XB157;

always @(posedge sw_com_dig) begin
    XB597 <= key_5 | key_6 | key_7 | key_8 | key_9;
    XB487 <= key_4 | key_5 | key_6 | key_7 | key_8;
    XB377 <= key_3 | key_4 | key_5 | key_6 | key_7;
    XB267 <= key_2 | key_3 | key_4 | key_5 | key_6;
    XB157 <= key_1 | key_2 | key_3 | key_4 | key_5;
end

// originally, this would be a 6 ms delay for debouncing
// the keyboard reed switches, but any value should work
// since bouncing contacts is not a problem here
reg [6:0] kbd_cnt;
always @(posedge clk) begin
    if (key_clr_ent | key_dp | sw_com_dig | sw_com_fun) begin
        if (kbd_cnt < KEYBOARD_DELAY-1)
            kbd_cnt <= kbd_cnt + 1;
    end
    else
        kbd_cnt <= 0;
end

wire EKBD3 = (kbd_cnt == KEYBOARD_DELAY-1);
assign kbd_ack = EKBD3;

wire s_1051;
ac AC_1051 (
    .clk(clk),
    .en(key_chg_sign),
    .trans(EKBD3),
    .out(s_1051)
);
wire ECS1, ECS2;
ff CHANGE_SIGN_1050 (
    .clk(clk),
    .rst_l(ERF3),
    .set_l(s_1051),
    .set_p(1'b0),
    .rst_p(1'b0),
    .tog_p(1'b0),
    .q(ECS1),
    .q_n(ECS2)
);

wire XCE7 = key_clr_ent;
wire s_1032, aofl2_ac, eas1_ac;
ac AC_1032 (
    .clk(clk),
    .en(XCE7),
    .trans(EKBD3),
    .out(s_1032)
);
ac AC_AOFL2 (
    .clk(clk),
    .en(1'b1),
    .trans(AOFL2),
    .out(aofl2_ac)
);
ac AC_EAS1 (
    .clk(clk),
    .en(1'b1),
    .trans(EAS1),
    .out(eas1_ac)
);
wire ESD1, ESD2;
ff SHIFT_DOWN_1030 (
    .clk(clk),
    .rst_l(ERF3),
    .set_l(s_1032 | aofl2_ac | eas1_ac),
    .set_p(1'b0),
    .rst_p(1'b0),
    .tog_p(ESTO1),
    .q(ESD1),
    .q_n(ESD2)
);

wire s_1041;
ac AC_1041 (
    .clk(clk),
    .en(key_store),
    .trans(EKBD3),
    .out(s_1041)
);
wire ESTO1, ESTO2;
ff STORE_1040 (
    .clk(clk),
    .rst_l(ERF3),
    .set_l(s_1041),
    .set_p(1'b0),
    .rst_p(1'b0),
    .tog_p(1'b0),
    .q(ESTO1),
    .q_n(ESTO2)
);

wire s_1071;
ac AC_1071 (
    .clk(clk),
    .en(key_recall),
    .trans(EKBD3),
    .out(s_1071)
);
wire ERC1, ERC2;
ff RECALL_1070 (
    .clk(clk),
    .rst_l(ERF3),
    .set_l(s_1071),
    .set_p(1'b0),
    .rst_p(1'b0),
    .tog_p(1'b0),
    .q(ERC1),
    .q_n(ERC2)
);

wire s_1061;
ac AC_1061 (
    .clk(clk),
    .en(key_repeat),
    .trans(EKBD3),
    .out(s_1061)
);
wire ERP1, ERP2;
ff REPEAT_1060 (
    .clk(clk),
    .rst_l(ERF3),
    .set_l(s_1061),
    .set_p(1'b0),
    .rst_p(1'b0),
    .tog_p(1'b0),
    .q(ERP1),
    .q_n(ERP2)
);

wire s_1091;
ac AC_1091 (
    .clk(clk),
    .en(key_mult),
    .trans(EKBD3),
    .out(s_1091)
);
wire EMU1, EMU2;
ff MULT_1090 (
    .clk(clk),
    .rst_l(ERF3),
    .set_l(s_1091),
    .set_p(1'b0),
    .rst_p(1'b0),
    .tog_p(1'b0),
    .q(EMU1),
    .q_n(EMU2)
);

wire s_1081;
ac AC_1081 (
    .clk(clk),
    .en(key_div),
    .trans(EKBD3),
    .out(s_1081)
);
wire EDV1, EDV2;
ff DIV_1080 (
    .clk(clk),
    .rst_l(ERF3),
    .set_l(s_1081),
    .set_p(1'b0),
    .rst_p(1'b0),
    .tog_p(1'b0),
    .q(EDV1),
    .q_n(EDV2)
);

wire s_1112, s_1111;
ac AC_1112 (
    .clk(clk),
    .en(key_dp),
    .trans(DBSL3),
    .out(s_1112)
);
ac AC_1111 (
    .clk(clk),
    .en(sw_com_dig),
    .trans(EKBD3),
    .out(s_1111)
);
wire ECD1, ECD2;
ff COM_DIG_1110 (
    .clk(clk),
    .rst_l(r_1104 | EROF9),
    .set_l(s_1112 | s_1111),
    .set_p(1'b0),
    .rst_p(1'b0),
    .tog_p(1'b0),
    .q(ECD1),
    .q_n(ECD2)
);

wire ECFS1, ECFS2;
ff CFS_1120 (
    .clk(clk),
    .rst_l(1'b0),
    .set_l(EROF9),
    .set_p(ECF1),
    .rst_p(ECD2),
    .tog_p(1'b0),
    .q(ECFS1),
    .q_n(ECFS2)
);

wire s_1102, r_1104, r_1103;
ac AC_1102 (
    .clk(clk),
    .en(sw_com_fun),
    .trans(EKBD3),
    .out(s_1102)
);
ac AC_1104 (
    .clk(clk),
    .en(PS73),
    .trans(HOME1),
    .out(r_1104)
);
ac AC_1103 (
    .clk(clk),
    .en(AOFL3),
    .trans(HOME1),
    .out(r_1103)
);
wire ECF1, ECF2;
ff COM_FUN_1100 (
    .clk(clk),
    .rst_l(r_1104 | r_1103 | EROF9),
    .set_l(s_1102),
    .set_p(ESD1),
    .rst_p(1'b0),
    .tog_p(1'b0),
    .q(ECF1),
    .q_n(ECF2)
);

wire s_1021;
ac AC_1021 (
    .clk(clk),
    .en(key_add | key_sub),
    .trans(EKBD3),
    .out(s_1021)
);
wire EAS1, EAS2;
ff ADD_SUB_1020 (
    .clk(clk),
    .rst_l(ERF3),
    .set_l(s_1021),
    .set_p(1'b0),
    .rst_p(1'b0),
    .tog_p(1'b0),
    .q(EAS1),
    .q_n(EAS2)
);

wire ECFD4 = !(ECD1 | ECF1);

wire EROF9 = key_of_lock | ESTA3;
wire ECFD4_p;
ac AC_ECFD4 (
    .clk(clk),
    .en(1'b1),
    .trans(ECFD4),
    .out(ECFD4_p)
);
wire ERF3 = EROF9 | ECFD4_p;

wire s_1221, s_1222, r_1223;
ac AC_1221 (
    .clk(clk),
    .en(MAIS3),
    .trans(ACOF1),
    .out(s_1221)
);
ac AC_1222 (
    .clk(clk),
    .en(CDZ4),
    .trans(RSLO5),
    .out(s_1222)
);
ac AC_1223 (
    .clk(clk),
    .en(XCE7),
    .trans(TC14),
    .out(r_1223)
);
wire AOFL1, AOFL2;
ff OVERFLOW_1220 (
    .clk(clk),
    .rst_l(r_1223 | EROF9),
    .set_l(s_1221 | s_1222),
    .set_p(1'b0),
    .rst_p(1'b0),
    .tog_p(1'b0),
    .q(AOFL1),
    .q_n(AOFL2)
);
wire MOFL3 = !AOFL2;
assign lamp_overflow = MOFL3;
wire AOFL3 = !(PC21 | PC41 | MA1L3 | AOFL2);
assign kbd_lock = !(!(AOFL3 | ECF1) | key_clr_ent);

// DECIMAL POINT SWITCH
wire DSZ6 = DC81 | DC41 | DC21 | DC11;
wire DSZ3 = !DSZ6;

wire DIC5 = M1L4 | HOME1 | DSZ3;

wire DEDS3 = !EMU1;
wire DMUS3 = !EMU2;
wire EMD4 = !(EMU1 | EDV1);
wire P4SD3 = !(EMD4 | PC42);

wire s_1133, s_1132;
ac AC_1133 (
    .clk(clk),
    .en(DSZ3),
    .trans(P4SD3),
    .out(s_1133)
);
ac AC_1132 (
    .clk(clk),
    .en(key_dp),
    .trans(EKBD3),
    .out(s_1132)
);

wire EDPS1, EDPS2;
ff DPS_1130 (
    .clk(clk),
    .rst_l(EROF9),
    .set_l(s_1133 | s_1132),
    .set_p(ECFS1),
    .rst_p(AIRX3 | ECF2),
    .tog_p(1'b0),
    .q(EDPS1),
    .q_n(EDPS2)
);

wire XD177, XD167, XD157, XD147;
wire XD137, XD127, XD117, XD107;

assign {XD147, XD157, XD167, XD177} = (sw_dp + 4'h3) & {DMUS3, DMUS3, DMUS3, DMUS3};
assign {XD107, XD117, XD127, XD137} = (-sw_dp) & {DEDS3, DEDS3, DEDS3, DEDS3};

wire s_1211;
ac AC_1211 (
    .clk(clk),
    .en(XD137 | XD177),
    .trans(EDPS1),
    .out(s_1211)
);
wire DC11, DC12;
ff DPC1_1210 (
    .clk(clk),
    .rst_l(EROF9),
    .set_l(s_1211),
    .set_p(1'b0),
    .rst_p(1'b0),
    .tog_p(DIC5),
    .q(DC11),
    .q_n(DC12)
);

wire s_1203, s_1201;
ac AC_1203 (
    .clk(clk),
    .en(EDV1),
    .trans(AIRX3),
    .out(s_1203)
);
ac AC_1201 (
    .clk(clk),
    .en(XD127 | XD167),
    .trans(EDPS1),
    .out(s_1201)
);
wire DC21, DC22;
ff DPC2_1200 (
    .clk(clk),
    .rst_l(EROF9),
    .set_l(s_1203 | s_1201),
    .set_p(1'b0),
    .rst_p(1'b0),
    .tog_p(DC12),
    .q(DC21),
    .q_n(DC22)
);

wire s_1193, s_1191;
ac AC_1193 (
    .clk(clk),
    .en(DMUS3),
    .trans(AIRX3),
    .out(s_1193)
);
ac AC_1191 (
    .clk(clk),
    .en(XD117 | XD157),
    .trans(EDPS1),
    .out(s_1191)
);
wire DC41, DC42;
ff DPC4_1190 (
    .clk(clk),
    .rst_l(EROF9),
    .set_l(s_1193 | s_1191),
    .set_p(1'b0),
    .rst_p(1'b0),
    .tog_p(DC22),
    .q(DC41),
    .q_n(DC42)
);

wire s_1181;
ac AC_1181 (
    .clk(clk),
    .en(XD107 | XD147),
    .trans(EDPS1),
    .out(s_1181)
);
wire DC81, DC82;
ff DPC8_1180 (
    .clk(clk),
    .rst_l(EROF9),
    .set_l(s_1181),
    .set_p(1'b0),
    .rst_p(1'b0),
    .tog_p(DC42),
    .q(DC81),
    .q_n(DC82)
);

//////////////////

wire RSCT3 = !(PS64 | TC14 | EAS2 | TFF1 | XRDL4);
wire r_1144;
ac AC_1144 (
    .clk(clk),
    .en(key_sub),
    .trans(EAS1),
    .out(r_1144)
);
wire ASC1, ASC2;
ff SIGN_CONT_1140 (
    .clk(clk),
    .rst_l(r_1144),
    .set_l(1'b0),
    .set_p(HOME1 | EAS1),
    .rst_p(1'b0),
    .tog_p(RSCT3),
    .q(ASC1),
    .q_n(ASC2)
);

wire DBDE3 = !(DSZ6 | EDPS2);
wire DBSL3 = !(EDPS2 | ECFS2);

wire ME1L3 = !(PS74 | DBSL3 | DBDE3 | ECD2);
wire MA1L3 = !(PC41 | PC21 | PC12 | ECF2 | DSZ3);
wire MMDL3 = !(DSZ3 | PS64 | EMD4);
wire M2LM3 = !(EMU2 | PC41 | PC22 | PC12);
wire MAID3 = !(DSZ3 | EDV2 | PC42 | PC21 | PC12);
wire MAIM3 = !(EMU2 | CDZ3 | PC42 | PC21 | PC12);
wire MAIS3 = !(EAS2 | PS74 | ASC2);
wire MIAD3 = !(ACOF1 | PC42 | PC21 | PC11 | EDV2);
wire MSID6 = EDV2 | PC41 | PC22 | PC12;
wire MSIS6 = PS74 | ASC1;

wire M1L4 = !(ME1L3 | MA1L3 | MMDL3);
wire M2L4 = !(M2LM3 | MAID3);
wire MAD4 = !(ACOF2 & (MAID3 | MAIM3 | MAIS3));
wire MIAD4 = !MIAD3;
wire MSDS3 = !(MSID6 & MSIS6);
wire MSU4 = !(MIAD3 | MSDS3);
wire ARDS3 = !MSU4;

// 2000 - MASTER OSCILLATOR
wire TOSC4 = clk_div_8;

wire HOME1, HOME2;
ff HOME_1450 (
    .clk(clk),
    .rst_l(ESTA3),
    .set_l(1'b0),
    .rst_p(CIA9),
    .set_p(TFL2),
    .tog_p(1'b0),
    .q(HOME1),
    .q_n(HOME2)
);

wire TOSC3 = !(TOSC4 | HOME1);
wire HOME3 = !HOME2;

// remove CLOCK divider to mimic timing of 3-counter version
/*
wire TCLK1, TCLK2;
ff CLOCK_1460 (
    .clk(clk),
    .set_l(1'b0),
    .rst_l(1'b0),
    .set_p(1'b0),
    .rst_p(1'b0),
    .tog_p(TOSC3),
    .q(TCLK1),
    .q_n(TCLK2)
);
*/

wire TCLK2 = TOSC3;

wire TFA1, TFA2;
ff A_1470 (
    .clk(clk),
    .set_l(HOME3),
    .rst_l(1'b0),
    .set_p(1'b0),
    .rst_p(1'b0),
    .tog_p(TCLK2),
    .q(TFA1),
    .q_n(TFA2)
);

wire TFB1, TFB2;
ff B_1480 (
    .clk(clk),
    .set_l(HOME3),
    .rst_l(1'b0),
    .set_p(1'b0),
    .rst_p(1'b0),
    .tog_p(TFA2),
    .q(TFB1),
    .q_n(TFB2)
);

wire TFC1, TFC2;
ff C_1490 (
    .clk(clk),
    .set_l(1'b0),
    .rst_l(1'b0),
    .set_p(1'b0),
    .rst_p(1'b0),
    .tog_p(TFB2),
    .q(TFC1),
    .q_n(TFC2)
);

wire TFD1, TFD2;
ff D_1500 (
    .clk(clk),
    .set_l(1'b0),
    .rst_l(1'b0),
    .set_p(1'b0),
    .rst_p(1'b0),
    .tog_p(TFC2),
    .q(TFD1),
    .q_n(TFD2)
);

wire TFE1, TFE2;
ff E_1510 (
    .clk(clk),
    .set_l(1'b0),
    .rst_l(1'b0),
    .set_p(1'b0),
    .rst_p(1'b0),
    .tog_p(TFD2),
    .q(TFE1),
    .q_n(TFE2)
);

wire TFF1, TFF2;
ff F_1520 (
    .clk(clk),
    .set_l(1'b0),
    .rst_l(1'b0),
    .rst_p(1'b0),
    .set_p(TFG3),
    .tog_p(TFE2),
    .q(TFF1),
    .q_n(TFF2)
);

wire TFG1, TFG2;
ff G_1530 (
    .clk(clk),
    .set_l(1'b0),
    .rst_l(1'b0),
    .set_p(1'b0),
    .rst_p(HOME2),
    .tog_p(TFF2),
    .q(TFG1),
    .q_n(TFG2)
);
wire TFG3 = !TFG2;

wire TFH1, TFH2;
ff H_1540 (
    .clk(clk),
    .set_l(1'b0),
    .rst_l(1'b0),
    .set_p(1'b0),
    .rst_p(1'b0),
    .tog_p(TFG3),
    .q(TFH1),
    .q_n(TFH2)
);

wire TFJ1, TFJ2;
ff J_1550 (
    .clk(clk),
    .set_l(1'b0),
    .rst_l(1'b0),
    .set_p(1'b0),
    .rst_p(1'b0),
    .tog_p(TFH2),
    .q(TFJ1),
    .q_n(TFJ2)
);

wire TFK1, TFK2;
ff K_1560 (
    .clk(clk),
    .set_l(1'b0),
    .rst_l(1'b0),
    .set_p(1'b0),
    .rst_p(1'b0),
    .tog_p(TFJ2),
    .q(TFK1),
    .q_n(TFK2)
);

wire TFL1, TFL2;
ff L_1570 (
    .clk(clk),
    .set_l(1'b0),
    .rst_l(1'b0),
    .set_p(1'b0),
    .rst_p(1'b0),
    .tog_p(TFK2),
    .q(TFL1),
    .q_n(TFL2)
);

wire s_1581;
ac AC_1581 (
    .clk(clk),
    .en(TFM2),
    .trans(TFL2),
    .out(s_1581)
);
wire TFM1, TFM2;
ff M_1580 (
    .clk(clk),
    .set_l(s_1581),
    .rst_l(1'b0),
    .set_p(1'b0),
    .rst_p(TFL2),
    .tog_p(1'b0),
    .q(TFM1),
    .q_n(TFM2)
);

wire TFN1, TFN2;
ff N_1590 (
    .clk(clk),
    .set_l(1'b0),
    .rst_l(1'b0),
    .set_p(1'b0),
    .rst_p(1'b0),
    .tog_p(TFM2),
    .q(TFN1),
    .q_n(TFN2)
);

wire TFP1, TFP2;
ff P_1590 (
    .clk(clk),
    .set_l(s_1581),
    .rst_l(1'b0),
    .set_p(TFL2),
    .rst_p(TFN2),
    .tog_p(1'b0),
    .q(TFP1),
    .q_n(TFP2)
);

wire TB154 = TFA2 | TFB2 | TFC2 | TFD2;

wire TR03 = !(TFE2 | TFG2);
wire TR04 = !TR03;

wire TR13 = !(TFE1 | TFF1 | TFG1);
wire TR14 = !TR13;

wire TC03 = !(TFH1 | TFJ1 | TFK1 | TFL1);

wire TC13 = !(TFH2 | TFJ1 | TFK1 | TFL1);
wire TC14 = !TC13;

wire TC23 = !(TFH1 | TFJ2 | TFK1 | TFL1);
wire TC24 = !TC23;

wire TC153 = !(TFH2 | TFJ2 | TFK2 | TFL2);
wire TC154 = !TC153;
wire TC013 = !(TFJ1 | TFK1 | TFL1);
wire TCX5 =  TC013 | !(EDV1 | TC154);

// A COUNTER
wire s_1251, s_1252, r_1254, r_1253;
ac AC_1251 (
    .clk(clk),
    .en(CA41),
    .trans(CIA9),
    .out(s_1251)
);
ac AC_1252 (
    .clk(clk),
    .en(CD51),
    .trans(SDA9),
    .out(s_1252)
);
ac AC_1254 (
    .clk(clk),
    .en(CD52),
    .trans(SDA9),
    .out(r_1254)
);
ac AC_1253 (
    .clk(clk),
    .en(CA42),
    .trans(CIA9),
    .out(r_1253)
);
wire CA51, CA52;
ff A5_1250 (
    .clk(clk),
    .set_l(s_1251 | s_1252),
    .rst_l(r_1254 | r_1253),
    .set_p(1'b0),
    .rst_p(CRA9),
    .tog_p(1'b0),
    .q(CA51),
    .q_n(CA52)
);

wire s_1261, s_1262, r_1264, r_1263;
ac AC_1261 (
    .clk(clk),
    .en(CA31),
    .trans(CIA9),
    .out(s_1261)
);
ac AC_1262 (
    .clk(clk),
    .en(CD41),
    .trans(SDA9),
    .out(s_1262)
);
ac AC_1264 (
    .clk(clk),
    .en(CD42),
    .trans(SDA9),
    .out(r_1264)
);
ac AC_1263 (
    .clk(clk),
    .en(CA32),
    .trans(CIA9),
    .out(r_1263)
);
wire CA41, CA42;
ff A4_1260 (
    .clk(clk),
    .set_l(s_1261 | s_1262),
    .rst_l(r_1264 | r_1263),
    .set_p(1'b0),
    .rst_p(CRA9),
    .tog_p(1'b0),
    .q(CA41),
    .q_n(CA42)
);

wire s_1271, s_1272, r_1274, r_1273;
ac AC_1271 (
    .clk(clk),
    .en(CA21),
    .trans(CIA9),
    .out(s_1271)
);
ac AC_1272 (
    .clk(clk),
    .en(CD31),
    .trans(SDA9),
    .out(s_1272)
);
ac AC_1274 (
    .clk(clk),
    .en(CD32),
    .trans(SDA9),
    .out(r_1274)
);
ac AC_1273 (
    .clk(clk),
    .en(CA22),
    .trans(CIA9),
    .out(r_1273)
);
wire CA31, CA32;
ff A3_1270 (
    .clk(clk),
    .set_l(s_1271 | s_1272),
    .rst_l(r_1274 | r_1273),
    .set_p(1'b0),
    .rst_p(CRA9),
    .tog_p(1'b0),
    .q(CA31),
    .q_n(CA32)
);

wire s_1281, s_1282, r_1284, r_1283;
ac AC_1281 (
    .clk(clk),
    .en(CA11),
    .trans(CIA9),
    .out(s_1281)
);
ac AC_1282 (
    .clk(clk),
    .en(CD21),
    .trans(SDA9),
    .out(s_1282)
);
ac AC_1284 (
    .clk(clk),
    .en(CD22),
    .trans(SDA9),
    .out(r_1284)
);
ac AC_1283 (
    .clk(clk),
    .en(CA12),
    .trans(CIA9),
    .out(r_1283)
);
wire CA21, CA22;
ff A2_1280 (
    .clk(clk),
    .set_l(s_1281 | s_1282),
    .rst_l(r_1284 | r_1283),
    .set_p(1'b0),
    .rst_p(CRA9),
    .tog_p(1'b0),
    .q(CA21),
    .q_n(CA22)
);

wire s_1291, s_1293, s_1292, r_1295, r_1296, r_1294, r_1297;
ac AC_1291 (
    .clk(clk),
    .en(ASA13),
    .trans(CRA9),
    .out(s_1291)
);
ac AC_1293 (
    .clk(clk),
    .en(CA52),
    .trans(CIA9),
    .out(s_1293)
);
ac AC_1292 (
    .clk(clk),
    .en(CD11),
    .trans(SDA9),
    .out(s_1292)
);
ac AC_1295 (
    .clk(clk),
    .en(CD12),
    .trans(SDA9),
    .out(r_1295)
);
ac AC_1296 (
    .clk(clk),
    .en(CA51),
    .trans(CIA9),
    .out(r_1296)
);
ac AC_1294 (
    .clk(clk),
    .en(ARA13),
    .trans(CRA9),
    .out(r_1294)
);
ac AC_1297 (
    .clk(clk),
    .en(TC13),
    .trans(CA21),
    .out(r_1297)
);
wire CA11, CA12;
ff A1_1290 (
    .clk(clk),
    .set_l(s_1291 | s_1293 | s_1292),
    .rst_l(r_1295 | r_1296 | r_1294 | r_1297),
    .set_p(1'b0),
    .rst_p(1'b0),
    .tog_p(1'b0),
    .q(CA11),
    .q_n(CA12)
);

wire CA94 = CA52 | CA41;

// B COUNTER
wire s_1351, s_1352, r_1354, r_1353;
ac AC_1351 (
    .clk(clk),
    .en(CA51),
    .trans(SAB9),
    .out(s_1351)
);
ac AC_1352 (
    .clk(clk),
    .en(CD51),
    .trans(SDB9),
    .out(s_1352)
);
ac AC_1354 (
    .clk(clk),
    .en(CD52),
    .trans(SDB9),
    .out(r_1354)
);
ac AC_1353 (
    .clk(clk),
    .en(CA52),
    .trans(SAB9),
    .out(r_1353)
);
wire CB51, CB52;
ff B5_1350 (
    .clk(clk),
    .set_l(s_1351 | s_1352),
    .rst_l(r_1354 | r_1353),
    .set_p(1'b0),
    .rst_p(1'b0),
    .tog_p(1'b0),
    .q(CB51),
    .q_n(CB52)
);

wire s_1361, s_1362, r_1364, r_1363;
ac AC_1361 (
    .clk(clk),
    .en(CA41),
    .trans(SAB9),
    .out(s_1361)
);
ac AC_1362 (
    .clk(clk),
    .en(CD41),
    .trans(SDB9),
    .out(s_1362)
);
ac AC_1364 (
    .clk(clk),
    .en(CD42),
    .trans(SDB9),
    .out(r_1364)
);
ac AC_1363 (
    .clk(clk),
    .en(CA42),
    .trans(SAB9),
    .out(r_1363)
);
wire CB41, CB42;
ff B4_1360 (
    .clk(clk),
    .set_l(s_1361 | s_1362),
    .rst_l(r_1364 | r_1363),
    .set_p(1'b0),
    .rst_p(1'b0),
    .tog_p(1'b0),
    .q(CB41),
    .q_n(CB42)
);

wire s_1371, s_1372, r_1374, r_1373;
ac AC_1371 (
    .clk(clk),
    .en(CA31),
    .trans(SAB9),
    .out(s_1371)
);
ac AC_1372 (
    .clk(clk),
    .en(CD31),
    .trans(SDB9),
    .out(s_1372)
);
ac AC_1374 (
    .clk(clk),
    .en(CD32),
    .trans(SDB9),
    .out(r_1374)
);
ac AC_1373 (
    .clk(clk),
    .en(CA32),
    .trans(SAB9),
    .out(r_1373)
);
wire CB31, CB32;
ff B3_1370 (
    .clk(clk),
    .set_l(s_1371 | s_1372),
    .rst_l(r_1374 | r_1373),
    .set_p(1'b0),
    .rst_p(1'b0),
    .tog_p(1'b0),
    .q(CB31),
    .q_n(CB32)
);

wire o_194 = CB22 | TFD1;

wire s_1381, s_1382, r_1384, r_1383, r_1385;
ac AC_1381 (
    .clk(clk),
    .en(CA21),
    .trans(SAB9),
    .out(s_1381)
);
ac AC_1382 (
    .clk(clk),
    .en(CD21),
    .trans(SDB9),
    .out(s_1382)
);
ac AC_1384 (
    .clk(clk),
    .en(CD22),
    .trans(SDB9),
    .out(r_1384)
);
ac AC_1383 (
    .clk(clk),
    .en(CA22),
    .trans(SAB9),
    .out(r_1383)
);
ac AC_1385 (
    .clk(clk),
    .en(TC13),
    .trans(o_194),
    .out(r_1385)
);
wire CB21, CB22;
ff B2_1380 (
    .clk(clk),
    .set_l(s_1381 | s_1382),
    .rst_l(r_1384 | r_1383 | r_1385),
    .set_p(1'b0),
    .rst_p(1'b0),
    .tog_p(1'b0),
    .q(CB21),
    .q_n(CB22)
);

wire s_1391, s_1392, r_1394, r_1393, r_1395;
ac AC_1391 (
    .clk(clk),
    .en(CA11),
    .trans(SAB9),
    .out(s_1391)
);
ac AC_1392 (
    .clk(clk),
    .en(CD11),
    .trans(SDB9),
    .out(s_1392)
);
ac AC_1394 (
    .clk(clk),
    .en(CD12),
    .trans(SDB9),
    .out(r_1394)
);
ac AC_1393 (
    .clk(clk),
    .en(CA12),
    .trans(SAB9),
    .out(r_1393)
);
ac AC_1395 (
    .clk(clk),
    .en(CD12),
    .trans(SDB9),
    .out(r_1395)
);
wire CB11, CB12;
ff B1_1390 (
    .clk(clk),
    .set_l(s_1391 | s_1392),
    .rst_l(r_1394 | r_1393 | r_1395),
    .set_p(1'b0),
    .rst_p(1'b0),
    .tog_p(1'b0),
    .q(CB11),
    .q_n(CB12)
);

// C COUNTER
wire s_1403, s_1402, s_1401, r_1404, r_1405, r_1406;
ac AC_1403 (
    .clk(clk),
    .en(CC12),
    .trans(C1C9),
    .out(s_1403)
);
ac AC_1402 (
    .clk(clk),
    .en(CA51),
    .trans(SAC9),
    .out(s_1402)
);
ac AC_1401 (
    .clk(clk),
    .en(CB51),
    .trans(SBC9),
    .out(s_1401)
);
ac AC_1404 (
    .clk(clk),
    .en(CB52),
    .trans(SBC9),
    .out(r_1404)
);
ac AC_1405 (
    .clk(clk),
    .en(CA52),
    .trans(SAC9),
    .out(r_1405)
);
ac AC_1406 (
    .clk(clk),
    .en(CC11),
    .trans(C1C9),
    .out(r_1406)
);
wire CC51, CC52;
ff C5_1400 (
    .clk(clk),
    .set_l(s_1403 | s_1402 | s_1401),
    .rst_l(r_1404 | r_1405 | r_1406),
    .set_p(1'b0),
    .rst_p(1'b0),
    .tog_p(1'b0),
    .q(CC51),
    .q_n(CC52)
);

wire s_1413, s_1412, s_1411, r_1414, r_1415, r_1416;
ac AC_1413 (
    .clk(clk),
    .en(CC51),
    .trans(C1C9),
    .out(s_1413)
);
ac AC_1412 (
    .clk(clk),
    .en(CA41),
    .trans(SAC9),
    .out(s_1412)
);
ac AC_1411 (
    .clk(clk),
    .en(CB41),
    .trans(SBC9),
    .out(s_1411)
);
ac AC_1414 (
    .clk(clk),
    .en(CB42),
    .trans(SBC9),
    .out(r_1414)
);
ac AC_1415 (
    .clk(clk),
    .en(CA42),
    .trans(SAC9),
    .out(r_1415)
);
ac AC_1416 (
    .clk(clk),
    .en(CC52),
    .trans(C1C9),
    .out(r_1416)
);
wire CC41, CC42;
ff C4_1410 (
    .clk(clk),
    .set_l(s_1413 | s_1412 | s_1411),
    .rst_l(r_1414 | r_1415 | r_1416),
    .set_p(1'b0),
    .rst_p(1'b0),
    .tog_p(1'b0),
    .q(CC41),
    .q_n(CC42)
);

wire s_1423, s_1422, s_1421, r_1424, r_1425, r_1426;
ac AC_1423 (
    .clk(clk),
    .en(CC41),
    .trans(C1C9),
    .out(s_1423)
);
ac AC_1422 (
    .clk(clk),
    .en(CA31),
    .trans(SAC9),
    .out(s_1422)
);
ac AC_1421 (
    .clk(clk),
    .en(CB31),
    .trans(SBC9),
    .out(s_1421)
);
ac AC_1424 (
    .clk(clk),
    .en(CB32),
    .trans(SBC9),
    .out(r_1424)
);
ac AC_1425 (
    .clk(clk),
    .en(CA32),
    .trans(SAC9),
    .out(r_1425)
);
ac AC_1426 (
    .clk(clk),
    .en(CC42),
    .trans(C1C9),
    .out(r_1426)
);
wire CC31, CC32;
ff C3_1420 (
    .clk(clk),
    .set_l(s_1423 | s_1422 | s_1421),
    .rst_l(r_1424 | r_1425 | r_1426),
    .set_p(1'b0),
    .rst_p(1'b0),
    .tog_p(1'b0),
    .q(CC31),
    .q_n(CC32)
);

wire s_1433, s_1432, s_1431, r_1434, r_1435, r_1436;
ac AC_1433 (
    .clk(clk),
    .en(CC31),
    .trans(C1C9),
    .out(s_1433)
);
ac AC_1432 (
    .clk(clk),
    .en(CA21),
    .trans(SAC9),
    .out(s_1432)
);
ac AC_1431 (
    .clk(clk),
    .en(CB21),
    .trans(SBC9),
    .out(s_1431)
);
ac AC_1434 (
    .clk(clk),
    .en(CB22),
    .trans(SBC9),
    .out(r_1434)
);
ac AC_1435 (
    .clk(clk),
    .en(CA22),
    .trans(SAC9),
    .out(r_1435)
);
ac AC_1436 (
    .clk(clk),
    .en(CC32),
    .trans(C1C9),
    .out(r_1436)
);
wire CC21, CC22;
ff C2_1430 (
    .clk(clk),
    .set_l(s_1433 | s_1432 | s_1431),
    .rst_l(r_1434 | r_1435 | r_1436),
    .set_p(1'b0),
    .rst_p(1'b0),
    .tog_p(1'b0),
    .q(CC21),
    .q_n(CC22)
);

wire s_1443, s_1442, s_1441, r_1444, r_1445, r_1446;
ac AC_1443 (
    .clk(clk),
    .en(CC21),
    .trans(C1C9),
    .out(s_1443)
);
ac AC_1442 (
    .clk(clk),
    .en(CA11),
    .trans(SAC9),
    .out(s_1442)
);
ac AC_1441 (
    .clk(clk),
    .en(CB11),
    .trans(SBC9),
    .out(s_1441)
);
ac AC_1444 (
    .clk(clk),
    .en(CB12),
    .trans(SBC9),
    .out(r_1444)
);
ac AC_1445 (
    .clk(clk),
    .en(CA12),
    .trans(SAC9),
    .out(r_1445)
);
ac AC_1446 (
    .clk(clk),
    .en(CC22),
    .trans(C1C9),
    .out(r_1446)
);
wire CC11, CC12;
ff C1_1440 (
    .clk(clk),
    .set_l(s_1443 | s_1442 | s_1441),
    .rst_l(r_1444 | r_1445 | r_1446),
    .set_p(1'b0),
    .rst_p(1'b0),
    .tog_p(1'b0),
    .q(CC11),
    .q_n(CC12)
);

wire CCZ3 = !(CC51 | CC11);
wire TB013 = !(TFB1 | TFC1 | TFD1);
wire TBX3 = !(TFB2 | TFC2 | TFD2);
wire C1C4 = !(CCZ3 | TB013 | TBX3 | TCLK2);
wire C1C9 = !C1C4;

// DELAY LINE
// simulate the delay line as a big shift register
reg [DELAY_LINE_LENGTH-1:0] _dl;

reg [1:0] dl_in_prev;
wire dl_in = C1C4 | ESTA3;

// delay line only responds to edge inputs
always @(negedge clk_div_4) begin
    dl_in_prev <= {dl_in_prev[0], dl_in};
    if (!clk_div_8) begin
        _dl <= {_dl[DELAY_LINE_LENGTH-2:0], 1'b0};
    end
    if (dl_in_prev == 2'b10) begin
        _dl[0] <= 1'b1;
    end
end

// turn shift register output into a pulse
wire XRDL4 = !_dl[DELAY_LINE_LENGTH-1] | clk_div_8;

// D COUNTER
wire s_1304, s_1303, s_1301, s_1302, r_1306, r_1305, r_1307, r_1308;
ac AC_1304 (
    .clk(clk),
    .en(XB597),
    .trans(ME1L3),
    .out(s_1304)
);
ac AC_1303 (
    .clk(clk),
    .en(ACRY1),
    .trans(CRD9),
    .out(s_1303)
);
ac AC_1301 (
    .clk(clk),
    .en(CD12),
    .trans(CID9),
    .out(s_1301)
);
ac AC_1302 (
    .clk(clk),
    .en(CA51),
    .trans(SAD9),
    .out(s_1302)
);
ac AC_1306 (
    .clk(clk),
    .en(CA52),
    .trans(SAD9),
    .out(r_1306)
);
ac AC_1305 (
    .clk(clk),
    .en(CD11),
    .trans(CID9),
    .out(r_1305)
);
ac AC_1307 (
    .clk(clk),
    .en(ACRY2),
    .trans(CRD9),
    .out(r_1307)
);
ac AC_1308 (
    .clk(clk),
    .en(CED55),
    .trans(HOME1),
    .out(r_1308)
);
wire CD51, CD52;
ff D5_1300 (
    .clk(clk),
    .set_l(s_1304 | s_1303 | s_1301 | s_1302),
    .rst_l(r_1306 | r_1305 | r_1307 | r_1308),
    .set_p(1'b0),
    .rst_p(1'b0),
    .tog_p(1'b0),
    .q(CD51),
    .q_n(CD52)
);

wire s_1313, s_1311, s_1312, r_1315, r_1314;
ac AC_1313 (
    .clk(clk),
    .en(XB487),
    .trans(ME1L3),
    .out(s_1313)
);
ac AC_1311 (
    .clk(clk),
    .en(CD51),
    .trans(CID9),
    .out(s_1311)
);
ac AC_1312 (
    .clk(clk),
    .en(CA41),
    .trans(SAD9),
    .out(s_1312)
);
ac AC_1315 (
    .clk(clk),
    .en(CA42),
    .trans(SAD9),
    .out(r_1315)
);
ac AC_1314 (
    .clk(clk),
    .en(CD52),
    .trans(CID9),
    .out(r_1314)
);
wire CD41, CD42;
ff D4_1310 (
    .clk(clk),
    .set_l(s_1313 | s_1311 | s_1312),
    .rst_l(r_1315 | r_1314),
    .set_p(1'b0),
    .rst_p(CRD9),
    .tog_p(1'b0),
    .q(CD41),
    .q_n(CD42)
);

wire s_1323, s_1321, s_1322, r_1325, r_1324;
ac AC_1323 (
    .clk(clk),
    .en(XB377),
    .trans(ME1L3),
    .out(s_1323)
);
ac AC_1321 (
    .clk(clk),
    .en(CD41),
    .trans(CID9),
    .out(s_1321)
);
ac AC_1322 (
    .clk(clk),
    .en(CA31),
    .trans(SAD9),
    .out(s_1322)
);
ac AC_1325 (
    .clk(clk),
    .en(CA32),
    .trans(SAD9),
    .out(r_1325)
);
ac AC_1324 (
    .clk(clk),
    .en(CD42),
    .trans(CID9),
    .out(r_1324)
);
wire CD31, CD32;
ff D3_1320 (
    .clk(clk),
    .set_l(s_1323 | s_1321 | s_1322),
    .rst_l(r_1325 | r_1324),
    .set_p(1'b0),
    .rst_p(CRD9),
    .tog_p(1'b0),
    .q(CD31),
    .q_n(CD32)
);

wire s_1333, s_1331, s_1332, r_1335, r_1334;
ac AC_1333 (
    .clk(clk),
    .en(XB267),
    .trans(ME1L3),
    .out(s_1333)
);
ac AC_1331 (
    .clk(clk),
    .en(CD31),
    .trans(CID9),
    .out(s_1331)
);
ac AC_1332 (
    .clk(clk),
    .en(CA21),
    .trans(SAD9),
    .out(s_1332)
);
ac AC_1335 (
    .clk(clk),
    .en(CA22),
    .trans(SAD9),
    .out(r_1335)
);
ac AC_1334 (
    .clk(clk),
    .en(CD32),
    .trans(CID9),
    .out(r_1334)
);
wire CD21, CD22;
ff D2_1330 (
    .clk(clk),
    .set_l(s_1333 | s_1331 | s_1332),
    .rst_l(r_1335 | r_1334),
    .set_p(1'b0),
    .rst_p(CRD9),
    .tog_p(1'b0),
    .q(CD21),
    .q_n(CD22)
);

wire s_1343, s_1341, s_1342, r_1345, r_1344;
ac AC_1343 (
    .clk(clk),
    .en(XB157),
    .trans(ME1L3),
    .out(s_1343)
);
ac AC_1341 (
    .clk(clk),
    .en(CD21),
    .trans(CID9),
    .out(s_1341)
);
ac AC_1342 (
    .clk(clk),
    .en(CA11),
    .trans(SAD9),
    .out(s_1342)
);
ac AC_1345 (
    .clk(clk),
    .en(CA12),
    .trans(SAD9),
    .out(r_1345)
);
ac AC_1344 (
    .clk(clk),
    .en(CD22),
    .trans(CID9),
    .out(r_1344)
);
wire CD11, CD12;
ff D1_1340 (
    .clk(clk),
    .set_l(s_1343 | s_1341 | s_1342),
    .rst_l(r_1345 | r_1344),
    .set_p(1'b0),
    .rst_p(CRD9),
    .tog_p(1'b0),
    .q(CD11),
    .q_n(CD12)
);

wire CDZ3 = !(CD51 | CD11);
wire CDZ4 = !CDZ3;

// PHASE COUNTER
wire s_1151, r_1154;
ac AC_1151 (
    .clk(clk),
    .en(EMD4),
    .trans(PC21),
    .out(s_1151)
);
ac AC_1154 (
    .clk(clk),
    .en(MMDL3),
    .trans(HOME1),
    .out(r_1154)
);
wire PC41, PC42;
ff PC4_1150 (
    .clk(clk),
    .set_l(s_1151),
    .rst_l(r_1154 | ECFD4),
    .set_p(1'b0),
    .rst_p(1'b0),
    .tog_p(PC22),
    .q(PC41),
    .q_n(PC42)
);

wire PC21, PC22;
ff PC2_1160 (
    .clk(clk),
    .set_l(1'b0),
    .rst_l(ECFD4),
    .set_p(1'b0),
    .rst_p(1'b0),
    .tog_p(PC12),
    .q(PC21),
    .q_n(PC22)
);

wire P1C5 = MAIM3 | MIAD3 | MA1L3 | HOME1;

wire PC11, PC12;
ff PC1_1170 (
    .clk(clk),
    .set_l(1'b0),
    .rst_l(ECFD4),
    .set_p(1'b0),
    .rst_p(1'b0),
    .tog_p(P1C5),
    .q(PC11),
    .q_n(PC12)
);

wire PSZ3 = !(ACOF1 | PC41 | PC21 | PC11);
wire PS64 = PC42 | PC22 | PC11;
wire PS73 = !(PC42 | PC22 | PC12);
wire PS74 = !PS73;

// REGISTER AND SHIFT CONTROL
wire RIAC6 = ASC1 | ACOF2 | TC14 | TR04;
wire RIAS6 = ECS2 | PS64 | TC14 | TR04;
wire RIMC6 = EMU2 | ACOF2 | TC24 | TR14;
wire RIAM6 = EMU2 | ACOF2 | ACRY2 | TR14;
wire RIAD6 = MIAD4 | TC24 | TR14;
wire ASA13 = !(RIAC6 & RIAS6 & RIMC6 & RIAM6 & RIAD6);
wire ARA13 = !ASA13;
wire AERM3 = !(EMU2 | ARA13);
wire AERS3 = !(MSU4 | CA94);
wire AESA3 = !(AERS3 | CA94);
wire ARCA3 = !(MAD4 | TCX5 | TR04 | TB154 | AERC4);
// AERC4 has a nasty feedback path, so clock it
//wire AERC4 = !(ACRY1 | ARCA3);
reg AERC4;
always @(posedge clk) begin
    AERC4 <= !(ACRY1 | ARCA3);
end
wire MAIR3 = !XRDL4;
wire CIA9 = ARCA3 | MAIR3;

wire s_1232, r_1234, r_1235, r_1236;
ac AC_1232 (
    .clk(clk),
    .en(AESA3),
    .trans(CIA9),
    .out(s_1232)
);
ac AC_1234 (
    .clk(clk),
    .en(AERS3),
    .trans(CIA9),
    .out(r_1234)
);
ac AC_1235 (
    .clk(clk),
    .en(CA94),
    .trans(ARCA3),
    .out(r_1235)
);
ac AC_1236 (
    .clk(clk),
    .en(AERM3),
    .trans(CRA9),
    .out(r_1236)
);
wire ACRY1, ACRY2;
ff CARRY_1230 (
    .clk(clk),
    .set_l(s_1232),
    .rst_l(r_1234 | r_1235 | r_1236 | EROF9),
    .set_p(AIDS3),
    .rst_p(HOME1),
    .tog_p(1'b0),
    .q(ACRY1),
    .q_n(ACRY2)
);
wire s_1241;
wire o_160 = ACOF1 | HOME1;
ac AC_1241 (
    .clk(clk),
    .en(ACRY1),
    .trans(o_160),
    .out(s_1241)
);
wire ACOF1, ACOF2;
ff CARRY_OF_1240 (
    .clk(clk),
    .set_l(s_1241),
    .rst_l(EROF9), 
    .set_p(1'b0),
    .rst_p(HOME1),
    .tog_p(1'b0),
    .q(ACOF1),
    .q_n(ACOF2)
);

wire o_050 = TR14 | PC41 | PC22 | PC11;
wire o_083 = ESTO2 | PS74 | TR04;
wire o_084 = ESD2 | PS64 | TFG1;
wire o_085 = EMD4 | PS74 | TFG1;
wire RESD3 = !(o_050 & o_083 & o_084 & o_085);
wire SEAC4 = (!RESD3) | TC03;
wire SEBC4 = !SEAC4;
wire SAC9 = !(SEAC4 | TC153 | TB154);
wire SBC9 = !(SEBC4 | TB154);

wire o_089 = ERC2 | PS64 | TR03;
wire o_090 = ERP2 | PS64;
wire RURR3 = !(o_089 & o_090);

wire o_097 = M1L4 | TCX5 | TR14;
wire o_098 = M2L4 | TCX5 | TFE2 | TFF1;
wire o_099 = ECD2 | ECFS2 | PS64 | TFG1;
wire RSUL3 = !(o_097 & o_098 & o_099);

wire o_088 = ERC2 | PS64 | TFG1;
wire o_091 = ERP2 | PS64 | TFG1 | TR13;
wire RRRU3 = !(o_088 & o_091);

wire RCM3 = !(ASC1 | ACOF2 | TCX5 | TR14);
wire AIRS3 = !(MSU4 | TCX5 | TR04);
wire AIRX3 = !(PC41 | PC22 | PC11 | TC14 | TR14);
wire AIRA3 = !(MAD4 | TCX5 | TR04);
wire RERD3 = !(ECD2 | ECFS2 | PS64 | TR04);
wire R10F3 = !(MMDL3 | M1L4 | TC154 | HOME1);
wire R20F3 = !(M2L4 | EDPS2 | TC154 | HOME1);

wire SDA9 = !(MSU4 | TCX5 | TR04 | TB154);

wire SEAD4 = !(RURR3 | YCPR3 | RSUL3);
wire SAD9 = !(TB154 | SEAD4);

wire SEDB4 = (!(RSUL3 | SEBC4 | RRRU3 | RCM3)) | TC03;
wire SEAB4 = !SEDB4;
wire SAB9 = !(TB154 | SEAB4);
wire SDB9 = !(SEDB4 | TB154);

wire REID4 = !(RCM3 | AIRS3);
wire CRA9 = !(AIRS3 | AIRX3 | AIRA3 | TB154);
wire CED55 = RSLO5 | ARDS3;
wire RSLO5 = R10F3 | R20F3;
wire CERD4 = !(ARDS3 | RCM3 | RERD3 | RSLO5);
wire CRD9 = !(TB154 | CERD4);

wire AIDM3 = !(EMU2 | MAD4 | CDZ3 | TC154 | TR14);
wire AIDS3 = !(XRDL4 | REID4);

// CID9 can emit a glitch when the timing chain ripple carries, so
// add a glitch filter for CID9
wire CID9_pre = AIDM3 | AIDS3;
reg CID9;
reg [1:0] CID9_filt;
always @(posedge clk) begin
    CID9_filt <= {CID9_filt[0], CID9_pre};
    if (CID9_filt == 2'b11)
        CID9 <= 1'b1;
    if (CID9_filt == 2'b0)
        CID9 <= 1'b0;
end

// DISPLAY
// we're really cheating here, as the bare minimum of the display logic
// is implemented to get the calculator to calculate
//
// maybe this will be expanded someday to drive some DACs for an oscilloscope?
// could be fun!
wire o_221 = TFE2 | TFM1;
wire o_222 = TFE1 | TFM2;
wire o_223 = TFF2 | TFN1;
wire o_224 = TFF1 | TFN2;
wire YCPR4 = !(o_221 & o_222 & PSZ3 & TFG2 & o_223 & o_224);
wire YCPR3 = !YCPR4;

endmodule
