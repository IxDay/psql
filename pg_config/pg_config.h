/* PostgreSQL configuration for static psql build */

#ifndef PG_CONFIG_H
#define PG_CONFIG_H

/* Alignment requirements */
#define ALIGNOF_DOUBLE 8
#define ALIGNOF_INT 4
#define ALIGNOF_LONG 8
#define ALIGNOF_LONG_LONG_INT 8
#define ALIGNOF_SHORT 2

/* Block size */
#define BLCKSZ 8192

/* Default port */
#define DEF_PGPORT 5432
#define DEF_PGPORT_STR "5432"

/* Dynamic library suffix */
#define DLSUFFIX ".so"

/* Thread safety */
#define ENABLE_THREAD_SAFETY 1

/* Feature availability */
#define HAVE_ATOMICS 1
#define HAVE_COMPUTED_GOTO 1
#define HAVE_FSEEKO 1
#define HAVE_GETOPT 1
#define HAVE_GETOPT_H 1
#define HAVE_GETOPT_LONG 1
#define HAVE_GETIFADDRS 1
/* macOS has strlcat/strlcpy/strnlen built-in, Linux doesn't */
#ifdef __APPLE__
#define HAVE_DECL_STRLCAT 1
#define HAVE_DECL_STRLCPY 1
#define HAVE_DECL_STRNLEN 1
#define HAVE_DECL_FDATASYNC 0
#define HAVE_DECL_F_FULLFSYNC 1
#define HAVE_DECL_POSIX_FADVISE 0
#else
#define HAVE_DECL_STRLCAT 0
#define HAVE_DECL_STRLCPY 0
#define HAVE_DECL_STRNLEN 1
#define HAVE_DECL_FDATASYNC 1
#define HAVE_DECL_F_FULLFSYNC 0
#define HAVE_DECL_POSIX_FADVISE 1
#endif
#define HAVE_DECL_PREADV 1
#define HAVE_DECL_PWRITEV 1

/* GCC atomics */
#define HAVE_GCC__ATOMIC_INT32_CAS 1
#define HAVE_GCC__ATOMIC_INT64_CAS 1
#define HAVE_GCC__SYNC_CHAR_TAS 1
#define HAVE_GCC__SYNC_INT32_CAS 1
#define HAVE_GCC__SYNC_INT32_TAS 1
#define HAVE_GCC__SYNC_INT64_CAS 1

/* Headers */
#define HAVE_DLFCN_H 1
#define HAVE_IFADDRS_H 1
#define HAVE_INTTYPES_H 1
#define HAVE_LANGINFO_H 1
#define HAVE_MEMORY_H 1
#define HAVE_NETINET_TCP_H 1
#define HAVE_NET_IF_H 1
#define HAVE_POLL_H 1
#define HAVE_STDINT_H 1
#define HAVE_STDLIB_H 1
#define HAVE_STRINGS_H 1
#define HAVE_STRING_H 1
#define HAVE_STDBOOL_H 1
#define HAVE_SYS_EPOLL_H 1
#define HAVE_SYS_IPC_H 1
#define HAVE_SYS_RESOURCE_H 1
#define HAVE_SYS_SELECT_H 1
#define HAVE_SYS_SEM_H 1
#define HAVE_SYS_SHM_H 1
#define HAVE_SYS_SIGNALFD_H 1
#define HAVE_SYS_SOCKET_H 1
#define HAVE_SYS_STAT_H 1
#define HAVE_SYS_TIME_H 1
#define HAVE_SYS_TYPES_H 1
#define HAVE_SYS_UIO_H 1
#define HAVE_SYS_UN_H 1
#define HAVE_TERMIOS_H 1
#define HAVE_UNISTD_H 1
#define HAVE_WCTYPE_H 1

/* getopt - musl provides struct option */
#define HAVE_STRUCT_OPTION 1

/* Functions */
#define HAVE_CLOCK_GETTIME 1
#define HAVE_FDATASYNC 1
#define HAVE_GETRLIMIT 1
#define HAVE_INET_ATON 1
#define HAVE_INET_PTON 1
#define HAVE_MBSTOWCS_L 1
#define HAVE_MEMSET_S 0
#define HAVE_MKDTEMP 1
#define HAVE_POSIX_FADVISE 1
#define HAVE_POSIX_FALLOCATE 1
#define HAVE_PPOLL 1
#define HAVE_PTHREAD_BARRIER_WAIT 1
#define HAVE_READLINK 1
#define HAVE_SETENV 1
#define HAVE_SETSID 1
#define HAVE_STRCHRNUL 1
#define HAVE_STRERROR_R 1
#define HAVE_STRSIGNAL 1
#define HAVE_SYMLINK 1
#define HAVE_SYNCFS 1
/* sync_file_range not available in musl */
/* #define HAVE_SYNC_FILE_RANGE 1 */
#define HAVE_UNSETENV 1
#define HAVE_USELOCALE 1
#define HAVE_WCSTOMBS_L 1

