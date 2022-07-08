// Friden EC-130 simulator with OpenGL support
// Kyle Owen - 8 July 2022

#include <stdio.h>
#include <stdlib.h>
#include <memory>
#include <verilated.h>
#include "Vtop.h"

#include <GL/gl.h>
#include <GL/glu.h>
#include <GL/glut.h>

// vertical positions
#define POS_A 2.0
#define POS_B 1.0
#define POS_C 0.0
float v_lut[] = {POS_C, POS_B, POS_A};

// horizontal positions
#define POS_D 1.0
#define POS_E 0.0
#define POS_F -0.2
float h_lut[] = {POS_F, POS_E, POS_D};

// scale factors
#define V_SCALE 6.0
#define H_SCALE 6.0
#define SLANT_FACTOR 0.2

// spacing
#define H_SPACING 9.0
#define V_SPACING 18.0

// shifting
#define SHIFT_1 (0.3 * H_SPACING)
#define SHIFT_7 (-0.1 * H_SPACING)

#define KEY_DELAY 50000UL
uint64_t t_event;
int valid_press = 0;
int key_processed = 1;
int quit = 0;
uint64_t i = 0;
Vtop *top;

#undef VM_TRACE // trace doesn't work for this OpenGL version...yet

#if VM_TRACE
VerilatedVcdC* tfp;
#endif

void segment(float v_off, float h_off, int v_pos, int h_pos, int vseg, float len)
{
    if (len == 0.0) {
        glBegin(GL_POINTS); // draw a decimal point
        glVertex2f(h_off + h_lut[h_pos] * H_SCALE + SLANT_FACTOR * v_lut[v_pos] * V_SCALE, 
                   v_off + v_lut[v_pos] * V_SCALE);
    } else {
        glBegin(GL_LINES);
        glVertex2f(h_off + h_lut[h_pos] * H_SCALE + SLANT_FACTOR * v_lut[v_pos] * V_SCALE, 
                   v_off + v_lut[v_pos] * V_SCALE);
        if (vseg) // draw vertical segment
            glVertex2f(h_off + h_lut[h_pos] * H_SCALE + SLANT_FACTOR * (v_lut[v_pos] - len) * V_SCALE, 
                       v_off + (v_lut[v_pos] - len) * V_SCALE);
        else // draw horizontal segment
            glVertex2f(h_off + (h_lut[h_pos] - len) * H_SCALE + SLANT_FACTOR * v_lut[v_pos] * V_SCALE, 
                       v_off + v_lut[v_pos] * V_SCALE);
    }
    glEnd();
    glFlush();
}

void display(void)
{
    if (quit) {
#if VM_TRACE
        if (tfp)
            tfp->close();
#endif
        top->final();
        VL_PRINTF("\nexiting...\n");
        exit(0);
    }

    for (int clk = 0; clk < 2; clk++) {
#if VM_TRACE
        tfp->dump(10*i + 5*clk);
#endif
        top->clk = clk;
        top->eval();
    }

    if (top->erase) {
        glutSwapBuffers();
        glClear(GL_COLOR_BUFFER_BIT);
        glFlush();
    }

    if (top->seg_samp)
        segment(top->v_staircase * V_SPACING, 
                top->shift1 * SHIFT_1 + top->shift7 * SHIFT_7 + 
                (13 - top->h_staircase) * H_SPACING, 
                top->v_dot, top->h_dot, top->v_seg, top->seg_len / 48.0);

    if (valid_press) {
        valid_press = 0;
        key_processed = 0;
        t_event = i + KEY_DELAY;
    }

    if (!key_processed && (t_event == i)) {
        key_processed = 1;
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

    i++;
    glutPostRedisplay();
}

void keyboard_sf(int key, int x, int y)
{
    switch (key) {
        case GLUT_KEY_UP:
            valid_press = 0;
            if (top->sw_dp < 13)
                top->sw_dp++;
            break;
        case GLUT_KEY_DOWN:
            valid_press = 0;
            if (top->sw_dp > 0)
                top->sw_dp--;
            break;
        default:
            break;
    }
}

void keyboard(unsigned char key, int x, int y)
{
    valid_press = 1;
    switch (key) {
        case '0':
            top->key_0 = 1;
            break;
        case '1':
            top->key_1 = 1;
            break;
        case '2':
            top->key_2 = 1;
            break;
        case '3':
            top->key_3 = 1;
            break;
        case '4':
            top->key_4 = 1;
            break;
        case '5':
            top->key_5 = 1;
            break;
        case '6':
            top->key_6 = 1;
            break;
        case '7':
            top->key_7 = 1;
            break;
        case '8':
            top->key_8 = 1;
            break;
        case '9':
            top->key_9 = 1;
            break;
        case '\r':
        case '\n':
            top->key_enter = 1;
            break;
        case 0x7F:
        case '\b':
            top->key_clr_ent = 1;
            break;
        case 'c':
            top->key_clr_all = 1;
            break;
        case '.':
            top->key_dp = 1;
            break;
        case 's':
            top->key_chg_sign = 1;
            break;
        case 'r':
            top->key_repeat = 1;
            break;
        case 'o':
            top->key_of_lock = 1;
            break;
        case 't':
            top->key_store = 1;
            break;
        case 'e':
            top->key_recall = 1;
            break;
        case '*':
            top->key_mult = 1;
            break;
        case '/':
            top->key_div = 1;
            break;
        case '+':
            top->key_add = 1;
            break;
        case '-':
            top->key_sub = 1;
            break;
        case 'q':
            valid_press = 0;
            quit = 1;
            break;
        default:
            valid_press = 0;
            break;
    }
}

void init(void) 
{
    glutInitDisplayMode (GLUT_DOUBLE | GLUT_RGB);
    glutInitWindowSize (600, 300);
    glutInitWindowPosition(500, 300);
    glutCreateWindow("Friden EC-130");
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glColor3f(0.0, 1.0, 0.0);
    glPointSize(2.0);
    //glEnable(GL_POINT_SMOOTH);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    gluOrtho2D(-15, 145, -8, 72);
}

int main(int argc, char** argv, char** env) {
    if (false && argc && argv && env) {}

    Verilated::debug(0);
    Verilated::randReset(2);
    Verilated::traceEverOn(true);
    Verilated::commandArgs(argc, argv);

    top = new Vtop;

#if VM_TRACE
	const char* flag = Verilated::commandArgsPlusMatch("trace");
    if (flag && 0 == strcmp(flag, "+trace")) {
		tfp = new VerilatedVcdC;
		top->trace(tfp, 99);
		tfp->open("logs/trace.vcd");
	}
#endif
	VL_PRINTF("starting simulation...\n");

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

    glutInit(&argc, argv);
    init();
    glutKeyboardFunc(keyboard);
    glutSpecialFunc(keyboard_sf);
    glutDisplayFunc(display);
    glutMainLoop();
    return 0;
}
