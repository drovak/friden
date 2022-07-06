// Friden EC-130 simulator
// Kyle Owen - 22 June 2022

// need ncurses for interactive terminal simulator
#include <stdio.h>
#include <stdlib.h>
#include <memory>
#include <verilated.h>
#include "verilated_vcd_c.h"
#include "Vtop.h"
#include <ncurses.h>

#define KEY_DELAY 50000UL

// prints a register in a human-readable way
void print_reg(uint8_t * reg, int dp) {
    for (int i = 15; i >= 2; i--) {
        if (i < 15)
            printw("%x", reg[i]);
        if (dp + 2 == i)
            printw(".");
    }
    if (reg[1])
        printw("-");
    else
        printw(" ");
    printw("\n");
}

int main(int argc, char** argv, char** env) {
    WINDOW *win;
    win = initscr();
    nodelay(win, TRUE);
    keypad(win, TRUE);
    noecho();
    curs_set(0);

    if (false && argc && argv && env) {}

    Verilated::debug(0);
    Verilated::randReset(2);
    Verilated::traceEverOn(true);
    Verilated::commandArgs(argc, argv);

    Vtop *top = new Vtop;

#if VM_TRACE
	VerilatedVcdC* tfp = nullptr;
	const char* flag = Verilated::commandArgsPlusMatch("trace");
    if (flag && 0 == strcmp(flag, "+trace")) {
		tfp = new VerilatedVcdC;
		top->trace(tfp, 99);
		tfp->open("logs/trace.vcd");
	}
	VL_PRINTF("starting simulation...\n");
#endif

    top->key_of_lock = 0;
    top->key_chg_sign = 0;
    top->key_repeat = 0;
    top->key_div = 0;
    top->key_clr_ent = 0;
    top->key_enter = 0;
    top->key_mult = 0;
    top->key_clr_all = 0;
    top->key_sub = 0;
    top->key_add = 0;
    top->key_store = 0;
    top->key_recall = 0;
    top->key_dp = 0;
    top->key_0 = 0;
    top->key_1 = 0;
    top->key_2 = 0;
    top->key_3 = 0;
    top->key_4 = 0;
    top->key_5 = 0;
    top->key_6 = 0;
    top->key_7 = 0;
    top->key_8 = 0;
    top->key_9 = 0;
    top->sw_dp = 5;

    top->eval();

    uint64_t t_event;
    int valid_press = 0;
    int key_processed = 1;
    int c;
    int quit = 0;

    for (uint64_t i = 0; ; i++) {
        if (quit)
            break;

        c = getch();
        if (c > 0) {
            switch (c) {
                case '0':
                    mvprintw(8,0,"key press: 0\n");
                    valid_press = 1;
                    top->key_0 = 1;
                    break;
                case '1':
                    mvprintw(8,0,"key press: 1\n");
                    valid_press = 1;
                    top->key_1 = 1;
                    break;
                case '2':
                    mvprintw(8,0,"key press: 2\n");
                    valid_press = 1;
                    top->key_2 = 1;
                    break;
                case '3':
                    mvprintw(8,0,"key press: 3\n");
                    valid_press = 1;
                    top->key_3 = 1;
                    break;
                case '4':
                    mvprintw(8,0,"key press: 4\n");
                    valid_press = 1;
                    top->key_4 = 1;
                    break;
                case '5':
                    mvprintw(8,0,"key press: 5\n");
                    valid_press = 1;
                    top->key_5 = 1;
                    break;
                case '6':
                    mvprintw(8,0,"key press: 6\n");
                    valid_press = 1;
                    top->key_6 = 1;
                    break;
                case '7':
                    mvprintw(8,0,"key press: 7\n");
                    valid_press = 1;
                    top->key_7 = 1;
                    break;
                case '8':
                    mvprintw(8,0,"key press: 8\n");
                    valid_press = 1;
                    top->key_8 = 1;
                    break;
                case '9':
                    mvprintw(8,0,"key press: 9\n");
                    valid_press = 1;
                    top->key_9 = 1;
                    break;
                case KEY_ENTER:
                case '\n':
                case '\r':
                    mvprintw(8,0,"key press: ENTER\n");
                    valid_press = 1;
                    top->key_enter = 1;
                    break;
                case KEY_BACKSPACE:
                    mvprintw(8,0,"key press: CLEAR ENTRY\n");
                    valid_press = 1;
                    top->key_clr_ent = 1;
                    break;
                case 'c':
                    mvprintw(8,0,"key press: CLEAR ALL\n");
                    valid_press = 1;
                    top->key_clr_all = 1;
                    break;
                case '.':
                    mvprintw(8,0,"key press: DECIMAL POINT\n");
                    valid_press = 1;
                    top->key_dp = 1;
                    break;
                case 's':
                    mvprintw(8,0,"key press: CHANGE SIGN\n");
                    valid_press = 1;
                    top->key_chg_sign = 1;
                    break;
                case 'r':
                    mvprintw(8,0,"key press: REPEAT\n");
                    valid_press = 1;
                    top->key_repeat = 1;
                    break;
                case 'o':
                    mvprintw(8,0,"key press: OVERFLOW LOCK\n");
                    valid_press = 1;
                    top->key_of_lock = 1;
                    break;
                case 't':
                    mvprintw(8,0,"key press: STORE\n");
                    valid_press = 1;
                    top->key_store = 1;
                    break;
                case 'e':
                    mvprintw(8,0,"key press: RECALL\n");
                    valid_press = 1;
                    top->key_recall = 1;
                    break;
                case '*':
                    mvprintw(8,0,"key press: MUL\n");
                    valid_press = 1;
                    top->key_mult = 1;
                    break;
                case '/':
                    mvprintw(8,0,"key press: DIV\n");
                    valid_press = 1;
                    top->key_div = 1;
                    break;
                case '+':
                    mvprintw(8,0,"key press: ADD\n");
                    valid_press = 1;
                    top->key_add = 1;
                    break;
                case '-':
                    mvprintw(8,0,"key press: SUB\n");
                    valid_press = 1;
                    top->key_sub = 1;
                    break;
                case KEY_UP:
                    if (top->sw_dp < 13)
                        top->sw_dp++;
                    break;
                case KEY_DOWN:
                    if (top->sw_dp > 0)
                        top->sw_dp--;
                    break;
                case 'q':
                    endwin();
                    quit = 1;
                    break;
                default:
                    mvprintw(8,0,"unknown key press: 0x%03x\n", c);
                    break;
            }
        }

        if (valid_press) {
            valid_press = 0;
            key_processed = 0;
            t_event = i + KEY_DELAY;
        }

        if (!key_processed && (t_event == i)) {
            key_processed = 1;
            move(8,0);
            printw("\n");
            top->key_of_lock = 0;
            top->key_chg_sign = 0;
            top->key_repeat = 0;
            top->key_div = 0;
            top->key_clr_ent = 0;
            top->key_enter = 0;
            top->key_mult = 0;
            top->key_clr_all = 0;
            top->key_sub = 0;
            top->key_add = 0;
            top->key_store = 0;
            top->key_recall = 0;
            top->key_dp = 0;
            top->key_0 = 0;
            top->key_1 = 0;
            top->key_2 = 0;
            top->key_3 = 0;
            top->key_4 = 0;
            top->key_5 = 0;
            top->key_6 = 0;
            top->key_7 = 0;
            top->key_8 = 0;
            top->key_9 = 0;
        }

        move(10,0);
        if (top->kbd_lock)
            printw("LOCK\n");
        else
            printw("\n");
        if (top->lamp_overflow)
            printw("OVERFLOW\n");
        else
            printw("\n");

        printw("sw_dp:     %d\n", top->sw_dp);
        printw("kbd_ack:   %d\n", top->kbd_ack);
        printw("timing:    %04x\n", top->timing);
        printw("phase:     %d\n", top->phase);
        printw("a_cnt:     %x\n", top->a_cnt);
        printw("b_cnt:     %x\n", top->a_cnt);
        printw("c_cnt:     %x\n", top->c_cnt);
        printw("d_cnt:     %x\n", top->d_cnt);
        printw("dp_cnt:    %x\n", top->dp_cnt);
        printw("start:     %x\n", top->ff_start);
        printw("home:      %x\n", top->ff_home);
        printw("shft_dwn:  %x\n", top->ff_shift_down);

        mvprintw(9,30,"chg_sign:  %x\n", top->ff_chg_sign);
        mvprintw(10,30,"store:     %x\n", top->ff_store);
        mvprintw(11,30,"recall:    %x\n", top->ff_recall);
        mvprintw(12,30,"repeat:    %x\n", top->ff_repeat);
        mvprintw(13,30,"add_sub:   %x\n", top->ff_add_sub);
        mvprintw(14,30,"mult:      %x\n", top->ff_mult);
        mvprintw(15,30,"div:       %x\n", top->ff_div);
        mvprintw(16,30,"com_fun:   %x\n", top->ff_com_fun);
        mvprintw(17,30,"com_dig:   %x\n", top->ff_com_dig);
        mvprintw(18,30,"cfs:       %x\n", top->ff_cfs);
        mvprintw(19,30,"sign_cont: %x\n", top->ff_sign_cont);
        mvprintw(20,30,"dps:       %x\n", top->ff_dps);
        mvprintw(21,30,"of:        %x\n", top->ff_of);
        mvprintw(22,30,"carry:     %x\n", top->ff_carry);
        mvprintw(23,30,"carry_of:  %x\n", top->ff_carry_of);

        move(0,0);
        print_reg(top->reg_4, top->sw_dp);
        print_reg(top->reg_3, top->sw_dp);
        print_reg(top->reg_2, top->sw_dp);
        print_reg(top->reg_1, top->sw_dp);
        print_reg(top->reg_0, top->sw_dp);
        print_reg(top->reg_s, top->sw_dp);

        for (int clk = 0; clk < 2; clk++) {
#if VM_TRACE
            tfp->dump(10*i + 5*clk);
#endif
            top->clk = clk;
            top->eval();
        }
    }

#if VM_TRACE
	if (tfp)
		tfp->close();
#endif

    top->final();

    VL_PRINTF("\nexiting...\n");
    exit(0);
}
