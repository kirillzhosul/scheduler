/// @description Delay, repeat, await functions.
// @file Scheduler system.

// @author Kirill Zhosul (@kirillzhosul).
// @copyright (c) 2022 Kirill Zhosul.
// @license MIT License. (@see "SCHEDULER_LICENSE")
// @see {@link https://github.com/kirillzhosul/gamemaker-scheduler}
// @version 1.0


// "Scheduler",

// Allows you to:
// - Delay / repeat:
// -- Delay function calls for given `N` amount of frames [scheduler(f).after(n)],
// -- Repeat function calls for given `N` amount of frames [scheduler(f).every(n)],
// -- Or, all at once (repeat function every `N` frames, after `N` frames) [scheduler(f).after(n).every(n)],
// - Await HTTP:
// -- Call function when HTTP request is completed (function will give you result). [scheduler(f).http(http_get(...))]

// Examples:
// - scheduler(instance_destroy).after(room_speed * 3).
// - scheduler(function(){...}).every(room_speed * 1).
// - scheduler(function(){...}).after(room_speed * 3).every(room_speed * 1).
// - scheduler(function(r){...}).http(http_get("https://google.com/"))

#region Public (Interface for you).

// If true, will try to init schedule before schedule.
// which will create all required environment.
// if disabled, may cause tasks not ticks, and other stuff.
#macro SCHEDULER_SAFE_SCHEDULE_INIT true

function schedule(callback, params=undefined){
	// @description Schedules given callback as scheduled task and returns it as schedule task structure (allowing you to chain*).
	// @param {function} callback Function that will be called when schedule triggered.
	if (SCHEDULER_SAFE_SCHEDULE_INIT) __scheduler_init();
	
	var scheduled_task = new __SchedulerTask(callback, params); // Create new task.
	ds_list_add(global.__scheduler_tasks_list, scheduled_task); // Add task to scheduler list.
	
	return scheduled_task; // Return task to make chains.
}

#region Scheduler (schedule) chain aliases (after, every, http).

// Alias for schedule(callback, params).after(delay);
function after(delay, callback, params=undefined){
	// @description Calls callback, after delay amount of frames.
	return schedule(callback, params).after(delay);
}

// Alias for schedule(callback, params).every(delay);
function every(delay, callback, params=undefined){
	// @description Calls callback, every delay amount of frames.
	return schedule(callback, params).every(delay);
}

// Alias for schedule(callback, params).http(request_id);
function http(request_id, callback, params=undefined){
	// @description Calls callback, after HTTP response is come.
	return schedule(callback, params).http(request_id);
}

#endregion

#endregion

#region Private (Back-end structure).

#region Callbacks.

function __scheduler_task_call(task, extra_params=undefined){
	// @description Calls given task by calling it callback.
	// @param {struct[__SchedulerTask]} task Task to call.
	// @returns {any} Callback result.
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
function __SchedulerTask(callback, params) constructor{
	// @param {function} callback Function that will be called when task executed.
	// @param {any} params Will be passed with callback.
	
	// Holds all private releated information.
	// Should not be modified except scheduler core.
	self.__container = new __SchedulerTaskContainer(callback, params);
	
	// Chain operations.
		// (task)*.after(delay).*;
	self.after = __scheduler_task_chain_operation_after;
		// (task)*.every(delay).*;
	self.every = __scheduler_task_chain_operation_every; 
		// (task)*.http(request).*;
	self.http = __scheduler_task_chain_operation_http; 
};

// Scheduler task private container structure.
// encapsulates data from `__SchedulerTask`.
function __SchedulerTaskContainer(callback, params) constructor{
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
	
	// HTTP.
	// - self.http_request_id = undefined;
}

#endregion

#region Init.

// Controller settings.
// for creating if not exists.
#macro __SCHEDULER_CONTROLLER_OBJECT oSchedulerController
#macro __SCHEDULER_CONTROLLER_LAYER layer_get_id("Instances")
#macro __SCHEDULER_CONTROLLER_DEPTH 0

function __scheduler_init(){
	// @description Initialises scheduler if it is not initialised.
	if (not instance_exists(__SCHEDULER_CONTROLLER_OBJECT)){
		__scheduler_create_controller(); // Creates object.
		__scheduler_tick_setup()         // Tick alarm.
	}
	
	if (not variable_global_exists("__scheduler_tasks_list")){
		global.__scheduler_tasks_list = ds_list_create(); // List of all tasks structures. Cleaned in the `__scheduler_free()`.
	}
}

function __scheduler_create_controller(){
	// @description Creates new controller object.
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
	// @description Free scheduler memory.
	
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
	// @description Sets alarm for tick.
	__SCHEDULER_CONTROLLER_OBJECT.alarm_set(__SCHEDULER_TICK_ALARM_INDEX, __SCHEDULER_TICK_ALARM_FRAMES);
}

function __scheduler_tick_all(){
	// @description Handles `tick`, updates all scheduled tasks.
	
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
	// @description Ticks specific task.
	// @param {struct[__SchedulerTask]} task Task to tick.
	// @returns {bool} Task is completed? (Should be deleted with `__scheduler_tick_all()` if true.
	
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

#region Async (HTTP).

function __scheduler_on_async_http(){
	// @description Handles `async` HTTP loading event.
	
	var http_request_id = async_load[? "id"];
	
	var tasks_count = ds_list_size(global.__scheduler_tasks_list);
	for (var task_index = 0; task_index < tasks_count; task_index ++){
		var task = ds_list_find_value(global.__scheduler_tasks_list, task_index);
		if (not variable_struct_exists(task.__container, "http_request_id")) continue;
		
		if (task.__container.http_request_id == http_request_id){
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
	// @description Delays task for given amount of frames (by resetting previous value).
	// @param {real} delay Delay after, in frames.
	// @returns {struct[__SchedulerTask]} Chain continuation.
	
	// Updating time.
	self.__container.time_after = delay;
	self.__container.time_left_after = self.__container.time_after;
	
	return self; // Returning chain.
}

function __scheduler_task_chain_operation_http(http_request_id){
	// @description Will call task when HTTP response for given request is ready.
	// @param {real} http_request_id Request index.
	// @returns {struct[__SchedulerTask]} Chain continuation.
	
	// Remember request.
	self.__container.http_request_id = http_request_id;
	
	// Locking by HTTP. (Do not process tick).
	self.__container.skip_handle_tick = true;
	
	return self; // Returning chain.
}

function __scheduler_task_chain_operation_every(delay){
	// @description Makes task to run every given amount of frames (by resetting previous value).
	// @param {real} delay Delay every, in frames.
	// @returns {struct[__SchedulerTask]} Chain continuation.
	
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