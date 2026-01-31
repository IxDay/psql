/* PostgreSQL OS-specific configuration for Linux */

#ifndef PG_CONFIG_OS_H
#define PG_CONFIG_OS_H

/* Linux-specific settings from port/linux.h */
#define HAVE_LINUX_EIDRM_BUG
#define PLATFORM_DEFAULT_SYNC_METHOD SYNC_METHOD_FDATASYNC

#endif /* PG_CONFIG_OS_H */
