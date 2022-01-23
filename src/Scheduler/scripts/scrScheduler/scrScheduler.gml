/// @description Delay, repeat, await functions.
/// @file Scheduler system.

/// @author Kirill Zhosul (@kirillzhosul).
/// @copyright (c) 2022 Kirill Zhosul.
/// @license MIT License. (@see "SCHEDULER_LICENSE")
/// @see {@link https://github.com/kirillzhosul/gamemaker-scheduler}
/// @version 2.0

/// "Scheduler",

/// Allows you to:
/// - Delay / repeat:
/// - - Delay function calls for given `N` amount of frames [scheduler(f).after(n)],
/// - - Repeat function calls for given `N` amount of frames [scheduler(f).every(n)],
/// - - Or, all at once (repeat function every `N` frames, after `N` frames) [scheduler(f).after(n).every(n)],
/// - Await:
/// - - Call function when HTTP request is completed (function will give you result). [scheduler(f).http_async(http_get(...))]
/// - - Call function when Steam request is completed (function will give you result). [scheduler(f).steam_async(steam_*(...))]
/// - - Call function when Buffer is loaden/saved. [scheduler(f).buffer_async(buffer_load_async(...))]
/// - - Call function when Dialog is completed (function will give you result). [scheduler(f).dialog_async(show_question_async(...))]
/// - - Call function when Image is loaden. [scheduler(f).sprite_async(sprite_add(...)) |OR| sprite_add_async(...)]

///Examples:
///- Scheduler:
///- - scheduler(instance_destroy).after(room_speed * 3).
///- - scheduler(function(){...}).every(room_speed * 1).
///- - scheduler(function(){...}).after(room_speed * 3).every(room_speed * 1).
///- - scheduler(function(r){...}).http_async(http_get("https://google.com/"))
///- - scheduler(function(r){...}).steam_async(steam_download_scores(...))
///- - scheduler(function(r){...}).dialog_async(show_question_async("Are you fine?"))
///- - scheduler(function(r){...}).sprite_async(sprite_add(...))
///- - scheduler(function(r){...}).buffer_async(buffer_load_async(...))
///- Aliases:
///- every(room_speed * 1, function(){...})
///- after(room_speed * 3, function(){...})
///- http_async(http_get("https://google.com/"), function(r){...})
///- steam_async(steam_download_scores(...), function(r){...})
///- EXT:
///- - sprite_add_async({sprite_add params}, function(r){...})

/// For async tasks, you may want read offficial GM event documentation:
/// https://docs2.yoyogames.com/source/_build/2_interface/1_editors/events/async_events.html


#region Public (Interface for you).

// If true, will try to init schedule before schedule.
// which will create all required environment.
// if disabled, may cause tasks not ticks, and other stuff.
#macro SCHEDULER_SAFE_SCHEDULE_INIT true

function schedule(callback, params=undefined){
	/// @description Schedules given callback as scheduled task and returns it as schedule task structure (allowing you to chain*).
	/// @param {function} callback Function that will be called when schedule triggered.
	/// @param {any} params If != undefined, will be passed with callback.
	if (SCHEDULER_SAFE_SCHEDULE_INIT) __scheduler_init();
	
	var scheduled_task = new __SchedulerTask(callback, params); // Create new task.
	ds_list_add(global.__scheduler_tasks_list, scheduled_task); // Add task to scheduler list.
	
	return scheduled_task; // Return task to make chains.
}

#region Other aliases.

function sprite_add_async(fname, imgnumb, removeback, smooth, xorig, yorig, callback, params=undefined){
	/// @description Will add sprite and call callback when sprite is loaded.
	/// @param {string} fname Filename to load.
	/// @param {real} imgnumb Number of images to load.
	/// @param {bool} removeback If true, will remove background.
	/// @param {bool} smooth If true, will smooth edges if transparent.
	/// @param {real} xorig X Origin.
	/// @param {real} yorig Y Origin.
	/// @param {function} callback Function that will be called when schedule triggered.
	/// @param {any} params If != undefined, will be passed with callback.
	return sprite_async(sprite_add(fname, imgnumb, removeback, smooth, xorig, yorig), callback, params);
}

