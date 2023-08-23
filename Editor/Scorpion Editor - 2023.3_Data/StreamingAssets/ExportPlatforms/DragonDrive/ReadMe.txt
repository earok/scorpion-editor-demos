Flashkit - A simple tool to flash DragonDrive carts using Krikzz Flashkit.
--------------------------------------------------------------------------
--- Windows Version ---

This tool has been designed to be used with the DragonDrive flashcarts.
If you want to use Krikzz Flashcarts, please download his own flasher tool.


How to use
----------

This program does not have a GUI and needs to be used from the command line.

If you simply run it, it will show all parameters which should be self-explanatory:

-d <ttydevice>      (default /dev/ttyS2, which would be COM-Port 3)
-r <file> [size]    dump the cart (default 4MB)
-w <file> [size]    flash the cart (file size)
-e <size>           erase (rounds to block size)
-a <start_address>  cart start address (default 0)
-v                  verify written data
-i                  get info about the flash chip

The first thing you need to find out is which COM-Port Windows has given the connected flashkit.
You can check this in the Device Manager.

The device that needs to be used translates like this:
COM1: /dev/ttyS0
COM2: /dev/ttyS1
COM3: /dev/ttyS2 (this is the default value)
COM4: /dev/ttyS3
... and so on, I think you get how it works :)

To flash a ROM onto the cart, all you need to do is enter:

flashkit.exe -d /dev/ttySX -w YOUR-ROM.bin
or
flashkit.exe -d /dev/ttySX -v -w YOUR-ROM.bin

The -v flag tests that the ROM has been properly flashed onto the cart.
Replace the X with the value according to the COM-Port.
If the COM-Port used is 3, then you can omit the -d parameter.

That's it :)

Note: If you receive the message "unexpected CFI response: ffff ffff ffff", then the flashcart is wrongly inserted into the flasher.
Simply turn it around and try again :)
