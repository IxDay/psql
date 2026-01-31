/*
 * Minimal arm_arch.h for cross-compilation without ARM assembly optimizations.
 * This disables ARM NEON/crypto extensions and uses C fallbacks instead.
 */

#ifndef __ARM_ARCH_H__
#define __ARM_ARCH_H__

/* Disable ARM assembly optimizations - use C fallbacks */
#define OPENSSL_NO_ASM

/* ARM feature detection - all disabled for portable builds */
#define ARMV7_NEON      0
#define ARMV8_AES       0
#define ARMV8_SHA1      0
#define ARMV8_SHA256    0
#define ARMV8_PMULL     0
#define ARMV8_SHA512    0
#define ARMV8_SM3       0
#define ARMV8_SM4       0

/* CPU capability variable - defined as 0 (no capabilities) */
extern unsigned int OPENSSL_armcap_P;

/* These macros are used to check for ARM crypto capabilities */
#define OPENSSL_armcap_P 0

#endif /* __ARM_ARCH_H__ */
