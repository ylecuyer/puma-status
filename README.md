# puma-status

Command-line tool for puma to display information about running request/process.

## Install

Install with:

```
gem install puma-status
```

## Usage

```
$ puma-status path/to/puma.state
```

For continuous monitoring:

```
$ watch --interval 0.1 --color puma-status path/to/puma.state
```

## Output examples

Clustered mode:

```
16723 (/tmp/puma.state) Version: 5.6.4/ruby2.5.3p105 | Uptime:  1m50s | Phase: 0 | Load: 2[██░░      ]10 | Req: 936
 └ 16827 CPU:  93.3% Mem:  140 MB Uptime:  1m50s | Load: 1[█░   ]5 | Req: 469
 └ 16833 CPU: 106.7% Mem:  145 MB Uptime:  1m50s | Load: 1[█░   ]5 | Req: 467
```

Single mode:

```
18847 (/tmp/puma.state) Version: 5.6.4/ruby2.5.3p105 | Uptime:  0m 3s | Load: 1[█░░  ]5 | Req: 672
 └ 18847 CPU: 120.0% Mem:  143 MB Uptime:  0m 3s | Load: 1[█░░  ]5 | Req: 672
```

## Known issues

Uptime will shows `--m --s` for older versions of puma (< 4.1.0): https://github.com/puma/puma/pull/1844
