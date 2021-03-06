/// @description Initialisation.
// @author (с) 2022 Kirill Zhosul (@kirillzhosul)

// Counters.
counter_every_fast = 0;
counter_every_slow = 0;


// Slow counter, every 3 seconds.
// *May use non-aliased syntax like below.
every(room_speed * 3, function (){
	counter_every_slow++;
})


// Fast counter, every 1 second.
// *May use non-aliased syntax like below.
every(room_speed * 1, function (){
	counter_every_fast++;
})


// Delay message
// *May use non-aliased syntax like below.
after(room_speed * 2, function (){
	show_message_async("Message after 2 seconds!");
})


// Question.
dialog_async(show_question_async("Async question!"), function(r){
	if (ds_map_find_value(r, "status")){
		show_message("You pressed yes!");
	}else{
		show_message("You pressed no!");
	}
})

// Question (Non-example).
dialog_async(show_question_async("Try call Steam/HTTP/Buffer examples?"), function(r){
	if (ds_map_find_value(r, "status")){
		// Message after HTTP response.
		schedule(function(){
			show_message_async("Message after HTTP request response!");
		}).http(http_get("https://google.com"));

		// Message after Steam response.
		schedule(function(r){
			show_message_async("Message after Steam request response!\nResult:\n" + json_encode(r));
		}).steam(steam_download_scores("NOT_EXISTING_LEADERBOARD", 0, 1));

		// Message after Buffer saved.
		var buffer = buffer_create(1, buffer_grow, 1); 
		buffer_write(buffer, buffer_f64, 1124.32);
		var buffer_save_id = buffer_save_async(buffer, "test", 0, buffer_get_size(buffer));

		schedule(function(buffer, r){
			show_message_async("Message after buffer save!");
		}, buffer).buffer(buffer_save_id);
	}
})
