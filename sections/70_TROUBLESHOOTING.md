# Troubleshooting

## Tomcat unable to bind port (error in log file)

Occasionally if the Drillbridge server is not shut down properly it will leave a
process running and using the port that Drillbridge wants to operate on. This 
can prevent Drillbridge from starting properly. To fix this on a Windows 
system, just start the Task Manager, look for a process named java.exe, and 
stop it. Then start up the Drillbridge server.
