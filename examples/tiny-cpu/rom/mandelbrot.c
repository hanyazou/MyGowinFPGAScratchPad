#include <stdio.h>
#include <stdint.h>

typedef int16_t var_t;
//typedef uint32_t var_t;

const int FRACBITS = 9;
const int WIDTH = 78;
const int HEIGHT = 24;

var_t fixed_point(float f)
{
    return f * (1 << FRACBITS);
}

var_t fp_mul(var_t a, var_t b)
{
    /*
    var_t bh, bl;
    bh = b >> FRACBITS;
    bl = b & ((1 << FRACBITS) - 1);
    */
    /*
    printf("fp_mul: bh=%04x, bl=%04x, %04x * %04x = %04x\n", (uint16_t)bh, (uint16_t)bl,
           (uint16_t)a, (uint16_t)b, (a * bh) + ((uint16_t)(a * bl) >> FRACBITS));
    printf("fp_mul: (a * bh)=%04x, (a * bl)=%04x, %04x\n", a * bh, (uint16_t)a * (uint16_t)bl,
           ((uint16_t)((a * bl)) >> FRACBITS));
    printf("fp_mul: bh=%04x, bl=%04x, %04x * %04x = %04x\n", bh, bl,
           a, b, (a * bh) + ((a * bl) >> FRACBITS));
    printf("fp_mul: (a * bh)=%04x, (a * bl)=%04x, %04x\n", a * bh, a * bl,
           ((a * bl) >> FRACBITS));
    */
    //return (a * bh) + (((uint16_t)(a * bl)) >> FRACBITS);
    //return (a * bh) + (((uint16_t)(a >> FRACBITS)) * bl);
    /*
    printf("fp_mul: %04x * %04x = %04x * %04x = %04x\n",
           ((uint16_t)a), ((uint16_t)b),
           ((uint16_t)(a >> 4)), ((uint16_t)(b >> (FRACBITS - 4))),
           (uint16_t)(((uint16_t)(a >> 4)) * ((uint16_t)(b >> (FRACBITS - 4)))));
    */
    //return (uint16_t)(((uint16_t)(a >> 4)) * ((uint16_t)(b >> (FRACBITS - 4))));
    return (var_t)(((var_t)(a >> 4)) * ((var_t)(b >> (FRACBITS - 4))));
    //return (a * bh) + ((a * bl) >> FRACBITS);
}

int main(int ac, char *av[])
{
    const var_t FP0_0458 = fixed_point(0.0458);
    const var_t FP0_08333 = fixed_point(0.08333);
    const var_t FP4_0 = fixed_point(4.0);

    int16_t X, Y;
    var_t A, B, CA, CB;
    var_t T;
    uint8_t I;

    CA = -WIDTH/2 * FP0_0458;
    CB = -HEIGHT/2 * FP0_08333;

    printf(" FRACBITS: %d\n", FRACBITS);
    printf(" FP0_0458: %04x\n", FP0_0458);
    printf("FP0_08333: %04x\n", FP0_08333);
    printf("    FP4_0: %04x\n", FP4_0);
    printf(" CA(init): %04x\n", (unsigned)(var_t)CA);
    printf(" CB(init): %04x\n", (unsigned)(var_t)CB);

    for (Y = HEIGHT + 1; 0 < Y; Y--) {
        CA = -WIDTH/2 * FP0_0458;
        for (X = WIDTH + 1; 0 < X; X--) {
            A = CA;
            B = CB;
            for (I = 0; I <= 15; I++) {
                T = fp_mul(A, A) - fp_mul(B, B) + CA;
                B = 2 * fp_mul(A, B) + CB;
                A = T;
                /*
                printf("X=%04x Y=%04x A=%04x B=%04x CA=%04x CB=%04x T=%04x I=%04x\n",
                       (uint16_t)X, (uint16_t)Y, (uint16_t)A, (uint16_t)B,
                       (uint16_t)CA, (uint16_t)CB, (uint16_t)T, (uint16_t)I);
                */
#if 0
                printf("X=%08x Y=%08x A=%08x B=%08x CA=%08x CB=%08x T=%08x I=%08x\n",
                       (uint32_t)X, (uint32_t)Y, (uint32_t)A, (uint32_t)B,
                       (uint32_t)CA, (uint32_t)CB, (uint32_t)T, (uint32_t)I);
#endif
                if ((fp_mul(A, A) + fp_mul(B, B)) > FP4_0) {
                    if (I > 9) I = I + 7;
                    printf("%c", 48 + I);
                    break;
                } else {
                    if (I == 15) {
                        printf(" ");
                    }
                }
            }
            CA = CA + FP0_0458;
        }
#if 1
                printf("X=%08x Y=%08x A=%08x B=%08x CA=%08x CB=%08x T=%08x I=%08x\n",
                       (uint32_t)X, (uint32_t)Y, (uint32_t)A, (uint32_t)B,
                       (uint32_t)CA, (uint32_t)CB, (uint32_t)T, (uint32_t)I);
#endif
        CB = CB + FP0_08333;
        printf("\n");
    }

    return 0;
}
