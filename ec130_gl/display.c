#include <GL/glut.h>
#include "display.h"

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

void segment(float v_off, float h_off, int v_pos, int h_pos, int vseg, float len)
{
    if (len == 0.0) {
        glBegin(GL_POINTS); // draw a decimal point
        glVertex2f(h_off + H_LUT[h_pos] * H_SCALE + SLANT_FACTOR * V_LUT[v_pos] * V_SCALE, 
                   v_off + V_LUT[v_pos] * V_SCALE);
    } else {
        glBegin(GL_LINES);
        glVertex2f(h_off + H_LUT[h_pos] * H_SCALE + SLANT_FACTOR * V_LUT[v_pos] * V_SCALE, 
                   v_off + V_LUT[v_pos] * V_SCALE);
        if (vseg) // draw vertical segment
            glVertex2f(h_off + H_LUT[h_pos] * H_SCALE + SLANT_FACTOR * (V_LUT[v_pos] - len) * V_SCALE, 
                       v_off + (V_LUT[v_pos] - len) * V_SCALE);
        else // draw horizontal segment
            glVertex2f(h_off + (H_LUT[h_pos] - len) * H_SCALE + SLANT_FACTOR * V_LUT[v_pos] * V_SCALE, 
                       v_off + V_LUT[v_pos] * V_SCALE);
    }
    glEnd();
    glFlush();
}

void display_helper(int erase, int seg_samp, int v_staircase, int h_staircase, 
                    int v_dot, int h_dot, int v_seg, int seg_len, int shift1, int shift7) 
{
    if (erase) {
        glutSwapBuffers();
        glClear(GL_COLOR_BUFFER_BIT);
        glFlush();
    }

    if (seg_samp)
        segment(v_staircase * V_SPACING, 
                shift1 * SHIFT_1 + shift7 * SHIFT_7 + 
                (13 - h_staircase) * H_SPACING, 
                v_dot, h_dot, v_seg, seg_len / 48.0);
}