#endregion

#region Scheduler (schedule) chain aliases.

#region Delay / Time based.

// Alias for schedule(callback, params).after(delay);
function after(delay, callback, params=undefined){
	/// @description Calls callback, after delay amount of frames.
	/// @param {function} callback Function that will be called when schedule triggered.
	/// @param {any} params If != undefined, will be passed with callback.
	return schedule(callback, params).after(delay);
}

// Alias for schedule(callback, params).every(delay);
function every(delay, callback, params=undefined){
	/// @description Calls callback, every delay amount of frames.
	/// @param {function} callback Function that will be called when schedule triggered.
	/// @param {any} params If != undefined, will be passed with callback.
	return schedule(callback, params).every(delay);
}

#endregion

#region Async events.

// Alias for schedule(callback, params).http(request_id);
function http_async(request_id, callback, params=undefined){
	/// @description Calls callback, after HTTP response is come.
	/// @param {real} request_id Index of the HTTP request.
	/// @param {function} callback Function that will be called when schedule triggered.
	/// @param {any} params If != undefined, will be passed with callback.
	return schedule(callback, params).http(request_id);
}

// Alias for schedule(callback, params).steam(request_id);
function steam_async(request_id, callback, params=undefined){
	/// @description Calls callback, after Steam response is come.
	/// @param {real} request_id Index of the Steam request.
	/// @param {function} callback Function that will be called when schedule triggered.
	/// @param {any} params If != undefined, will be passed with callback.
	return schedule(callback, params).steam(request_id);
}

// Alias for schedule(callback, params).buffer(request_id);
function buffer_async(request_id, callback, params=undefined){
	/// @description Calls callback, after buffer is loaden/saved.
	/// @param {real} request_id Index of the Buffer request.
	/// @param {function} callback Function that will be called when schedule triggered.
	/// @param {any} params If != undefined, will be passed with callback.
	return schedule(callback, params).buffer(request_id);
}

// Alias for schedule(callback, params).sprite(request_id);
function sprite_async(sprite_add_id, callback, params=undefined){
	/// @description Calls callback, after given sprite is finally loaden.
	/// @param {real} sprite_add_id Index of the sprite add request.
	/// @param {function} callback Function that will be called when schedule triggered.
	/// @param {any} params If != undefined, will be passed with callback.
	return schedule(callback, params).sprite(sprite_add_id);
}

// Alias for schedule(callback, params).dialog(dialog_id);
function dialog_async(dialog_id, callback, params=undefined){
	/// @description Calls callback, after given dialog is triggered.
	/// @param {real} dialog Index of the async dialog request.
	/// @param {function} callback Function that will be called when schedule triggered.
	/// @param {any} params If != undefined, will be passed with callback.
	return schedule(callback, params).dialog(dialog_id);
}

#endregion

#endregion

#endregion

#region Private (Back-end structure).

#region Callbacks.

function __scheduler_task_call(task, extra_params=undefined){
	/// @description Calls given task by calling it callback.
	/// @param {struct[__SchedulerTask]} task Task to call.
	/// @returns {any} Callback result.
	var callback_function = task.__container.callback_function;
	var callback_params = task.__container.callback_params;

	if (not is_undefined(extra_params)){
		return callback_function(extra_params, callback_params);
	}
	
	return callback_function(callback_params);
}

#endregion

#region Structs (Tasks).

