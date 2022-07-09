// vertical positions
#define POS_A 2.0
#define POS_B 1.0
#define POS_C 0.0

// horizontal positions
#define POS_D 1.0
#define POS_E 0.0
#define POS_F -0.2

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

const float V_LUT[] = {POS_C, POS_B, POS_A};
const float H_LUT[] = {POS_F, POS_E, POS_D};

void init(void);

void display_helper(int erase, int seg_samp, int v_staircase, int h_staircase, 
                    int v_dot, int h_dot, int v_seg, int seg_len, int shift1, int shift7);
