#include <linux/module.h>  // Needed by all modules
#include <linux/kernel.h>  // Needed for KERN_INFO
#include <linux/fs.h>      // Needed by filp
#include <asm/uaccess.h>   // Needed by segment descriptors

int init_module(void)
{
	struct file*f;
	char buf[128];
	char write_buf[12] = "test";
	mm_segment_t fs;
	int i;

	for (i = 0;i < 128; i++)
	{
		buf[i] = 0;
	}

	printk(KERN_INFO "read_write loaded\n");

	f = filp_open("/home/omkar/kernel_module/test", O_RDONLY, 0);
	if (f == NULL)
	{
		printk(KERN_ALERT "filp_open error!!.\n");
	}

	else
	{
		fs = get_fs();
		set_fs(get_ds());
		f->f_op->read(f, buf, 128, &f->f_pos);
		set_fs(fs);
		printk(KERN_INFO "buf:%s\n",buf);
	}

	filp_close(f,NULL);

	f = filp_open("/home/omkar/kernel_module/write", O_RDWR, 0);
    if (f == NULL)
    {
        printk(KERN_ALERT "filp_open error!!.\n");
    }

    else
    {
        fs = get_fs();
        set_fs(get_ds());
        f->f_op->write(f, write_buf, 12, &f->f_pos);
        set_fs(fs);
        printk(KERN_INFO "write_buf:%s\n",write_buf);
    }

    filp_close(f,NULL);
    return 0;
}

void cleanup_module(void)
{
    printk(KERN_INFO "read_write unloaded\n");
}