// Scheduler task structure.
// will be returned from `schedule()` and all chain operations (as `self`).
function __SchedulerTask(callback, params=undefined) constructor{
	/// @param {function} callback Function that will be called when task executed.
	/// @param {any} params Will be passed with callback.
	
	// Holds all private releated information.
	// Should not be modified except scheduler core.
	self.__container = new __SchedulerTaskContainer(callback, params);
	
	// Chain operations.
	
	// Delay / Time based.
		// (task)*.after(delay).*;
	self.after = __scheduler_task_chain_operation_after;
		// (task)*.every(delay).*;
	self.every = __scheduler_task_chain_operation_every; 
	
	// Async events.
		// (task)*.http(request_id).*;
	self.http = __scheduler_task_chain_operation_http; 
		// (task)*.steam(request_id).*;
	self.steam = __scheduler_task_chain_operation_steam; 
		// (task)*.buffer(request_id).*;
	self.buffer = __scheduler_task_chain_operation_buffer; 
		// (task)*.sprite(request_id).*;
	self.sprite = __scheduler_task_chain_operation_sprite; 
		// (task)*.dialog(dialoag_id).*;
	self.dialog = __scheduler_task_chain_operation_dialog; 

};

// Scheduler task private container structure.
// encapsulates data from `__SchedulerTask`.
function __SchedulerTaskContainer(callback, params=undefined) constructor{
	/// @param {function} callback Function that will be called when task executed.
	/// @param {any} params Will be passed with callback.
	
	// Callback information (`callback_function(callback_params)`).
	self.callback_function = callback;
	self.callback_params = params;
	
	// If true, will skip tick.
	// used for tasks, like `http` which should not tick until own `async` operation.
	self.skip_handle_tick = false;
	
	// Time information. (Default state).
	self.time_every = 0;
	self.time_after = 1;
	// Time left information. (Current state).
	self.time_left_every = self.time_every;
	self.time_left_after = self.time_after;
	
	// Non default parameters.
	
	// Async.
	// - self.http_request_id = undefined;
	// - self.steam_request_id = undefined;
	// - self.buffer_request_id = undefined;
	// - self.sprite_request_id = undefined;
	// - self.dialog_id = undefined;
}

#endregion

#region Init.

// Controller settings.
// for creating if not exists.
#macro __SCHEDULER_CONTROLLER_OBJECT oSchedulerController
#macro __SCHEDULER_CONTROLLER_LAYER layer_get_id("Instances")
#macro __SCHEDULER_CONTROLLER_DEPTH 0

function __scheduler_init(){
	/// @description Initialises scheduler if it is not initialised.
	if (not instance_exists(__SCHEDULER_CONTROLLER_OBJECT)){
		__scheduler_create_controller(); // Creates object.
		__scheduler_tick_setup()         // Tick alarm.
	}
	
	if (not variable_global_exists("__scheduler_tasks_list")){
		global.__scheduler_tasks_list = ds_list_create(); // List of all tasks structures. Cleaned in the `__scheduler_free()`.
	}
}

function __scheduler_create_controller(){
	/// @description Creates new controller object.
	if (instance_exists(__SCHEDULER_CONTROLLER_OBJECT)) return;
	
	if (layer_exists(__SCHEDULER_CONTROLLER_LAYER)){
		instance_create_layer(0, 0, __SCHEDULER_CONTROLLER_LAYER, __SCHEDULER_CONTROLLER_OBJECT);
		return;
	}
	
	instance_create_depth(0, 0, __SCHEDULER_CONTROLLER_DEPTH, __SCHEDULER_CONTROLLER_OBJECT);
	return;
}

#endregion

#region Free.

function __scheduler_free(){
	/// @description Free scheduler memory.
	
	if (instance_exists(__SCHEDULER_CONTROLLER_OBJECT)){
		instance_destroy(__SCHEDULER_CONTROLLER_OBJECT);
	}
	
	if (variable_global_exists("__scheduler_tasks_list")){
		ds_list_destroy(global.__scheduler_tasks_list)
	}
}

#endregion

#region Tick.

// Settings for tick alarm.
#macro __SCHEDULER_TICK_ALARM_FRAMES 1
#macro __SCHEDULER_TICK_ALARM_INDEX 0

