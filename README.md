# Game Maker Scheduler
This repository contains "Scheduler" project-package.

"Scheduler" allows you to:
- Delay / repeat:
- - Delay function calls for given `N` amount of frames [scheduler(f).after(n)],
- - Repeat function calls for given `N` amount of frames [scheduler(f).every(n)],
- - Or, all at once (repeat function every `N` frames, after `N` frames) [scheduler(f).after(n).every(n)],
- Await HTTP:
- - Call function when HTTP request is completed (function will give you result). [scheduler(f).http(http_get(...))]

Read more at [Documentation](src\Scheduler\notes\SCHEDULER_DOCUMENTATION)!