/* Readline */
#define HAVE_LIBREADLINE 1
#define HAVE_READLINE_HISTORY_H 1
#define HAVE_READLINE_READLINE_H 1
#define HAVE_RL_COMPLETION_MATCHES 1
#define HAVE_RL_COMPLETION_SUPPRESS_QUOTE 1
#define HAVE_RL_FILENAME_COMPLETION_FUNCTION 1
#define HAVE_RL_RESET_SCREEN_SIZE 1
#define HAVE_HISTORY_TRUNCATE_FILE 1
#define HAVE_RL_VARIABLE_BIND 1

/* OpenSSL */
#define USE_OPENSSL 1
#define HAVE_OPENSSL_INIT_SSL 1
#define HAVE_ASN1_STRING_GET0_DATA 1
#define HAVE_BIO_GET_DATA 1
#define HAVE_BIO_METH_NEW 1
#define HAVE_SSL_CTX_SET_CERT_CB 1
#define HAVE_SSL_CTX_SET_NUM_TICKETS 1
#define HAVE_X509_GET_SIGNATURE_INFO 1
#define HAVE_HMAC_CTX_NEW 1
#define HAVE_HMAC_CTX_FREE 1

/* Kerberos */
#define PG_KRB_SRVNAM ""

/* zlib */
#define HAVE_LIBZ 1

/* Integer types - let c.h define them via HAVE_LONG_INT_64 */
#define HAVE_LONG_INT_64 1
#define PG_INT64_TYPE long int

/* Size types */
#define SIZEOF_BOOL 1
#define SIZEOF_LONG 8
#define SIZEOF_OFF_T 8
#define SIZEOF_SIZE_T 8
#define SIZEOF_VOID_P 8

/* Alignment */
#define MAXIMUM_ALIGNOF 8

/* Memory settings */
#define MEMSET_LOOP_LIMIT 1024

/* Byte order - little endian (do NOT define WORDS_BIGENDIAN for little endian) */
/* #undef WORDS_BIGENDIAN */

/* Maximum identifier length */
#define NAMEDATALEN 64

/* Segment size */
#define RELSEG_SIZE 131072

/* Index tuple size */
#define INDEX_MAX_KEYS 32

/* Toast chunk size */
#define TOAST_MAX_CHUNK_SIZE (BLCKSZ / 4)

/* Version info */
#define PG_MAJORVERSION "15"
#define PG_MAJORVERSION_NUM 15
#define PG_MINORVERSION_NUM 10
#define PG_VERSION "15.10"
#define PG_VERSION_NUM 151000
#define PG_VERSION_STR "PostgreSQL 15.10"

/* CATALOG version */
#define CATALOG_VERSION_NO 202209061

/* Package info */
#define PACKAGE_BUGREPORT "pgsql-bugs@lists.postgresql.org"
#define PACKAGE_NAME "PostgreSQL"
#define PACKAGE_STRING "PostgreSQL 15.10"
#define PACKAGE_TARNAME "postgresql"
#define PACKAGE_URL "https://www.postgresql.org/"
#define PACKAGE_VERSION "15.10"

/* Build configuration info */
#define CONFIGURE_ARGS "'--with-openssl'"

/* Locale */
#define LOCALE_T_IN_XLOCALE 0
#define WCSTOMBS_L_IN_XLOCALE 0

/* Strerror */
#define STRERROR_R_INT 1

/* Visibility */
#define HAVE_VISIBILITY_ATTRIBUTE 1
#define PG_VISIBILITY_SPEC __attribute__((visibility("default")))

/* Inline */
#ifndef PG_USE_INLINE
#define PG_USE_INLINE 1
#endif

/* Flexible array member */
#define FLEXIBLE_ARRAY_MEMBER

/* Restrict keyword */
#define pg_restrict __restrict

/* Printf format attribute */
#define PG_PRINTF_ATTRIBUTE printf

/* Use stdbool.h for bool type */
#define PG_USE_STDBOOL 1

/* Memory barrier */
#define pg_memory_barrier_impl() __atomic_thread_fence(__ATOMIC_SEQ_CST)
#define pg_read_barrier_impl() __atomic_thread_fence(__ATOMIC_ACQUIRE)
#define pg_write_barrier_impl() __atomic_thread_fence(__ATOMIC_RELEASE)

/* Spinlock */
#define HAVE_SPINLOCKS 1

/* Accept args */
#define ACCEPT_TYPE_ARG1 int
#define ACCEPT_TYPE_ARG2 struct sockaddr *
#define ACCEPT_TYPE_ARG3 socklen_t
#define ACCEPT_TYPE_RETURN int

/* Getaddrinfo */
#define HAVE_STRUCT_ADDRINFO 1
#define HAVE_STRUCT_SOCKADDR_STORAGE 1
#define HAVE_STRUCT_SOCKADDR_STORAGE_SS_FAMILY 1

/* Unix socket credentials */
#define HAVE_STRUCT_SOCKPEERCRED 0
#define HAVE_STRUCT_UCRED 1

/* WAL segment size */
#define XLOG_BLCKSZ 8192

#endif /* PG_CONFIG_H */
