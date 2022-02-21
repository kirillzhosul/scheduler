## Game Maker Scheduler
"Scheduler" project-package.

"Scheduler" allows you to:
- Delay / repeat:
- - Delay function calls for given `N` amount of frames [`scheduler(f).after(n)`],
- - Repeat function calls for given `N` amount of frames [`scheduler(f).every(n)`],
- - Or, all at once (repeat function every `N` frames, after `N` frames) [`scheduler(f).after(n).every(n)`],
- Await:
- - Call function when `HTTP` request is completed (function will give you result). [`scheduler(f).http_async(http_get(...))`]
- - Call function when `Steam` request is completed (function will give you result). [`scheduler(f).steam_async(steam_*(...))`]
- - Call function when `Buffer` is loaden/saved. [`scheduler(f).buffer_async(buffer_load_async(...))`]
- - Call function when `Dialog` is completed (function will give you result). [`scheduler(f).dialog_async(show_question_async(...))`]
- - Call function when `Image` is loaden. [`scheduler(f).sprite_async(sprite_add(...))` OR `sprite_add_async(...)`]

Read more at [Documentation](https://github.com/kirillzhosul/gamemaker-scheduler/blob/main/src/Scheduler/notes/SCHEDULER_DOCUMENTATION/SCHEDULER_DOCUMENTATION.txt)!  \
About GML async events [Official Documentation](https://docs2.yoyogames.com/source/_build/2_interface/1_editors/events/async_events.html)!
