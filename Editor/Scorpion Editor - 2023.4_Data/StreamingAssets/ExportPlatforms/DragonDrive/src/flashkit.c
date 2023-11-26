/*
 * Tool for USB serial communication with Krikzz's FlashKit-MD
 * Copyright (c) 2017 notaz
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be 
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
 * BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <assert.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <arpa/inet.h> // hton
#include <termios.h>
#include <unistd.h>

#ifndef min
#define min(x, y) ((x) < (y) ? (x) : (y))
#define max(x, y) ((x) > (y) ? (x) : (y))
#endif

enum dev_cmd {
	CMD_ADDR = 0,
        CMD_LEN = 1,
        CMD_RD = 2,
        CMD_WR = 3,
        CMD_RY = 4,
        CMD_DELAY = 5,
};
#define PAR_MODE8  (1 << 4)
#define PAR_DEV_ID (1 << 5)
#define PAR_SINGE  (1 << 6)
#define PAR_INC    (1 << 7)

static int setup(int fd)
{
	struct termios tty;
	int ret;

	memset(&tty, 0, sizeof(tty));

	ret = tcgetattr(fd, &tty);
	if (ret != 0)
	{
		perror("tcgetattr");
		return 1;
	}

	tty.c_iflag &= ~(IGNBRK | BRKINT | PARMRK | ISTRIP
			| INLCR | IGNCR | ICRNL | IXON);
	tty.c_oflag &= ~OPOST;
	tty.c_lflag &= ~(ECHO | ECHONL | ICANON | ISIG | IEXTEN);
	tty.c_cflag &= ~(CSIZE | PARENB);
	tty.c_cflag |= CS8;

	//tty.c_cc[VMIN] = 1;
	//tty.c_cc[VTIME] = 5;            // 0.5 seconds read timeout

	ret = tcsetattr(fd, TCSANOW, &tty);
	if (ret != 0) {
		perror("tcsetattr");
		return ret;
	}

	return 0;
}

static int write_serial(int fd, const void *data, size_t size)
{
	int ret;

	ret = write(fd, data, size);
	if (ret != size) {
		fprintf(stderr, "write %d/%zd: ", ret, size);
		perror("");
		exit(1);
	}

	return 0;
}

static int read_serial(int fd, void *data, size_t size)
{
	size_t got = 0;
	int ret;

	while (got < size) {
		ret = read(fd, (char *)data + got, size - got);
		if (ret <= 0) {
			fprintf(stderr, "read %d %zd/%zd: ",
				ret, got, size);
			perror("");
			exit(1);
		}
		got += ret;
	}

	return 0;
}

static void set_addr(int fd, uint32_t addr)
{
	uint8_t cmd[6] = {
		CMD_ADDR, addr >> 17,
		CMD_ADDR, addr >> 9,
		CMD_ADDR, addr >> 1
	};
	write_serial(fd, cmd, sizeof(cmd));
}

static uint16_t read_word(int fd, uint32_t addr)
{
	uint8_t cmd[7] = {
		CMD_ADDR, addr >> 17,
		CMD_ADDR, addr >> 9,
		CMD_ADDR, addr >> 1,
		CMD_RD | PAR_SINGE
	};
	uint16_t r;

	write_serial(fd, cmd, sizeof(cmd));
	read_serial(fd, &r, sizeof(r));
	return ntohs(r);
}

static void write_word(int fd, uint32_t addr, uint16_t d)
{
	uint8_t cmd[9] = {
		CMD_ADDR, addr >> 17,
		CMD_ADDR, addr >> 9,
		CMD_ADDR, addr >> 1,
		CMD_WR | PAR_SINGE,
		d >> 8, d
	};

	write_serial(fd, cmd, sizeof(cmd));
}

static void read_block(int fd, void *dst, uint32_t size)
{
	uint8_t cmd[5] = {
		CMD_LEN, size >> 9,
		CMD_LEN, size >> 1,
		CMD_RD | PAR_INC
	};

	assert(size <= 0x10000);
	write_serial(fd, cmd, sizeof(cmd));
	read_serial(fd, dst, size);
}

static uint16_t flash_seq_r(int fd, uint8_t cmd, uint32_t addr)
{
	// unlock
	write_word(fd, 0xaaa, 0xaa);
	write_word(fd, 0x555, 0x55);

	write_word(fd, 0xaaa, cmd);
	return read_word(fd, addr);
}

static void flash_seq_erase(int fd, uint32_t addr)
{
	// printf("erase %06x\n", addr);
	write_word(fd, 0xaaa, 0xaa);
	write_word(fd, 0x555, 0x55);
	write_word(fd, 0xaaa, 0x80);

	write_word(fd, 0xaaa, 0xaa);
	write_word(fd, 0x555, 0x55);
	write_word(fd, addr, 0x30);
}

static void flash_seq_write(int fd, uint32_t addr, uint8_t *d)
{
	uint8_t cmd[] = {
		// unlock
		CMD_ADDR, 0,
		CMD_ADDR, 0x05,
		CMD_ADDR, 0x55,
		CMD_WR | PAR_SINGE | PAR_MODE8, 0xaa,
		CMD_ADDR, 0,
		CMD_ADDR, 0x02,
		CMD_ADDR, 0xaa,
		CMD_WR | PAR_SINGE | PAR_MODE8, 0x55,
		// program setup
		CMD_ADDR, 0,
		CMD_ADDR, 0x05,
		CMD_ADDR, 0x55,
		CMD_WR | PAR_SINGE | PAR_MODE8, 0xa0,
		// program data
		CMD_ADDR, addr >> 17,
		CMD_ADDR, addr >> 9,
		CMD_ADDR, addr >> 1,
		CMD_WR | PAR_SINGE, d[0], d[1],
		CMD_RY
	};

	write_serial(fd, cmd, sizeof(cmd));
}

// status wait + dummy read to cause a wait?
static uint16_t ry_read(int fd)
{
	uint8_t cmd[2] = { CMD_RY, CMD_RD | PAR_SINGE };
	uint16_t rv = 0;

	write_serial(fd, cmd, sizeof(cmd));
	read_serial(fd, &rv, sizeof(rv));
	return ntohs(rv);
}

static void set_delay(int fd, uint8_t delay)
{
	uint8_t cmd[2] = { CMD_DELAY, delay };

	write_serial(fd, cmd, sizeof(cmd));
}

static struct flash_info {
	uint16_t mid;
	uint16_t did;
	uint32_t size;
	uint16_t region_cnt;
	struct {
		uint32_t block_size;
		uint32_t block_count;
		uint32_t start;
		uint32_t size;
	} region[4];
} info;

static void read_info(int fd)
{
	static const uint16_t qry[3] = { 'Q', 'R', 'Y' };
	uint32_t total = 0;
	uint16_t resp[3];
	uint32_t i, a;

	info.mid = flash_seq_r(fd, 0x90, 0); // autoselect
	info.did = read_word(fd, 2);

	// could enter CFI directly, but there seems to be a "stack"
	// of modes, so 2 exits would be needed
	write_word(fd, 0, 0xf0);

	write_word(fd, 0xaa, 0x98); // CFI Query
	resp[0] = read_word(fd, 0x20);
	resp[1] = read_word(fd, 0x22);
	resp[2] = read_word(fd, 0x24);
	if (memcmp(resp, qry, sizeof(resp))) {
		fprintf(stderr, "unexpected CFI response: %04x %04x %04x\n",
			resp[0], resp[1], resp[2]);
		exit(1);
	}
	info.size = 1u << read_word(fd, 0x4e);
	info.region_cnt = read_word(fd, 0x58);
	assert(0 < info.region_cnt && info.region_cnt <= 4);
	for (i = 0, a = 0x5a; i < info.region_cnt; i++, a += 8) {
		info.region[i].block_count = read_word(fd, a + 0) + 1;
		info.region[i].block_count += read_word(fd, a + 2) << 8;
		info.region[i].block_size = read_word(fd, a + 4) << 8;
		info.region[i].block_size |= read_word(fd, a + 6) << 16;
		info.region[i].start = total;
		info.region[i].size =
			info.region[i].block_size * info.region[i].block_count;
		assert(info.region[i].size);
		total += info.region[i].size;
	}

	write_word(fd, 0, 0xf0); // flash reset

	printf("Flash info:\n");
	printf("Manufacturer ID: %04x\n", info.mid);
	printf("Device ID: %04x\n", info.did);
	printf("size: %u\n", info.size);
	printf("Erase Block Regions: %u\n", info.region_cnt);
	for (i = 0; i < info.region_cnt; i++)
		printf("  %5u x %u\n", info.region[i].block_size,
			info.region[i].block_count);
	if (info.size != total)
		fprintf(stderr, "warning: total is %u, bad CFI?\n", total);
}

static uint32_t get_block_addr(uint32_t addr, uint32_t blk_offset)
{
	uint32_t i;

	assert(info.region_cnt);
	for (i = 0; i < info.region_cnt; i++) {
		if (info.region[i].start <= addr
		    && addr < info.region[i].start + info.region[i].size)
		{
			uint32_t blk = (addr - info.region[i].start)
					/ info.region[i].block_size
					+ blk_offset;
			return info.region[i].start
				+ blk * info.region[i].block_size;
		}
	}

	fprintf(stderr, "\naddress out of range: 0x%x\n", addr);
	exit(1);
}

static void print_progress(uint32_t done, uint32_t total)
{
	int i, step;

	printf("\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b");
	printf("\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b"); /* 20 */
	printf("\b\b\b\b\b\b");
	printf("%06x/%06x |", done, total);

	step = (total + 19) / 20;
	for (i = step; i <= total; i += step)
		fputc(done >= i ? '=' : '-', stdout);
	printf("| %3d%%", done * 100 / total);
	fflush(stdout);
	if (done >= total)
		fputc('\n', stdout);
}