function __scheduler_tick_setup(){
	/// @description Sets alarm for tick.
	__SCHEDULER_CONTROLLER_OBJECT.alarm_set(__SCHEDULER_TICK_ALARM_INDEX, __SCHEDULER_TICK_ALARM_FRAMES);
}

function __scheduler_tick_all(){
	/// @description Handles `tick`, updates all scheduled tasks.
	
	var tasks_count = ds_list_size(global.__scheduler_tasks_list);
	for (var task_index = 0; task_index < tasks_count; task_index++){
		var task = ds_list_find_value(global.__scheduler_tasks_list, task_index);
		
		if (__scheduler_tick_task(task)){
			// If task completed.
			
			// Delete task if completed.
			ds_list_delete(global.__scheduler_tasks_list, task_index);
			delete task;
			
			// Next tasks list iteration.
			tasks_count--;
			continue;
		}
	}

	// Next tick.
	__scheduler_tick_setup();
}

function __scheduler_tick_task(task){
	/// @description Ticks specific task.
	/// @param {struct[__SchedulerTask]} task Task to tick.
	/// @returns {bool} Task is completed? (Should be deleted with `__scheduler_tick_all()` if true.
	
	if (task.__container.skip_handle_tick) return false; // Not handle if task should not process tick.
		
	if (task.__container.time_left_after - 1 < 1){
		// If time to execute.
		
		if (task.__container.time_every == 0){
			// If no `every` modificator.
			
			// Call.
			var result = __scheduler_task_call(task);
		
			// Task not returned any (or explicitly returned undefined).
			// Just pass as completed task.
			if (is_undefined(result)) return true;
		
			// If returned true.
			// Retry on next tick.
			if (result) return false;
		
			// If returned not true and not undefined.
			// This is should be false.
			// Which cause resetting to initial state and marking as uncompleted.
			task.__container.time_left_after = task.__container.time_after;
			return false;
		}else{
			if (task.__container.time_left_every - 1 < 1){
				// If time to execute.
				
				// Call.
				var result = __scheduler_task_call(task);
		
				// Reset timer.
				task.__container.time_left_every = task.__container.time_every;
				
				// Task not returned any (or explicitly returned undefined).
				// Just pass as NOT completed task (to continue every).
				if (is_undefined(result)) return false;
			
				// If returned !undefined.
				// Causes resetting to initial state and marking as uncompleted.
				task.__container.time_left_after = task.__container.time_after;
				return false;
			}
			
			// Task not called, update left every delay.
			task.__container.time_left_every--;
			return false; // Task not completed.
		}
	}

	// Task not called, update left delay.
	task.__container.time_left_after--;
	return false; // Task not completed.
}

#endregion

#region Async.

#region Events.

function __scheduler_on_async_http(){
	/// @description Handles `async` HTTP loading event.
	__scheduler_on_async_call("http_request_id");
}

function __scheduler_on_async_steam(){
	/// @description Handles `async` Steam loading event.
	__scheduler_on_async_call("steam_request_id");
}

function __scheduler_on_async_saveandload(){
	/// @description Handles `async` Save and Load loading event.
	__scheduler_on_async_call("buffer_request_id");
}

function __scheduler_on_async_dialog(){
	/// @description Handles `async` dialog trigger event.
	__scheduler_on_async_call("dialog_id");
}

function __scheduler_on_async_image_loaded(){
	/// @description Handles `async` image loaded event.
	__scheduler_on_async_call("sprite_request_id");
}

#endregion

function __scheduler_on_async_call(request_name, request_id=undefined){
	/// @description Call async request for requested task when there is some async event.
	/// @param {string} request_name Name of the request index parameter.
	/// @param {real|undefined} request_id Index of the request, may be ommited.
	
	request_id ??= async_load[? "id"];
	
	var tasks_count = ds_list_size(global.__scheduler_tasks_list);
	for (var task_index = 0; task_index < tasks_count; task_index ++){
		var task = ds_list_find_value(global.__scheduler_tasks_list, task_index);
		if (not variable_struct_exists(task.__container, request_name)) continue;
		
		if (variable_struct_get(task.__container, request_name) == request_id){
			// If current task is requested this call.
			
			__scheduler_task_call(task, async_load);
			task.__container.skip_handle_tick = true; // Allow to tick.
			
			// Delete task.
			ds_list_delete(global.__scheduler_tasks_list, task_index);
			return;
		}
	}
}

