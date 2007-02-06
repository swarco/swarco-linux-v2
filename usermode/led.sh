
while true
do
  ccm2200_gpio /dev/misc/ccm2200_gpio led 0x1248
  usleep 100000

  ccm2200_gpio /dev/misc/ccm2200_gpio led 0x03c0
  usleep 100000

  ccm2200_gpio /dev/misc/ccm2200_gpio led 0x0c30
  usleep 100000

  ccm2200_gpio /dev/misc/ccm2200_gpio led 0x8421
  usleep 100000

  ccm2200_gpio /dev/misc/ccm2200_gpio led 0x4422
  usleep 100000

  ccm2200_gpio /dev/misc/ccm2200_gpio led 0x2244
  usleep 100000
done