static void usage(const char *argv0)
{
	printf("usage:\n"
		"%s [options]\n"
		"  -d <ttydevice>      (default /dev/ttyS2, which would be COM-Port 3)\n"
		"  -r <file> [size]    dump the cart (default 4MB)\n"
		"  -w <file> [size]    flash the cart (file size)\n"
		"  -e <size>           erase (rounds to block size)\n"
		"  -a <start_address>  cart start address (default 0)\n"
		"  -v                  verify written data\n"
		"  -i                  get info about the flash chip\n"
		, argv0);
	exit(1);
}

static void invarg(int argc, char *argv[], int arg)
{
	if (arg < argc)
		fprintf(stderr, "invalid arg %d: \"%s\"\n", arg, argv[arg]);
	else
		fprintf(stderr, "missing required argument %d\n", arg);
	exit(1);
}

static void *getarg(int argc, char *argv[], int arg)
{
	if (arg >= argc)
		invarg(argc, argv, arg);
	return argv[arg];
}

static uint8_t g_block[0x10000];
static uint8_t g_block2[0x10000];

int main(int argc, char *argv[])
{
	const char *portname = "/dev/ttyS2";
	const char *fname_w = NULL;
	const char *fname_r = NULL;
	long size_w = 0;
	long size_r = 0;
	long size_e = 0;
	long size_v = 0;
	long len, address_in = 0;
	long a, a_blk, end;
	int do_info = 0;
	int do_verify = 0;
	FILE *f_w = NULL;
	FILE *f_r = NULL;
	uint8_t id[2] = { 0, 0 };
	uint8_t cmd;
	uint16_t rv;
	int arg = 1;
	int fd;

	if (argc < 2 || !strcmp(argv[1], "-h") || !strcmp(argv[1], "--help"))
		usage(argv[0]);

	for (arg = 1; arg < argc; arg++) {
		if (!strcmp(argv[arg], "-d")) {
			portname = getarg(argc, argv, ++arg);
			continue;
		}
		if (!strcmp(argv[arg], "-r")) {
			fname_r = getarg(argc, argv, ++arg);
			if (arg + 1 < argc && argv[arg + 1][0] != '-') {
				size_r = strtol(argv[++arg], NULL, 0);
				if (size_r <= 0)
					invarg(argc, argv, arg);
			}
			continue;
		}
		if (!strcmp(argv[arg], "-w")) {
			fname_w = getarg(argc, argv, ++arg);
			if (arg + 1 < argc && argv[arg + 1][0] != '-') {
				size_w = strtol(argv[++arg], NULL, 0);
				if (size_w <= 0)
					invarg(argc, argv, arg);
			}
			continue;
		}
		if (!strcmp(argv[arg], "-a")) {
			address_in = strtol(getarg(argc, argv, ++arg), NULL, 0);
			if (address_in < 0 || (address_in & 1))
				invarg(argc, argv, arg);
			continue;
		}
		if (!strcmp(argv[arg], "-e")) {
			size_e = strtol(getarg(argc, argv, ++arg), NULL, 0);
			if (size_e <= 0)
				invarg(argc, argv, arg);
			continue;
		}
		if (!strcmp(argv[arg], "-v")) {
			do_verify = 1;
			continue;
		}
		if (!strcmp(argv[arg], "-i")) {
			do_info = 1;
			continue;
		}
		invarg(argc, argv, arg);
	}

	if (fname_r && size_r == 0)
		size_r = 0x400000;

	if (fname_w) {
		f_w = fopen(fname_w, "rb");
		if (!f_w) {
			fprintf(stderr, "fopen %s: ", fname_w);
			perror("");
			return 1;
		}
		if (size_w <= 0) {
			fseek(f_w, 0, SEEK_END);
			size_w = ftell(f_w);
			fseek(f_w, 0, SEEK_SET);
		}
		if (size_w <= 0) {
			fprintf(stderr, "size of %s is %ld\n",
				fname_w, size_w);
			return 1;
		}
		if (size_e < size_w)
			size_e = size_w;
		if (do_verify)
			size_v = size_w;
	}

	fd = open(portname, O_RDWR | O_NOCTTY | O_SYNC);
	if (fd < 0) {
		fprintf(stderr, "open %s: ", portname);
		perror("");
		return 1;
	}

	setup(fd);

	cmd = CMD_RD | PAR_SINGE | PAR_DEV_ID;
	write_serial(fd, &cmd, sizeof(cmd));
	read_serial(fd, id, sizeof(id));
	if (id[0] != id[1] || id[0] == 0) {
		fprintf(stderr, "unexpected id: %02x %02x\n", id[0], id[1]);
		return 1;
	}
	printf("flashkit id: %02x\n", id[0]);

	set_delay(fd, 1);
	write_word(fd, 0, 0xf0); // flash reset

	if (do_info || size_e)
		read_info(fd);

	if (size_e) {
		// set_delay(fd, 0); // ?
		a_blk = get_block_addr(address_in, 0);
		end = address_in + size_e;

		printf("erasing %ld bytes:\n", size_e);
		print_progress(0, size_e);
		for (a = address_in; a < end; ) {
			flash_seq_erase(fd, a_blk);
			rv = ry_read(fd);
			if (rv != 0xffff) {
				fprintf(stderr, "\nerase error: %lx %04x\n",
					a_blk, rv);
			}

			a_blk = get_block_addr(a_blk, 1);
			a += a_blk - a;
			print_progress(a - address_in, size_e);
		}
	}
	if (f_w != NULL) {
		uint8_t b[2];
		set_delay(fd, 0);
		printf("writing %ld bytes:\n", size_w);
		for (a = 0; a < size_w; a += 2) {
			ssize_t r;

			b[1] = 0xff;
			len = min(size_w - a, 2);
			r = fread(b, 1, len, f_w);
			if (r != len) {
				perror("\nfread");
				return 1;
			}
			flash_seq_write(fd, address_in + a, b);

			if (!(a & 0x3fe))
				print_progress(a, size_w);
		}
		print_progress(a, size_w);
		rv = ry_read(fd);
		if (rv != ((b[0] << 8) | b[1]))
			fprintf(stderr, "warning: last bytes: %04x %02x%02x\n",
				rv, b[0], b[1]);
		rewind(f_w);
		set_delay(fd, 1);
	}

	if (fname_r || size_v) {
		long blks, blks_v, done, verify_diff = 0;

		blks = (size_r + sizeof(g_block) - 1) / sizeof(g_block);
		blks_v = (size_v + sizeof(g_block) - 1) / sizeof(g_block);
		blks = max(blks, blks_v);
		if (fname_r) {
			f_r = fopen(fname_r, "wb");
			if (!f_r) {
				fprintf(stderr, "fopen %s: ", fname_r);
				perror("");
				return 1;
			}
		}

		printf("reading %ld bytes:\n", max(size_r, size_v));
		print_progress(0, blks * sizeof(g_block));
		set_addr(fd, address_in);
		for (done = 0; done < size_r || done < size_v; ) {
			read_block(fd, g_block, sizeof(g_block));
			if (f_r && done < size_r) {
				len = min(size_r - done, sizeof(g_block));
				if (fwrite(g_block, 1, len, f_r) != len) {
					perror("fwrite");
					return 1;
				}
			}
			if (done < size_v) {
				len = min(size_v - done, sizeof(g_block));
				if (fread(g_block2, 1, len, f_w) != len) {
					perror("fread");
					return 1;
				}
				verify_diff |= memcmp(g_block, g_block2, len);
			}
			done += sizeof(g_block);
			print_progress(done, blks * sizeof(g_block));
		}
		if (verify_diff) {
			fprintf(stderr, "verify FAILED\n");
			return 1;
		}
	}
	if (f_r)
		fclose(f_r);
	if (f_w)
		fclose(f_w);

	return 0;
}