#endregion

#region Chain operations.

function __scheduler_task_chain_operation_after(delay){
	/// @description Delays task for given amount of frames (by resetting previous value).
	/// @param {real} delay Delay after, in frames.
	/// @returns {struct[__SchedulerTask]} Chain continuation.
	
	if (delay <= 0){
		show_error("[:ERROR:][Scheduler] Delay for `after` can not be less than 0!", true);
		return self; // Returning chain.
	}
	
	// Updating time.
	self.__container.time_after = delay;
	self.__container.time_left_after = self.__container.time_after;
	
	return self; // Returning chain.
}

function __scheduler_task_chain_operation_http(http_request_id){
	/// @description Will call task when HTTP response for given request is ready.
	/// @param {real} http_request_id Request index.
	/// @returns {struct[__SchedulerTask]} Chain continuation.
	
	// Remember request.
	self.__container.http_request_id = http_request_id;
	
	// Locking by HTTP. (Do not process tick).
	self.__container.skip_handle_tick = true;
	
	return self; // Returning chain.
}

function __scheduler_task_chain_operation_steam(steam_request_id){
	/// @description Will call task when Steam response for given request is ready.
	/// @param {real} steam_request_id Request index.
	/// @returns {struct[__SchedulerTask]} Chain continuation.
	
	// Remember request.
	self.__container.steam_request_id = steam_request_id;
	
	// Locking by Steam. (Do not process tick).
	self.__container.skip_handle_tick = true;
	
	return self; // Returning chain.
}

function __scheduler_task_chain_operation_buffer(buffer_request_id){
	/// @description Will call task when buffer for given request is loaden or saved.
	/// @param {real} buffer_request_id Request index.
	/// @returns {struct[__SchedulerTask]} Chain continuation.
	
	// Remember request.
	self.__container.buffer_request_id = buffer_request_id;
	
	// Locking by Buffer. (Do not process tick).
	self.__container.skip_handle_tick = true;
	
	return self; // Returning chain.
}

function __scheduler_task_chain_operation_sprite(sprite_request_id){
	/// @description Will call task when sprite for given request is loaden.
	/// @param {real} sprite_request_id Request index.
	/// @returns {struct[__SchedulerTask]} Chain continuation.
	
	// Remember request.
	self.__container.sprite_request_id = sprite_request_id;
	
	// Locking by Sprite. (Do not process tick).
	self.__container.skip_handle_tick = true;
	
	return self; // Returning chain.
}

function __scheduler_task_chain_operation_dialog(dialog_id){
	/// @description Will call task when dialog is triggered* (See GM docs).
	/// @param {real} dialog_id Dialog index.
	/// @returns {struct[__SchedulerTask]} Chain continuation.
	
	// Remember dialog.
	self.__container.dialog_id = dialog_id;
	
	// Locking by Dialog. (Do not process tick).
	self.__container.skip_handle_tick = true;
	
	return self; // Returning chain.
}

function __scheduler_task_chain_operation_every(delay){
	/// @description Makes task to run every given amount of frames (by resetting previous value).
	/// @param {real} delay Delay every, in frames.
	/// @returns {struct[__SchedulerTask]} Chain continuation.
	
	if (delay <= 0){
		show_error("[:ERROR:][Scheduler] Delay for `every` can not be less than 0!", true);
		return self; // Returning chain.
	}
	
	// Updating time.
	self.__container.time_every = delay;
	self.__container.time_left_every = self.__container.time_every;
	
	return self; // Returning chain.
}

#endregion

#endregion

// Entry point.
gml_pragma("global", "__scheduler_init()");
/*if (false) */ __scheduler_init();