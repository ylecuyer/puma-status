# puma-status

Command-line tool for puma to display information about running request/process

# Install

Install with

```
gem install puma-status
```

# Examples

Clustered mode:

```
9666 (/home/ylecuyer/Projects/testpuma/tmp/puma.state) Uptime:  0m43s | Load: 7[███████░░░░░░░░░]16
 └  9706 CPU:   0.0% Mem:   71 MB Uptime:  0m43s | Load: 3[███░]4
 └  9708 CPU:   0.0% Mem:   71 MB Uptime:  0m43s | Load: 4[████]4
 └  9725 CPU:   0.0% Mem:   58 MB Uptime:  0m43s | Load: 0[░░░░]4
 └  9732 CPU:   0.0% Mem:   58 MB Uptime:  0m43s | Load: 0[░░░░]4
```


Single mode:

```
ylecuyer@ylecuyer-U32U:~$ puma-status ~/Projects/testpuma/tmp/puma.state 
9949 (/home/ylecuyer/Projects/testpuma/tmp/puma.state) Uptime:  0m 5s | Load: 2[██░░]4
 └  9949 CPU:   0.0% Mem:   75 MB Uptime:  0m 5s | Load: 2[██░░]4
```

# Known issues

Uptime will shows 0s for older versions of puma: https://github.com/puma/puma/pull/1844
