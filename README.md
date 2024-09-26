# droptop4daemon
Monitors [DropTopFour](https://droptopfour.com) and restarts it if [RainMeter](https://www.rainmeter.net) has crashed or the screen reserved space coords are wrong which would also indicate that there is some issue.

I am unaware of any event logging by Windows around the screen reserved space area, so consider this a bandaid fix that I made for myself only. Your results may vary. Windows may place the RainMeter process in a suspended state and confuse it? Shrug.

Average CPU consumption: 0.07

Tested on Windows 11 Pro v22H2, PowerShell 7.4.

Run as user context (system context won't work) as well as elevated.

Use Windows task scheduler to run it at system start if desired, but run it as the logged in user credentials.

Should not impact even very low power CPUs, and should be fine to run continuously without performance impact:
![image](https://github.com/user-attachments/assets/c4d81c19-b615-4be0-af66-0cfa64a576cd)
