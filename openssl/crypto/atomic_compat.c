/*
 * On 32-bit x86 (baseline i386), the compiler generates calls to
 * __atomic_is_lock_free for 64-bit atomic operations because the
 * target may lack cmpxchg8b.  Zig's compiler-rt doesn't provide
 * this symbol, so we supply it via inline assembly.
 *
 * Returns 1 (lock-free) for sizes <= 4 bytes, 0 otherwise.
 * OpenSSL's threads_pthread.c falls back to a mutex-based path
 * when atomics aren't lock-free.
 */
#if defined(__i386__) || defined(_M_IX86)
__asm__(
    ".globl __atomic_is_lock_free\n"
    ".type __atomic_is_lock_free, @function\n"
    "__atomic_is_lock_free:\n"
    "    cmpl $4, 4(%esp)\n"
    "    setbe %al\n"
    "    movzbl %al, %eax\n"
    "    ret\n"
);
#endif
