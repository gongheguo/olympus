//sycamore_platform.h

#ifndef __SYCAMORE_PLATFORM_H__
#define __SYCAMORE_PLATFORM_H__

#include <linux/tty.h>
#define SYCAMORE_BUS_NAME "sycamore"

#define BUFFER_SIZE 512

typedef struct _sycamore_t sycamore_t;

//sycamore_platfrom data
struct _sycamore_t {
	//platform stuff
	struct platform_device *platform_device;
	struct attribute_group platform_attribute_group;
	u32	size_of_drt;
	char * drt;
	int	port_lock;
	struct platform_device *pdev;

	int buf_pos;
	char in_buffer[BUFFER_SIZE];
//	int  (*ioctl)(struct tty_struct *tty,
	//	      unsigned int cmd, unsigned long arg);

};



void read_data(sycamore_t *sycamore, char * buffer, int lenth);
int sycamore_ioctl(sycamore_t *sycamore, struct tty_struct *tty, unsigned int cmd, unsigned long arg);
int sycamore_attach(sycamore_t *sycamore);
void sycamore_disconnect(sycamore_t *sycamore);


#endif //__SYCAMORE_PLATFORM_H__
