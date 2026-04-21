/*
 * benchmark_matmul.c
 * 
 * Software baseline for 8x8 INT8 matrix multiplication on ARM Cortex-A53 (Zynq PS)
 * Used to establish speedup ratio vs systolic array hardware accelerator.
 *
 * Build (bare-metal Vitis):
 *   arm-none-eabi-gcc -O0 -o benchmark_matmul.elf benchmark_matmul.c
 *
 * Build (Linux on PetaLinux):
 *   aarch64-linux-gnu-gcc -O0 -o benchmark_matmul benchmark_matmul.c
 *
 * -O0 flag is intentional: we want unoptimized scalar baseline to fairly
 * represent what the CPU does without SIMD/NEON auto-vectorization.
 * A separate NEON-optimized baseline can be added for comparison.
 *
 * Author: Anil Sanneboyina
 */

#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <time.h>

#define N       8           /* Matrix dimension */
#define RUNS    100000      /* Number of iterations for averaging */

/* -----------------------------------------------------------------------
 * Scalar INT8 matrix multiply (no SIMD, no optimization)
 * C[i][j] = sum_k A[i][k] * B[k][j]
 * Accumulator is 32-bit to match hardware PE behavior
 * ----------------------------------------------------------------------- */
void matmul_scalar(
    const int8_t  A[N][N],
    const int8_t  B[N][N],
    int32_t       C[N][N])
{
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            int32_t acc = 0;
            for (int k = 0; k < N; k++) {
                acc += (int32_t)A[i][k] * (int32_t)B[k][j];
            }
            C[i][j] = acc;
        }
    }
}

/* -----------------------------------------------------------------------
 * Test matrices — fixed values for reproducibility
 * Same values used in hardware testbench (tb_systolic_nxn.v)
 * A = identity matrix scaled by 2 → result should be 2*B
 * ----------------------------------------------------------------------- */
static const int8_t A_test[N][N] = {
    {2, 0, 0, 0, 0, 0, 0, 0},
    {0, 2, 0, 0, 0, 0, 0, 0},
    {0, 0, 2, 0, 0, 0, 0, 0},
    {0, 0, 0, 2, 0, 0, 0, 0},
    {0, 0, 0, 0, 2, 0, 0, 0},
    {0, 0, 0, 0, 0, 2, 0, 0},
    {0, 0, 0, 0, 0, 0, 2, 0},
    {0, 0, 0, 0, 0, 0, 0, 2}
};

static const int8_t B_test[N][N] = {
    { 1,  2,  3,  4,  5,  6,  7,  8},
    { 9, 10, 11, 12, 13, 14, 15, 16},
    {17, 18, 19, 20, 21, 22, 23, 24},
    {25, 26, 27, 28, 29, 30, 31, 32},
    {33, 34, 35, 36, 37, 38, 39, 40},
    {41, 42, 43, 44, 45, 46, 47, 48},
    {49, 50, 51, 52, 53, 54, 55, 56},
    {57, 58, 59, 60, 61, 62, 63, 64}
};

/* -----------------------------------------------------------------------
 * Timer utilities
 * Uses POSIX clock_gettime (CLOCK_MONOTONIC) on Linux.
 * For bare-metal Vitis, replace with Xil_GetTime() or PMU cycle counter.
 * ----------------------------------------------------------------------- */
static inline double get_time_ns(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec * 1e9 + (double)ts.tv_nsec;
}

/* -----------------------------------------------------------------------
 * Main
 * ----------------------------------------------------------------------- */
int main(void) {
    int32_t C[N][N];
    double  t_start, t_end, elapsed_ns, avg_ns;

    printf("=== 8x8 INT8 Matrix Multiply — ARM Cortex-A53 Software Baseline ===\n");
    printf("Matrix dimension : %d x %d\n", N, N);
    printf("MAC operations   : %d per multiply (%d x %d x %d)\n",
           N*N*N, N, N, N);
    printf("Iterations       : %d\n\n", RUNS);

    /* --- Warm-up pass (not timed) --- */
    matmul_scalar(A_test, B_test, C);

    /* --- Timed benchmark --- */
    t_start = get_time_ns();
    for (int r = 0; r < RUNS; r++) {
        matmul_scalar(A_test, B_test, C);
        /* Prevent dead-code elimination */
        __asm__ volatile("" : : "r"(C) : "memory");
    }
    t_end = get_time_ns();

    elapsed_ns = t_end - t_start;
    avg_ns     = elapsed_ns / (double)RUNS;

    printf("--- Results ---\n");
    printf("Total time for %d runs : %.2f ms\n", RUNS, elapsed_ns / 1e6);
    printf("Average per multiply   : %.2f ns\n",  avg_ns);
    printf("Throughput             : %.2f MMAC/s\n",
           (double)(N*N*N) / avg_ns * 1000.0);

    /* -----------------------------------------------------------------------
     * Hardware comparison — update HARDWARE_CYCLES with your simulation result
     *
     * From wave-skew systolic array analysis:
     *   Skew latency  = 2N - 2 = 14 cycles
     *   Compute       = N      =  8 cycles
     *   Drain         = N      =  8 cycles
     *   Total         ~        = 30 cycles  (measure from waveform to confirm)
     *
     * At 100 MHz: 30 cycles × 10 ns = 300 ns per 8x8 multiply
     * ----------------------------------------------------------------------- */
    const double CLOCK_PERIOD_NS  = 10.0;   /* 100 MHz */
    const int    HARDWARE_CYCLES  = 30;     /* UPDATE from your waveform */
    double       hw_latency_ns    = HARDWARE_CYCLES * CLOCK_PERIOD_NS;
    double       speedup          = avg_ns / hw_latency_ns;

    /* Power efficiency — from Vivado power report */
    const double PL_POWER_W       = 0.006;  /* 6 mW PL logic */
    double       hw_gops          = (double)(N*N*N) / hw_latency_ns; /* GOPS */
    double       hw_efficiency    = hw_gops / PL_POWER_W;            /* GOPS/W */

    printf("\n--- Hardware vs Software Comparison ---\n");
    printf("Hardware latency (sim) : %.1f ns  (%d cycles @ 100 MHz)\n",
           hw_latency_ns, HARDWARE_CYCLES);
    printf("Software latency (ARM) : %.2f ns\n", avg_ns);
    printf("Estimated speedup      : %.2fx\n", speedup);
    printf("Hardware GOPS          : %.3f\n", hw_gops);
    printf("Power efficiency (PL)  : %.1f GOPS/W\n", hw_efficiency);

    /* --- Verify correctness against expected output --- */
    printf("\n--- Correctness Check (C = 2 * B) ---\n");
    int pass = 1;
    for (int i = 0; i < N && pass; i++)
        for (int j = 0; j < N && pass; j++)
            if (C[i][j] != 2 * (int32_t)B_test[i][j]) pass = 0;
    printf("Result: %s\n", pass ? "PASS" : "FAIL");

    return pass ? 0 : 1;
}
